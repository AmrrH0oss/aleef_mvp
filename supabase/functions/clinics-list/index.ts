// Edge Function: clinics-list
// Updated to sort clinics by logged-in user's location with proper JWT verification

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
  full_name: string;
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
  _rank: number; // Location-based ranking
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Step 1: Read and verify Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid Authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const jwt = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Initialize Supabase client (server-side)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

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

    console.log(`Authenticated user: ${user.id}`);

    // Step 3: Get user's record from PetOwners using user.id
    const { data: userProfile, error: profileError } = await supabase
      .from("PetOwners")
      .select("user_id, full_name, phone, city, district")
      .eq("user_id", user.id)
      .single();

    if (profileError && profileError.code !== "PGRST116") {
      // PGRST116 = no rows returned
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

    // Step 4: Extract city and district
    const userCity = profile?.city?.toLowerCase() || "";
    const userDistrict = profile?.district?.toLowerCase() || "";

    console.log(
      `User location: city="${userCity}", district="${userDistrict}"`
    );

    // Parse request body for filters
    const requestBody: RequestBody =
      req.method === "POST" ? await req.json() : {};

    // Step 5: Query Clinic table with specified fields (matching your actual DB schema)
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
        JSON.stringify({ error: "Failed to fetch clinics" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 6: For each clinic, compute _rank and get ratings
    const enrichedClinics: Clinic[] = [];

    for (const clinic of clinics || []) {
      const clinicCity = clinic.city?.toLowerCase() || "";
      const clinicDistrict = clinic.district?.toLowerCase() || "";

      // Compute _rank based on location matching
      let rank = 0; // Default: otherwise
      if (userDistrict && clinicDistrict === userDistrict) {
        rank = 2; // Same district
      } else if (userCity && clinicCity === userCity) {
        rank = 1; // Same city
      }

      // Get average rating and review count from Rating table (using actual column name 'stars')
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

      // Add enriched clinic data
      enrichedClinics.push({
        clinic_id: clinic.clinic_id,
        name: clinic.name,
        city: clinic.city,
        district: clinic.district,
        examination_price: clinic.examination_price,
        profile_image: clinic.profile_image,
        avg_rating: avgRating ? Math.round(avgRating * 10) / 10 : undefined, // Round to 1 decimal
        reviews_count: reviewsCount,
        _rank: rank,
      });
    }

    // Step 7: Sort by _rank DESC, then by name ASC
    enrichedClinics.sort((a, b) => {
      // First sort by rank (higher rank first)
      if (a._rank !== b._rank) {
        return b._rank - a._rank;
      }
      // Then sort by name alphabetically
      return a.name.localeCompare(b.name);
    });

    console.log(
      `Returning ${enrichedClinics.length} clinics sorted by location rank`
    );

    // Return the result as JSON
    return new Response(
      JSON.stringify({
        clinics: enrichedClinics,
        user_location: profile
          ? {
              city: profile.city,
              district: profile.district,
            }
          : null,
        total_count: enrichedClinics.length,
        sorted_by_location: !!(userCity || userDistrict),
        ranking_info: {
          same_district: 2,
          same_city: 1,
          otherwise: 0,
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

/* 
Deployment Instructions:

1. Deploy this Edge Function:
   supabase functions deploy clinics-list

2. Database requirements:
   - PetOwners table: user_id, full_name, phone, city, district
   - clinics table: clinic_id, name, city, district, examination_price, profile_image
   - Rating table: clinic_id, rating

3. Environment variables needed:
   - SUPABASE_URL: Your Supabase project URL
   - SUPABASE_SERVICE_ROLE_KEY: Service role key for server-side operations

4. Usage from Flutter:
   - Call with Authorization header: Bearer <jwt_token>
   - Optional body: { "search": "...", "priceMin": 100, "priceMax": 500 }
   - Returns sorted clinics with _rank field indicating location priority

5. Response format:
   {
     "clinics": [
       {
         "clinic_id": "123",
         "name": "Clinic Name",
         "city": "Cairo",
         "district": "Maadi",
         "examination_price": 200,
         "profile_image": "url",
         "avg_rating": 4.5,
         "reviews_count": 25,
         "_rank": 2
       }
     ],
     "user_location": { "city": "Cairo", "district": "Maadi" },
     "total_count": 10,
     "sorted_by_location": true
   }
*/
