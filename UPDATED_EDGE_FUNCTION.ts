// Edge Function: clinics-list (Updated with group_type logic)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface RequestBody {
  search?: string;
  priceMin?: number;
  priceMax?: number;
}

interface UserProfile {
  user_id: string;
  Full_name: string;
  phone?: string;
  city?: string;
  district?: string;
}

interface Clinic {
  clinic_id: string;
  name: string;
  city?: string;
  district?: string;
  examination_price?: number;
  profile_image?: string;
  avg_rating?: number;
  reviews_count?: number;
  _rank: number;
  group_type: string; // NEW: Classification based on location
}

// NEW: Function to classify clinics by location
function getClinicsByLocation(
  clinics: any[],
  userCity: string,
  userDistrict: string
): Clinic[] {
  return clinics.map((clinic) => {
    const clinicCity = clinic.city?.toLowerCase().trim() || "";
    const clinicDistrict = clinic.district?.toLowerCase().trim() || "";
    const normalizedUserCity = userCity.toLowerCase().trim();
    const normalizedUserDistrict = userDistrict.toLowerCase().trim();

    let groupType: string;
    let rank: number;

    // Classification logic
    if (
      clinicCity === normalizedUserCity &&
      clinicDistrict === normalizedUserDistrict
    ) {
      groupType = "same_district";
      rank = 2; // Highest priority
    } else if (
      clinicCity === normalizedUserCity &&
      clinicDistrict !== normalizedUserDistrict
    ) {
      groupType = "same_city";
      rank = 1; // Medium priority
    } else {
      groupType = "other_city";
      rank = 0; // Lowest priority
    }

    return {
      clinic_id: clinic.clinic_id,
      name: clinic.name,
      city: clinic.city,
      district: clinic.district,
      examination_price: clinic.examination_price,
      profile_image: clinic.profile_image,
      avg_rating: clinic.avg_rating,
      reviews_count: clinic.reviews_count,
      _rank: rank,
      group_type: groupType, // NEW: Add group classification
    };
  });
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Edge function started");

    // Step 1: Read and verify Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.error("Missing or invalid Authorization header");
      return new Response(
        JSON.stringify({ error: "Missing or invalid Authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const jwt = authHeader.substring(7); // Remove 'Bearer ' prefix
    console.log("JWT token received, length:", jwt.length);

    // Initialize Supabase client (server-side)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    console.log("Supabase client initialized");

    // Step 2: Verify JWT using Supabase's getUser()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(jwt);

    if (authError || !user) {
      console.error("JWT verification failed:", authError);
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log("User authenticated:", user.id);

    // Step 3: Get user's record from PetOwners using user.id
    const { data: userProfile, error: profileError } = await supabase
      .from("PetOwners")
      .select("user_id, Full_name, phone, city, district")
      .eq("user_id", user.id)
      .single();

    if (profileError && profileError.code !== "PGRST116") {
      console.error("Error fetching user profile:", profileError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch user profile" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const profile = userProfile as UserProfile | null;
    console.log("User profile:", profile);

    // Step 4: Extract city and district
    const userCity = profile?.city || "";
    const userDistrict = profile?.district || "";

    console.log(
      `User location: city="${userCity}", district="${userDistrict}"`
    );

    // Parse request body for filters
    const requestBody: RequestBody =
      req.method === "POST" ? await req.json() : {};
    console.log("Request body:", requestBody);

    // Step 5: Query Clinic table with specified fields
    let clinicsQuery = supabase
      .from("Clinic")
      .select(
        "clinic_id, name, city, district, examination_price, profile_image"
      );

    // Apply optional filters
    if (requestBody.search) {
      clinicsQuery = clinicsQuery.ilike("name", `%${requestBody.search}%`);
    }

    if (requestBody.priceMin !== undefined) {
      clinicsQuery = clinicsQuery.gte(
        "examination_price",
        requestBody.priceMin
      );
    }

    if (requestBody.priceMax !== undefined) {
      clinicsQuery = clinicsQuery.lte(
        "examination_price",
        requestBody.priceMax
      );
    }

    // Fetch clinics
    const { data: clinics, error: clinicsError } = await clinicsQuery;

    if (clinicsError) {
      console.error("Error fetching clinics:", clinicsError);
      return new Response(
        JSON.stringify({
          error: "Failed to fetch clinics",
          details: clinicsError,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log("Fetched clinics count:", clinics?.length || 0);

    // Step 6: For each clinic, get ratings and add avg_rating/reviews_count
    const clinicsWithRatings = [];

    for (const clinic of clinics || []) {
      // Get average rating and review count from Rating table
      const { data: ratings, error: ratingsError } = await supabase
        .from("Rating")
        .select("stars")
        .eq("clinic_id", clinic.clinic_id);

      let avgRating: number | undefined;
      let reviewsCount = 0;

      if (!ratingsError && ratings && ratings.length > 0) {
        const totalRating = ratings.reduce((sum, r) => sum + (r.stars || 0), 0);
        avgRating = totalRating / ratings.length;
        reviewsCount = ratings.length;
      }

      // Add rating data to clinic
      clinicsWithRatings.push({
        ...clinic,
        avg_rating: avgRating ? Math.round(avgRating * 10) / 10 : undefined,
        reviews_count: reviewsCount,
      });
    }

    // Step 7: NEW - Apply location-based classification using our function
    const classifiedClinics = getClinicsByLocation(
      clinicsWithRatings,
      userCity,
      userDistrict
    );

    // Step 8: Sort by _rank DESC, then by name ASC
    classifiedClinics.sort((a, b) => {
      if (a._rank !== b._rank) {
        return b._rank - a._rank;
      }
      return a.name.localeCompare(b.name);
    });

    console.log(
      `Returning ${classifiedClinics.length} clinics with location classification`
    );

    // Log classification results for debugging
    const groupCounts = classifiedClinics.reduce((acc, clinic) => {
      acc[clinic.group_type] = (acc[clinic.group_type] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    console.log("Classification results:", groupCounts);

    // Return the result as JSON
    return new Response(
      JSON.stringify({
        clinics: classifiedClinics,
        user_location: profile
          ? {
              city: profile.city,
              district: profile.district,
            }
          : null,
        total_count: classifiedClinics.length,
        sorted_by_location: !!(userCity || userDistrict),
        classification_counts: groupCounts, // NEW: Show classification stats
        ranking_info: {
          same_district: 2,
          same_city: 1,
          other_city: 0, // Updated from "otherwise"
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
