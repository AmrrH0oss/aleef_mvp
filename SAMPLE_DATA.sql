-- Sample Data for Clinic Profile Testing
-- Run this in Supabase SQL Editor

-- 1. Add sample services for existing clinics
INSERT INTO public."Service" (service_name, price, clinic_id) VALUES
-- Services for Happy pets clinic
('Examination', 300, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
('X-ray', 400, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
('Ultrasound', 250, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
('CBC Blood Test', 200, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),

-- Services for Lucky pets clinic  
('Examination', 350, '393d33eb-4978-4326-9cad-3b5e78c61ac2'),
('X-ray', 450, '393d33eb-4978-4326-9cad-3b5e78c61ac2'),
('Surgery Consultation', 500, '393d33eb-4978-4326-9cad-3b5e78c61ac2'),

-- Services for animalia clinic
('Examination', 250, 'd4410cca-0d4a-49f1-83c3-e201092ccb68'),
('Dental Cleaning', 220, 'd4410cca-0d4a-49f1-83c3-e201092ccb68'),
('Emergency Care', 600, 'd4410cca-0d4a-49f1-83c3-e201092ccb68');

-- 2. Add sample doctors for existing clinics
INSERT INTO public."Doctor" (doctor_id, name, specialization, available_hours, clinic_id) VALUES
-- Doctors for Happy pets clinic
(gen_random_uuid(), 'Dr Ahmed Adel Tawfik', 'General Veterinarian', '9:00 AM - 05:00 PM', 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
(gen_random_uuid(), 'Dr Kareem Hatem', 'Surgery Specialist', '10:00 AM - 07:00 PM', 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),

-- Doctors for Lucky pets clinic
(gen_random_uuid(), 'Dr Sara Mohamed', 'Exotic Animals', '8:00 AM - 04:00 PM', '393d33eb-4978-4326-9cad-3b5e78c61ac2'),
(gen_random_uuid(), 'Dr Omar Hassan', 'Emergency Care', '2:00 PM - 10:00 PM', '393d33eb-4978-4326-9cad-3b5e78c61ac2'),

-- Doctors for animalia clinic  
(gen_random_uuid(), 'Dr Fatma Ali', 'Dental Specialist', '9:00 AM - 03:00 PM', 'd4410cca-0d4a-49f1-83c3-e201092ccb68');

-- 3. Add opening hours to clinics
UPDATE public."Clinic" 
SET opening_hours = '{
  "monday": {"open": "09:00", "close": "21:00"},
  "tuesday": {"open": "09:00", "close": "21:00"}, 
  "wednesday": {"open": "09:00", "close": "21:00"},
  "thursday": {"open": "09:00", "close": "21:00"},
  "friday": {"open": "09:00", "close": "21:00"},
  "saturday": {"open": "10:00", "close": "18:00"},
  "sunday": {"open": "10:00", "close": "16:00"}
}'::jsonb
WHERE clinic_id = 'd1525fc2-b0cf-4c47-9173-64d4f00deaee';

-- 4. Add sample ratings for Happy pets (4.7 average)
INSERT INTO public."Rating" (stars, clinic_id) VALUES
(5, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
(5, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
(4, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
(5, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee'),
(4, 'd1525fc2-b0cf-4c47-9173-64d4f00deaee');

-- 5. Add sample ratings for animalia clinic (4.2 average)
INSERT INTO public."Rating" (stars, clinic_id) VALUES
(4, 'd4410cca-0d4a-49f1-83c3-e201092ccb68'),
(5, 'd4410cca-0d4a-49f1-83c3-e201092ccb68'),
(4, 'd4410cca-0d4a-49f1-83c3-e201092ccb68'),
(4, 'd4410cca-0d4a-49f1-83c3-e201092ccb68'),
(4, 'd4410cca-0d4a-49f1-83c3-e201092ccb68');
