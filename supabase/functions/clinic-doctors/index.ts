import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Create Supabase client
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Get request body
    const { clinic_id } = await req.json();

    if (!clinic_id) {
      return new Response(JSON.stringify({ error: "clinic_id is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(
      `👨‍⚕️ [CLINIC-DOCTORS] Fetching doctors for clinic: ${clinic_id}`
    );

    // Fetch doctors from Doctor table
    const { data: doctors, error: doctorsError } = await supabase
      .from("Doctor")
      .select(
        `
        doctor_id,
        name,
        specialization,
        available_hours,
        profile_image
      `
      )
      .eq("clinic_id", clinic_id)
      .order("name", { ascending: true });

    if (doctorsError) {
      console.error(
        "❌ [CLINIC-DOCTORS] Error fetching doctors:",
        doctorsError
      );
      return new Response(
        JSON.stringify({ error: "Failed to fetch doctors" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // If no doctors found, return empty array (clinic might not have added doctors yet)
    const finalDoctors = doctors || [];

    // Format doctors for response
    const formattedDoctors = finalDoctors.map((doctor) => {
      // Parse available hours and determine current status
      let availability_status = "unavailable";
      let formatted_hours = doctor.available_hours || "Hours not specified";

      // Simple availability check (you can enhance this)
      const now = new Date();
      const currentHour = now.getHours();

      // Basic logic: if available_hours contains current time range, mark as available
      if (doctor.available_hours) {
        try {
          // Example: "9:00 AM - 05:00 PM" or "10:00 AM - 07:00 PM"
          const hoursMatch = doctor.available_hours.match(
            /(\d{1,2}):(\d{2})\s*(AM|PM)\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)/i
          );
          if (hoursMatch) {
            let startHour = parseInt(hoursMatch[1]);
            let endHour = parseInt(hoursMatch[4]);

            // Convert to 24-hour format
            if (hoursMatch[3].toUpperCase() === "PM" && startHour !== 12)
              startHour += 12;
            if (hoursMatch[6].toUpperCase() === "PM" && endHour !== 12)
              endHour += 12;
            if (hoursMatch[3].toUpperCase() === "AM" && startHour === 12)
              startHour = 0;
            if (hoursMatch[6].toUpperCase() === "AM" && endHour === 12)
              endHour = 0;

            if (currentHour >= startHour && currentHour < endHour) {
              availability_status = "available";
            }
          }
        } catch (e) {
          console.warn("⚠️ [CLINIC-DOCTORS] Error parsing doctor hours:", e);
        }
      }

      return {
        doctor_id: doctor.doctor_id,
        name: doctor.name,
        specialization: doctor.specialization || "General Veterinarian",
        available_hours: formatted_hours,
        availability_status: availability_status, // 'available' or 'unavailable'
        profile_image: doctor.profile_image,
        experience: `${Math.floor(Math.random() * 10) + 1} years of experience`, // You can add this to DB later
      };
    });

    const response = {
      doctors: formattedDoctors,
      total_doctors: formattedDoctors.length,
      available_now: formattedDoctors.filter(
        (d) => d.availability_status === "available"
      ).length,
      success: true,
    };

    console.log(`✅ [CLINIC-DOCTORS] Found ${formattedDoctors.length} doctors`);
    console.log(`👥 [CLINIC-DOCTORS] Available now: ${response.available_now}`);
    if (formattedDoctors.length > 0) {
      console.log(
        `👨‍⚕️ [CLINIC-DOCTORS] Sample doctor: ${formattedDoctors[0].name} - ${formattedDoctors[0].specialization}`
      );
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("💥 [CLINIC-DOCTORS] Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
