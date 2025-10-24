// Edge Function: booking-availability
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const { clinic_id, booking_date } = await req.json();

    if (!clinic_id || !booking_date) {
      return new Response(
        JSON.stringify({ error: "clinic_id and booking_date are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `📅 [BOOKING-AVAILABILITY] Checking availability for clinic: ${clinic_id}, date: ${booking_date}`
    );

    // Get clinic opening hours
    const { data: clinic, error: clinicError } = await supabase
      .from("Clinic")
      .select("opening_hours")
      .eq("clinic_id", clinic_id)
      .single();

    if (clinicError || !clinic) {
      console.error(
        "❌ [BOOKING-AVAILABILITY] Error fetching clinic:",
        clinicError
      );
      return new Response(JSON.stringify({ error: "Clinic not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Parse the booking date and get day of week
    const requestDate = new Date(booking_date);
    const dayNames = [
      "sunday",
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
    ];
    const dayName = dayNames[requestDate.getDay()];

    console.log(`📅 [BOOKING-AVAILABILITY] Day: ${dayName}`);

    // Get opening hours for the specific day
    const dayHours = clinic.opening_hours?.[dayName];

    if (!dayHours || !dayHours.open || !dayHours.close) {
      console.log(`❌ [BOOKING-AVAILABILITY] Clinic closed on ${dayName}`);
      return new Response(
        JSON.stringify({
          available_slots: [],
          message: "Clinic is closed on this day",
          success: true,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Generate 30-minute time slots
    const slots = generateTimeSlots(dayHours.open, dayHours.close);
    console.log(
      `⏰ [BOOKING-AVAILABILITY] Generated ${slots.length} potential slots`
    );

    // Get existing bookings for this date
    const { data: existingBookings, error: bookingsError } = await supabase
      .from("Booking")
      .select("booking_time")
      .eq("clinic_id", clinic_id)
      .eq("booking_date", booking_date)
      .neq("status", "cancelled"); // Exclude cancelled bookings

    if (bookingsError) {
      console.error(
        "❌ [BOOKING-AVAILABILITY] Error fetching bookings:",
        bookingsError
      );
      return new Response(
        JSON.stringify({ error: "Failed to check existing bookings" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Filter out booked slots
    const bookedTimes = new Set(
      (existingBookings || []).map((booking) => booking.booking_time)
    );

    const availableSlots = slots.filter(
      (slot) => !bookedTimes.has(slot.time_24h)
    );

    console.log(
      `✅ [BOOKING-AVAILABILITY] ${availableSlots.length} available slots found`
    );
    console.log(
      `🚫 [BOOKING-AVAILABILITY] ${bookedTimes.size} slots already booked`
    );

    const response = {
      available_slots: availableSlots,
      clinic_hours: {
        day: dayName,
        open: dayHours.open,
        close: dayHours.close,
      },
      total_slots: slots.length,
      booked_slots: bookedTimes.size,
      success: true,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("💥 [BOOKING-AVAILABILITY] Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// Helper function to generate 30-minute time slots
function generateTimeSlots(openTime: string, closeTime: string) {
  const slots = [];

  // Parse open and close times
  const [openHour, openMin] = openTime.split(":").map(Number);
  const [closeHour, closeMin] = closeTime.split(":").map(Number);

  // Convert to minutes from midnight
  const openMinutes = openHour * 60 + openMin;
  const closeMinutes = closeHour * 60 + closeMin;

  // Generate 30-minute slots
  for (let minutes = openMinutes; minutes < closeMinutes; minutes += 30) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;

    // Format as 24-hour time for database
    const time24h = `${hours.toString().padStart(2, "0")}:${mins
      .toString()
      .padStart(2, "0")}:00`;

    // Format as 12-hour time for display
    const displayHour = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
    const ampm = hours >= 12 ? "PM" : "AM";
    const time12h = `${displayHour}:${mins
      .toString()
      .padStart(2, "0")} ${ampm}`;

    slots.push({
      time_24h: time24h,
      time_display: time12h,
      minutes_from_midnight: minutes,
    });
  }

  return slots;
}



