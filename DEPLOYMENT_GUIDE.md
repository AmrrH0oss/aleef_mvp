# 🚀 Deployment Guide - User Location-Based Clinic Sorting

## Overview

This guide walks you through deploying the complete user-location-based clinic sorting system, including the Edge Function and testing the Flutter implementation.

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Supabase CLI installed**

   ```bash
   npm install -g supabase
   ```

2. **Supabase project initialized**

   ```bash
   supabase init
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. **Required database tables**:
   - `PetOwners` table with `user_id`, `city`, `district` columns
   - `clinics` table with location and rating data

## 🛠️ Step 1: Deploy the Edge Function

### 1.1 Verify Edge Function Code

The Edge Function is located at:

```
test_screen/supabase/functions/clinics-sorted-by-location/index.ts
```

### 1.2 Deploy to Supabase

From your project root directory, run:

```bash
cd test_screen
supabase functions deploy clinics-sorted-by-location
```

### 1.3 Verify Deployment

Check the Supabase Dashboard:

1. Go to **Edge Functions** section
2. Confirm `clinics-sorted-by-location` is listed and active
3. Note the function URL: `https://YOUR_PROJECT.supabase.co/functions/v1/clinics-sorted-by-location`

## 🧪 Step 2: Test the Implementation

### 2.1 Run the Flutter App

```bash
cd test_screen
flutter run -d chrome
```

### 2.2 Test User Authentication

1. **Create Test User** (if needed):

   - Navigate to "Create Account"
   - Use test credentials with location data:
     - Email: `test@aleef.com`
     - Password: `TestPassword123!`
     - City: `Cairo`
     - District: `Maadi`

2. **Login with Test User**:
   - Use the login screen
   - Enter your test credentials

### 2.3 Test Clinic Sorting

1. **Navigate to Simple Clinics Page**:

   - From login screen, tap "🏥 Simple Clinics Page"
   - Or navigate to `/clinics-simple` route

2. **Verify Automatic Sorting**:

   - Clinics should load automatically
   - Same district clinics appear first (green badge)
   - Same city clinics appear second (blue badge)
   - Other clinics appear last (gray badge)

3. **Check Console Logs**:
   - Open browser developer tools
   - Look for debug messages:
     ```
     DEBUG: Fetching clinics with user location sorting
     DEBUG: User location: {city: "Cairo", district: "Maadi"}
     DEBUG: Sorted by location: true
     ```

## 🎯 Step 3: Verify Features

### 3.1 ListTile Display Format

Each clinic should display:

- **Title**: Clinic name
- **Subtitle**: District, City
- **Location Badge**: Color-coded priority indicator
- **Trailing**: Price (green) and rating (stars)

### 3.2 Automatic Sorting Logic

Verify the sorting order:

1. **Same District** (Priority 3) - Green badge
2. **Same City** (Priority 2) - Blue badge
3. **Other Locations** (Priority 1) - Gray badge
4. **Alphabetical** within each priority group

### 3.3 Error Handling

Test error scenarios:

- **No Active Session**: Should show "Please log in again" error
- **Network Error**: Should show retry button
- **Empty Results**: Should show "No clinics found" message

## 🔧 Step 4: Database Setup (if needed)

### 4.1 Create PetOwners Table

```sql
CREATE TABLE IF NOT EXISTS "PetOwners" (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  city TEXT,
  district TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4.2 Create/Update Clinics Table

```sql
CREATE TABLE IF NOT EXISTS "clinics" (
  clinic_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT,
  district TEXT,
  examination_price DECIMAL,
  avg_rating DECIMAL,
  reviews_count INTEGER DEFAULT 0,
  location TEXT,
  phone TEXT,
  specialty TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4.3 Insert Sample Data

```sql
-- Sample user in PetOwners
INSERT INTO "PetOwners" (user_id, full_name, city, district)
VALUES ('YOUR_TEST_USER_ID', 'Test User', 'Cairo', 'Maadi');

-- Sample clinics with different locations
INSERT INTO clinics (name, city, district, examination_price, avg_rating, reviews_count)
VALUES
  ('Maadi Pet Clinic', 'Cairo', 'Maadi', 200, 4.5, 25),
  ('Zamalek Vet Center', 'Cairo', 'Zamalek', 250, 4.2, 18),
  ('Alex Animal Hospital', 'Alexandria', 'Downtown', 180, 4.8, 42),
  ('Giza Pet Care', 'Giza', 'Dokki', 220, 4.1, 15);
```

## 📱 Step 5: Mobile Testing

### 5.1 Test on Mobile Device

```bash
flutter run -d <device-id>
```

### 5.2 Verify Mobile UI

- ListTile should be responsive
- Touch interactions work properly
- Loading states display correctly
- Error messages are readable

## 🐛 Troubleshooting

### Common Issues

1. **Edge Function Not Found (404)**

   - Verify deployment: `supabase functions list`
   - Check function name matches: `clinics-sorted-by-location`
   - Ensure project is linked correctly

2. **Authentication Errors (401)**

   - Verify user is logged in
   - Check JWT token is being sent
   - Confirm session is active

3. **Database Errors (500)**

   - Check table names match exactly: `PetOwners`, `clinics`
   - Verify column names are correct
   - Check user has location data

4. **No Sorting Applied**
   - Confirm user has `city`/`district` in PetOwners table
   - Check Edge Function logs in Supabase Dashboard
   - Verify clinic data has location fields

### Debug Steps

1. **Check Edge Function Logs**:

   - Go to Supabase Dashboard → Edge Functions
   - Click on `clinics-sorted-by-location`
   - View logs and invocations

2. **Verify Database Data**:

   - Check PetOwners table has user location
   - Confirm clinics table has city/district data
   - Test queries manually in SQL Editor

3. **Flutter Debug Console**:
   - Look for DEBUG messages in browser console
   - Check network requests in DevTools
   - Verify API responses

## ✅ Success Criteria

The implementation is working correctly when:

- ✅ User can login successfully
- ✅ Clinics page loads without errors
- ✅ Clinics are sorted by user location automatically
- ✅ Location badges show correct colors
- ✅ Price and rating display properly
- ✅ Refresh functionality works
- ✅ Error states handle gracefully

## 🎉 Next Steps

After successful deployment:

1. **Performance Testing**: Test with larger datasets
2. **User Experience**: Gather feedback on sorting relevance
3. **Additional Features**: Consider distance calculations, favorites
4. **Monitoring**: Set up alerts for Edge Function errors

---

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Supabase Edge Function logs
3. Verify database table structure and data
4. Test with different user accounts and locations

The system should provide automatic, seamless clinic sorting based on user location without any manual interaction required!
