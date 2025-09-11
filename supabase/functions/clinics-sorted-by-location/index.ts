// Edge Function: clinics-sorted-by-location
// This function decodes JWT, gets user location, and returns clinics sorted by proximity

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { decode } from "https://deno.land/x/djwt@v2.8/mod.ts";

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
  avg_rating?: number;
  reviews_count?: number;
  location?: string;
  phone?: string;
  specialty?: string;
  image_url?: string;
  created_at?: string;
}

interface SortedClinic extends Clinic {
  location_priority: number; // 3 = same district, 2 = same city, 1 = other
  distance_info?: string; // Human readable distance info
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get Authorization header
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

    // Decode JWT to get user ID
    const [header, payload, signature] = jwt.split(".");
    const decodedPayload = JSON.parse(atob(payload));
    const userId = decodedPayload.sub;

    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Invalid JWT: no user ID found" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const requestBody: RequestBody =
      req.method === "POST" ? await req.json() : {};

    // Get user's location from PetOwners table
    const { data: userProfile, error: userError } = await supabase
      .from("PetOwners")
      .select("user_id, full_name, phone, city, district")
      .eq("user_id", userId)
      .single();

    if (userError && userError.code !== "PGRST116") {
      // PGRST116 = no rows returned
      console.error("Error fetching user profile:", userError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch user profile" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const profile = userProfile as UserProfile | null;

    // Build clinic query with filters
    let query = supabase.from("clinics").select(`
        clinic_id,
        name,
        city,
        district,
        examination_price,
        avg_rating,
        reviews_count,
        location,
        phone,
        specialty,
        image_url,
        created_at
      `);

    // Apply search filter if provided
    if (requestBody.search) {
      query = query.or(
        `name.ilike.%${requestBody.search}%,specialty.ilike.%${requestBody.search}%`
      );
    }

    // Apply price filters if provided
    if (requestBody.priceMin !== undefined) {
      query = query.gte("examination_price", requestBody.priceMin);
    }
    if (requestBody.priceMax !== undefined) {
      query = query.lte("examination_price", requestBody.priceMax);
    }

    // Fetch clinics
    const { data: clinics, error: clinicsError } = await query;

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

    // Sort clinics by user location if user has location data
    let sortedClinics: SortedClinic[] = [];

    if (profile && (profile.city || profile.district)) {
      const userCity = profile.city?.toLowerCase() || "";
      const userDistrict = profile.district?.toLowerCase() || "";

      // Add location priority to each clinic
      sortedClinics = (clinics as Clinic[]).map((clinic) => {
        const clinicCity = clinic.city?.toLowerCase() || "";
        const clinicDistrict = clinic.district?.toLowerCase() || "";

        let locationPriority = 1; // Default: other locations
        let distanceInfo = "Other location";

        // Same district = highest priority
        if (userDistrict && clinicDistrict === userDistrict) {
          locationPriority = 3;
          distanceInfo = `Same district (${clinic.district})`;
        }
        // Same city = medium priority
        else if (userCity && clinicCity === userCity) {
          locationPriority = 2;
          distanceInfo = `Same city (${clinic.city})`;
        }

        return {
          ...clinic,
          location_priority: locationPriority,
          distance_info: distanceInfo,
        };
      });

      // Sort by priority (highest first), then by name
      sortedClinics.sort((a, b) => {
        if (a.location_priority !== b.location_priority) {
          return b.location_priority - a.location_priority;
        }
        return a.name.localeCompare(b.name);
      });
    } else {
      // No user location data - return unsorted clinics
      sortedClinics = (clinics as Clinic[]).map((clinic) => ({
        ...clinic,
        location_priority: 1,
        distance_info: "Location not specified",
      }));

      // Sort alphabetically by name
      sortedClinics.sort((a, b) => a.name.localeCompare(b.name));
    }

    // Return response
    return new Response(
      JSON.stringify({
        clinics: sortedClinics,
        user_location: profile
          ? {
              city: profile.city,
              district: profile.district,
            }
          : null,
        total_count: sortedClinics.length,
        sorted_by_location: !!(profile && (profile.city || profile.district)),
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

/* To deploy this Edge Function:

1. Make sure you have Supabase CLI installed
2. Run: supabase functions deploy clinics-sorted-by-location
3. The function will be available at: https://your-project.supabase.co/functions/v1/clinics-sorted-by-location

Environment variables needed:
- SUPABASE_URL: Your Supabase project URL
- SUPABASE_SERVICE_ROLE_KEY: Your Supabase service role key (for server-side operations)

Database requirements:
- PetOwners table with columns: user_id, full_name, phone, city, district
- clinics table with columns: clinic_id, name, city, district, examination_price, avg_rating, reviews_count, location, phone, specialty, image_url, created_at

*/

