-- Row Level Security (RLS) policies for the pet table
-- This allows users to manage their own pets

-- Enable RLS on the pet table (if not already enabled)
ALTER TABLE public.pet ENABLE ROW LEVEL SECURITY;

-- Policy: Users can insert pets for themselves
CREATE POLICY "Users can insert their own pets" ON public.pet
    FOR INSERT 
    WITH CHECK (
        owner_id IN (
            SELECT pet_owner_id 
            FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can view their own pets
CREATE POLICY "Users can view their own pets" ON public.pet
    FOR SELECT 
    USING (
        owner_id IN (
            SELECT pet_owner_id 
            FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can update their own pets
CREATE POLICY "Users can update their own pets" ON public.pet
    FOR UPDATE 
    USING (
        owner_id IN (
            SELECT pet_owner_id 
            FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        owner_id IN (
            SELECT pet_owner_id 
            FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can delete their own pets
CREATE POLICY "Users can delete their own pets" ON public.pet
    FOR DELETE 
    USING (
        owner_id IN (
            SELECT pet_owner_id 
            FROM public."PetOwners" 
            WHERE user_id = auth.uid()
        )
    );

-- Grant necessary permissions to authenticated users
GRANT ALL ON public.pet TO authenticated;
