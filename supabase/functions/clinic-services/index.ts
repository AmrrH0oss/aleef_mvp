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
      `🛠️ [CLINIC-SERVICES] Fetching services for clinic: ${clinic_id}`
    );

    // Fetch services from Service table
    const { data: services, error: servicesError } = await supabase
      .from("Service")
      .select(
        `
        service_id,
        service_name,
        price
      `
      )
      .eq("clinic_id", clinic_id)
      .order("service_name", { ascending: true });

    if (servicesError) {
      console.error(
        "❌ [CLINIC-SERVICES] Error fetching services:",
        servicesError
      );
      return new Response(
        JSON.stringify({ error: "Failed to fetch services" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // If no services found, return default examination service
    let finalServices = services || [];

    if (!finalServices || finalServices.length === 0) {
      console.log(
        "⚠️ [CLINIC-SERVICES] No services found, using default examination"
      );

      // Get clinic's examination price as fallback
      const { data: clinic } = await supabase
        .from("Clinic")
        .select("examination_price")
        .eq("clinic_id", clinic_id)
        .single();

      finalServices = [
        {
          service_id: "default-examination",
          service_name: "Examination",
          price: clinic?.examination_price || 300,
        },
      ];
    }

    // Format services for response
    const formattedServices = finalServices.map((service) => ({
      service_id: service.service_id,
      name: service.service_name,
      price: parseFloat(service.price) || 0,
      price_formatted: `${service.price} EGP`,
    }));

    // Sort services: Examination first, then alphabetically
    formattedServices.sort((a, b) => {
      if (a.name.toLowerCase().includes("examination")) return -1;
      if (b.name.toLowerCase().includes("examination")) return 1;
      return a.name.localeCompare(b.name);
    });

    const response = {
      services: formattedServices,
      total_services: formattedServices.length,
      success: true,
    };

    console.log(
      `✅ [CLINIC-SERVICES] Found ${formattedServices.length} services`
    );
    if (formattedServices.length > 0) {
      console.log(
        `📋 [CLINIC-SERVICES] Sample service: ${formattedServices[0].name} - ${formattedServices[0].price_formatted}`
      );
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("💥 [CLINIC-SERVICES] Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
