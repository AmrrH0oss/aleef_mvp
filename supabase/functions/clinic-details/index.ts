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
      `🏥 [CLINIC-DETAILS] Fetching details for clinic: ${clinic_id}`
    );

    // Step 1: Get clinic basic info
    const { data: clinic, error: clinicError } = await supabase
      .from("Clinic")
      .select(
        `
        clinic_id,
        name,
        city,
        district,
        phone,
        email,
        opening_hours,
        examination_price,
        profile_image
      `
      )
      .eq("clinic_id", clinic_id)
      .single();

    if (clinicError) {
      console.error("❌ [CLINIC-DETAILS] Error fetching clinic:", clinicError);
      return new Response(JSON.stringify({ error: "Clinic not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Step 2: Calculate average rating and review count
    const { data: ratings, error: ratingsError } = await supabase
      .from("Rating")
      .select("stars")
      .eq("clinic_id", clinic_id);

    let avgRating: number | null = null;
    let reviewsCount = 0;

    if (!ratingsError && ratings && ratings.length > 0) {
      const totalStars = ratings.reduce(
        (sum, rating) => sum + (rating.stars || 0),
        0
      );
      avgRating = Math.round((totalStars / ratings.length) * 10) / 10; // Round to 1 decimal
      reviewsCount = ratings.length;
    }

    // Step 3: Parse opening hours
    let parsedHours = null;
    let currentStatus = "closed";
    let todayHours = null;

    if (clinic.opening_hours) {
      try {
        parsedHours = clinic.opening_hours;

        // Get current day (0 = Sunday, 1 = Monday, etc.)
        const today = new Date().getDay();
        const dayNames = [
          "sunday",
          "monday",
          "tuesday",
          "wednesday",
          "thursday",
          "friday",
          "saturday",
        ];
        const todayName = dayNames[today];

        if (parsedHours[todayName]) {
          todayHours = parsedHours[todayName];

          // Check if currently open (simplified - you can enhance this)
          const now = new Date();
          const currentTime = now.getHours() * 100 + now.getMinutes(); // e.g., 14:30 = 1430

          if (todayHours.open && todayHours.close) {
            const openTime = parseInt(todayHours.open.replace(":", ""));
            const closeTime = parseInt(todayHours.close.replace(":", ""));

            if (currentTime >= openTime && currentTime <= closeTime) {
              currentStatus = "open";
            }
          }
        }
      } catch (e) {
        console.warn("⚠️ [CLINIC-DETAILS] Error parsing opening_hours:", e);
      }
    }

    // Step 4: Build response
    const response = {
      clinic: {
        clinic_id: clinic.clinic_id,
        name: clinic.name,
        city: clinic.city,
        district: clinic.district,
        phone: clinic.phone,
        email: clinic.email,
        examination_price: clinic.examination_price,
        profile_image: clinic.profile_image,
        location: `${clinic.district}, ${clinic.city}`, // Combined location
        avg_rating: avgRating,
        reviews_count: reviewsCount,
        opening_hours: parsedHours,
        today_hours: todayHours,
        current_status: currentStatus, // 'open' or 'closed'
      },
      success: true,
    };

    console.log(`✅ [CLINIC-DETAILS] Successfully fetched clinic details`);
    console.log(
      `📊 [CLINIC-DETAILS] Rating: ${avgRating}/5 (${reviewsCount} reviews)`
    );
    console.log(`🕐 [CLINIC-DETAILS] Status: ${currentStatus}`);

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("💥 [CLINIC-DETAILS] Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
