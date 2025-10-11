# Edge Function Setup Guide

## Step 1: Create Edge Function in Supabase Dashboard

1. **Go to your Supabase Dashboard**
2. **Navigate to Edge Functions** (in the left sidebar)
3. **Click "Create a new function"**
4. **Name it**: `clinics-list`
5. **Replace the default code** with the code below:

```typescript
// Edge Function: clinics-list
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
    const userCity = profile?.city?.toLowerCase() || "";
    const userDistrict = profile?.district?.toLowerCase() || "";

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

      // Add enriched clinic data
      enrichedClinics.push({
        clinic_id: clinic.clinic_id,
        name: clinic.name,
        city: clinic.city,
        district: clinic.district,
        examination_price: clinic.examination_price,
        profile_image: clinic.profile_image,
        avg_rating: avgRating ? Math.round(avgRating * 10) / 10 : undefined,
        reviews_count: reviewsCount,
        _rank: rank,
      });
    }

    // Step 7: Sort by _rank DESC, then by name ASC
    enrichedClinics.sort((a, b) => {
      if (a._rank !== b._rank) {
        return b._rank - a._rank;
      }
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
```

6. **Click "Deploy function"**

## Step 2: Fix Row Level Security (RLS)

The main issue might be RLS blocking access to your Clinic table.

### Option A: Disable RLS (Quick Fix)

1. **Go to Database > Tables**
2. **Find your "Clinic" table**
3. **Click on the table name**
4. **Go to "Settings" tab**
5. **Turn OFF "Enable Row Level Security"**

### Option B: Add RLS Policy (Recommended)

1. **Go to Database > Tables**
2. **Find your "Clinic" table**
3. **Click on "RLS" tab**
4. **Click "Add Policy"**
5. **Policy name**: `Allow authenticated users to read clinics`
6. **Policy type**: `SELECT`
7. **Target roles**: `authenticated`
8. **Policy definition**: `true` (allows all authenticated users)
9. **Click "Save"**

## Step 3: Test the Edge Function

After creating the function, test it in the Supabase dashboard:

1. **Go to Edge Functions**
2. **Click on "clinics-list"**
3. **Click "Invoke function"**
4. **Add headers**:
   ```json
   {
     "Authorization": "Bearer YOUR_JWT_TOKEN",
     "Content-Type": "application/json"
   }
   ```
5. **Add body** (optional):
   ```json
   {}
   ```
6. **Click "Send request"**

You should see a response with your clinics data.

## Step 4: Update Flutter Code

Once the Edge Function is working, update your Flutter code to use it:

1. **Uncomment the Edge Function import** in `clinics_service.dart`
2. **Replace the direct database call** with the Edge Function call
3. **Test in your Flutter app**

## Troubleshooting

If you still get errors:

1. **Check the Edge Function logs** in Supabase dashboard
2. **Verify your JWT token** is valid
3. **Check RLS policies** on Clinic and Rating tables
4. **Ensure your user exists** in PetOwners table
5. **Check database permissions**



