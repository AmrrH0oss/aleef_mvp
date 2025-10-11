// Edge Function: create-booking
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

    // Get the authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      console.error("❌ [CREATE-BOOKING] Authentication error:", userError);
      return new Response(
        JSON.stringify({ error: "Authentication required" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { clinic_id, booking_date, booking_time, pet_id } = await req.json();

    if (!clinic_id || !booking_date || !booking_time) {
      return new Response(
        JSON.stringify({
          error: "clinic_id, booking_date, and booking_time are required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`📝 [CREATE-BOOKING] Creating booking for user: ${user.email}`);
    console.log(
      `📝 [CREATE-BOOKING] Clinic: ${clinic_id}, Date: ${booking_date}, Time: ${booking_time}`
    );

    // Get the user's pet_owner_id
    const { data: petOwner, error: petOwnerError } = await supabase
      .from("PetOwners")
      .select("pet_owner_id")
      .eq("user_id", user.id)
      .single();

    if (petOwnerError || !petOwner) {
      console.error("❌ [CREATE-BOOKING] Pet owner not found:", petOwnerError);
      return new Response(
        JSON.stringify({ error: "Pet owner profile not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate pet_id if provided
    let validatedPetId = null;
    if (pet_id) {
      const { data: pet, error: petError } = await supabase
        .from("pet")
        .select("pet_id")
        .eq("pet_id", pet_id)
        .eq("owner_id", petOwner.pet_owner_id)
        .single();

      if (petError || !pet) {
        console.error("❌ [CREATE-BOOKING] Invalid pet_id:", petError);
        return new Response(JSON.stringify({ error: "Invalid pet selected" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      validatedPetId = pet_id;
    }

    // Check if the time slot is still available
    const { data: existingBooking, error: checkError } = await supabase
      .from("Booking")
      .select("booking_id")
      .eq("clinic_id", clinic_id)
      .eq("booking_date", booking_date)
      .eq("booking_time", booking_time)
      .neq("status", "cancelled")
      .maybeSingle();

    if (checkError) {
      console.error(
        "❌ [CREATE-BOOKING] Error checking availability:",
        checkError
      );
      return new Response(
        JSON.stringify({ error: "Failed to check availability" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (existingBooking) {
      console.log("❌ [CREATE-BOOKING] Time slot already booked");
      return new Response(
        JSON.stringify({
          error: "This time slot is no longer available",
          code: "SLOT_UNAVAILABLE",
        }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create the booking
    const bookingData = {
      booking_id: crypto.randomUUID(), // Generate UUID for booking_id
      booking_date: booking_date,
      booking_time: booking_time,
      status: "confirmed", // Default status
      owner_id: petOwner.pet_owner_id,
      pet_id: validatedPetId,
      clinic_id: clinic_id,
    };

    console.log(
      "📝 [CREATE-BOOKING] Inserting booking data:",
      JSON.stringify(bookingData, null, 2)
    );

    const { data: newBooking, error: bookingError } = await supabase
      .from("Booking")
      .insert(bookingData)
      .select(
        `
        booking_id,
        booking_date,
        booking_time,
        status,
        created_at
      `
      )
      .single();

    if (bookingError) {
      console.error(
        "❌ [CREATE-BOOKING] Error creating booking:",
        bookingError
      );
      console.error(
        "❌ [CREATE-BOOKING] Error details:",
        JSON.stringify(bookingError, null, 2)
      );
      return new Response(
        JSON.stringify({
          error: "Failed to create booking",
          details: bookingError.message || bookingError,
          code: bookingError.code || "UNKNOWN",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get clinic details for confirmation
    const { data: clinic, error: clinicError } = await supabase
      .from("Clinic")
      .select("name, phone, email")
      .eq("clinic_id", clinic_id)
      .single();

    console.log(
      `✅ [CREATE-BOOKING] Booking created successfully: ${newBooking.booking_id}`
    );

    const response = {
      booking: {
        booking_id: newBooking.booking_id,
        booking_date: newBooking.booking_date,
        booking_time: newBooking.booking_time,
        status: newBooking.status,
        created_at: newBooking.created_at,
      },
      clinic: clinic || null,
      message: "Booking created successfully",
      success: true,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("💥 [CREATE-BOOKING] Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
