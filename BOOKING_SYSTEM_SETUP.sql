-- =====================================================
-- BOOKING SYSTEM SETUP FOR SUPABASE
-- =====================================================
-- Run this script in your Supabase SQL Editor

-- 1. Create booking status enum (if not exists)
DO $$ BEGIN
    CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Ensure Booking table has correct structure
-- (This assumes the table already exists from your schema)
-- If you need to create it, uncomment the following:

/*
CREATE TABLE IF NOT EXISTS public.Booking (
  booking_id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  booking_date date NOT NULL,
  booking_time time without time zone NOT NULL,
  status booking_status NOT NULL DEFAULT 'confirmed',
  owner_id uuid,
  pet_id uuid,
  clinic_id uuid,
  CONSTRAINT Booking_pkey PRIMARY KEY (booking_id),
  CONSTRAINT Booking_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.PetOwners(pet_owner_id),
  CONSTRAINT Booking_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pet(pet_id),
  CONSTRAINT Booking_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.Clinic(clinic_id)
);
*/

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_booking_clinic_date_time 
ON public."Booking" (clinic_id, booking_date, booking_time);

CREATE INDEX IF NOT EXISTS idx_booking_owner_date 
ON public."Booking" (owner_id, booking_date DESC);

CREATE INDEX IF NOT EXISTS idx_booking_status 
ON public."Booking" (status);

-- 4. Set up Row Level Security (RLS) for Booking table
ALTER TABLE public."Booking" ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for Booking table

-- Policy: Users can view their own bookings
DROP POLICY IF EXISTS "Users can view their own bookings" ON public."Booking";
CREATE POLICY "Users can view their own bookings" ON public."Booking"
    FOR SELECT USING (
        owner_id IN (
            SELECT pet_owner_id FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can create bookings for themselves
DROP POLICY IF EXISTS "Users can create their own bookings" ON public."Booking";
CREATE POLICY "Users can create their own bookings" ON public."Booking"
    FOR INSERT WITH CHECK (
        owner_id IN (
            SELECT pet_owner_id FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can update their own bookings (for cancellation)
DROP POLICY IF EXISTS "Users can update their own bookings" ON public."Booking";
CREATE POLICY "Users can update their own bookings" ON public."Booking"
    FOR UPDATE USING (
        owner_id IN (
            SELECT pet_owner_id FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Clinics can view bookings for their clinic (for future clinic dashboard)
DROP POLICY IF EXISTS "Clinics can view their bookings" ON public."Booking";
CREATE POLICY "Clinics can view their bookings" ON public."Booking"
    FOR SELECT USING (
        -- This would need clinic user authentication system
        -- For now, we'll skip this policy
        false
    );

-- 6. Create a function to prevent double booking
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if there's already a confirmed booking for this slot
    IF EXISTS (
        SELECT 1 FROM public."Booking" 
        WHERE clinic_id = NEW.clinic_id 
        AND booking_date = NEW.booking_date 
        AND booking_time = NEW.booking_time 
        AND status != 'cancelled'
        AND booking_id != COALESCE(NEW.booking_id, '00000000-0000-0000-0000-000000000000'::uuid)
    ) THEN
        RAISE EXCEPTION 'This time slot is already booked';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger to prevent double booking
DROP TRIGGER IF EXISTS trigger_prevent_double_booking ON public."Booking";
CREATE TRIGGER trigger_prevent_double_booking
    BEFORE INSERT OR UPDATE ON public."Booking"
    FOR EACH ROW
    EXECUTE FUNCTION prevent_double_booking();

-- 8. Create a function to validate booking time is within clinic hours
CREATE OR REPLACE FUNCTION validate_booking_time()
RETURNS TRIGGER AS $$
DECLARE
    clinic_hours JSONB;
    day_name TEXT;
    day_hours JSONB;
    open_time TIME;
    close_time TIME;
BEGIN
    -- Get clinic opening hours
    SELECT opening_hours INTO clinic_hours
    FROM public."Clinic"
    WHERE clinic_id = NEW.clinic_id;
    
    IF clinic_hours IS NULL THEN
        RAISE EXCEPTION 'Clinic not found or has no opening hours';
    END IF;
    
    -- Get day name (0=Sunday, 1=Monday, etc.)
    day_name := CASE EXTRACT(DOW FROM NEW.booking_date)
        WHEN 0 THEN 'sunday'
        WHEN 1 THEN 'monday'
        WHEN 2 THEN 'tuesday'
        WHEN 3 THEN 'wednesday'
        WHEN 4 THEN 'thursday'
        WHEN 5 THEN 'friday'
        WHEN 6 THEN 'saturday'
    END;
    
    -- Get hours for this day
    day_hours := clinic_hours -> day_name;
    
    IF day_hours IS NULL OR day_hours ->> 'open' IS NULL OR day_hours ->> 'close' IS NULL THEN
        RAISE EXCEPTION 'Clinic is closed on %', 
            CASE day_name
                WHEN 'sunday' THEN 'Sunday'
                WHEN 'monday' THEN 'Monday'
                WHEN 'tuesday' THEN 'Tuesday'
                WHEN 'wednesday' THEN 'Wednesday'
                WHEN 'thursday' THEN 'Thursday'
                WHEN 'friday' THEN 'Friday'
                WHEN 'saturday' THEN 'Saturday'
            END;
    END IF;
    
    -- Parse open and close times
    open_time := (day_hours ->> 'open')::TIME;
    close_time := (day_hours ->> 'close')::TIME;
    
    -- Check if booking time is within opening hours
    IF NEW.booking_time < open_time OR NEW.booking_time >= close_time THEN
        RAISE EXCEPTION 'Booking time % is outside clinic hours (% - %)', 
            NEW.booking_time, open_time, close_time;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Create trigger to validate booking time
DROP TRIGGER IF EXISTS trigger_validate_booking_time ON public."Booking";
CREATE TRIGGER trigger_validate_booking_time
    BEFORE INSERT OR UPDATE ON public."Booking"
    FOR EACH ROW
    EXECUTE FUNCTION validate_booking_time();

-- 10. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public."Booking" TO authenticated;
GRANT SELECT ON public."Clinic" TO authenticated;
GRANT SELECT ON public."PetOwners" TO authenticated;

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================

-- Next steps:
-- 1. Deploy the Edge Functions to Supabase:
--    - supabase functions deploy booking-availability
--    - supabase functions deploy create-booking
--
-- 2. Test the booking system in your Flutter app
--
-- 3. Optional: Add sample bookings for testing:
--    INSERT INTO public."Booking" (booking_date, booking_time, status, owner_id, clinic_id)
--    VALUES ('2025-01-15', '14:00:00', 'confirmed', 
--            (SELECT pet_owner_id FROM public."PetOwners" LIMIT 1),
--            (SELECT clinic_id FROM public."Clinic" LIMIT 1));
