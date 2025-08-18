# Flutter Web App Deployment to Vercel Guide

This guide will walk you through deploying your Flutter web app to Vercel with automatic deployments on git push.

## Prerequisites

- ✅ Flutter project ready
- ✅ GitHub account
- ✅ Vercel account (free tier available)
- ✅ Git repository set up

## Step 1: Prepare Your Project for Deployment

### 1.1 Update Supabase Configuration (Optional)

If you want to use environment variables instead of hardcoded values, update `lib/core/supabase_client.dart`:

```dart
class SupabaseConfig {
  // Use environment variables in production, fallback to hardcoded values for development
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xdntvwflpsrcwgtncndh.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkbnR2d2ZscHNyY3dndG5jbmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwOTIxNDYsImV4cCI6MjA3MDY2ODE0Nn0.Lp9TJAKuhdpmxmvdDbd0GqF-k0pZRAipMm_GfPa8ieQ',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
```

### 1.2 Build the Project for Web

Run the following command in your terminal:

```bash
flutter build web --release
```

**Expected Output:**

- Build files will be generated in `build/web/` directory
- This includes `index.html`, `main.dart.js`, and other assets

### 1.3 Verify Build Success

Check that the `build/web` directory contains:

- `index.html`
- `main.dart.js`
- `flutter.js`
- `assets/` folder
- Other Flutter web assets

## Step 2: Set Up Git Repository

### 2.1 Initialize Git (if not already done)

```bash
git init
git add .
git commit -m "Initial commit: Flutter web app ready for deployment"
```

### 2.2 Create GitHub Repository

1. Go to [GitHub](https://github.com)
2. Click "+" → "New repository"
3. Repository name: `aleef_mvp`
4. Set as Public or Private (your choice)
5. Do NOT initialize with README (since you already have files)
6. Click "Create repository"

### 2.3 Connect Local Repository to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/aleef_mvp.git
git branch -M main
git push -u origin main
```

**Replace `YOUR_USERNAME` with your actual GitHub username.**

## Step 3: Deploy to Vercel

### 3.1 Sign Up/Login to Vercel

1. Go to [Vercel](https://vercel.com)
2. Sign up or login (recommend using GitHub for easier integration)

### 3.2 Import Your GitHub Repository

1. Click "New Project" on Vercel dashboard
2. Click "Import Git Repository"
3. Search for and select `aleef_mvp`
4. Click "Import"

### 3.3 Configure Project Settings

**Framework Preset:**

- Select "Other" from the dropdown

**Build and Output Settings:**

- Build Command: `flutter build web --release`
- Output Directory: `build/web`
- Install Command: Leave empty (Vercel will auto-detect)

**Root Directory:**

- Leave as default (root)

### 3.4 Set Environment Variables

In the project configuration screen, add these environment variables:

```
SUPABASE_URL = https://xdntvwflpsrcwgtncndh.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkbnR2d2ZscHNyY3dndG5jbmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwOTIxNDYsImV4cCI6MjA3MDY2ODE0Nn0.Lp9TJAKuhdpmxmvdDbd0GqF-k0pZRAipMm_GfPa8ieQ
```

**To add environment variables:**

1. Scroll down to "Environment Variables" section
2. Click "Add" for each variable
3. Enter Name and Value
4. Set environment to "Production" (or all environments)

### 3.5 Deploy

1. Click "Deploy" button
2. Vercel will start building your project
3. Wait for deployment to complete (usually 2-5 minutes)

## Step 4: Verify Deployment

### 4.1 Check Deployment Status

- Monitor the build logs in Vercel dashboard
- Look for any errors in the build process

### 4.2 Test Your Live App

1. Once deployed, click on the provided URL
2. Test all functionality:
   - Login/Signup
   - Clinic list loading
   - Navigation between screens
   - Responsive design on different screen sizes

### 4.3 Custom Domain (Optional)

1. Go to Project Settings → Domains
2. Add your custom domain
3. Follow DNS configuration instructions

## Step 5: Set Up Automatic Deployments

### 5.1 Automatic Deployment Configuration

Vercel automatically sets up continuous deployment when you import from GitHub:

- ✅ **Main Branch**: Deploys to production on push to `main`
- ✅ **Feature Branches**: Creates preview deployments
- ✅ **Pull Requests**: Creates preview deployments

### 5.2 Test Automatic Deployment

1. Make a small change to your Flutter app
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Test deployment update"
   git push origin main
   ```
3. Check Vercel dashboard for automatic build trigger
4. Verify changes are live after deployment completes

## Step 6: Troubleshooting Common Issues

### 6.1 Build Failures

**Issue**: Flutter build fails on Vercel
**Solution**:

- Ensure `flutter build web --release` works locally
- Check Vercel build logs for specific errors
- Verify all dependencies are properly listed in `pubspec.yaml`

### 6.2 Routing Issues

**Issue**: Direct URL access returns 404
**Solution**: Add `vercel.json` file to project root:

```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### 6.3 Supabase Connection Issues

**Issue**: App can't connect to Supabase
**Solution**:

- Verify environment variables are set correctly
- Check browser console for CORS errors
- Ensure Supabase project allows your Vercel domain

### 6.4 Large Build Size

**Issue**: Build takes too long or fails due to size
**Solution**:

- Use `flutter build web --release --tree-shake-icons`
- Remove unused dependencies
- Optimize images and assets

## Step 7: Production Checklist

Before going live, ensure:

- [ ] All environment variables are set
- [ ] HTTPS is enabled (Vercel provides this automatically)
- [ ] Domain is configured (if using custom domain)
- [ ] Error pages are handled gracefully
- [ ] Performance is acceptable on mobile devices
- [ ] All user flows are tested in production
- [ ] Analytics/monitoring is set up (optional)

## Step 8: Monitoring and Maintenance

### 8.1 Monitor Deployments

- Check Vercel dashboard regularly
- Set up notification preferences in Vercel settings

### 8.2 Update Dependencies

- Keep Flutter and dependencies up to date
- Test updates in development before pushing

### 8.3 Performance Monitoring

- Use Vercel Analytics (available in dashboard)
- Monitor Core Web Vitals
- Check mobile performance regularly

## Quick Commands Reference

```bash
# Build for web
flutter build web --release

# Deploy changes
git add .
git commit -m "Your commit message"
git push origin main

# Check build locally
flutter run -d chrome --release
```

## Support Links

- [Vercel Documentation](https://vercel.com/docs)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Supabase Flutter Guide](https://supabase.com/docs/reference/dart/introduction)

---

## Summary

After following this guide, you'll have:

- ✅ Flutter web app deployed to Vercel
- ✅ Automatic deployments on git push
- ✅ Environment variables configured
- ✅ Custom domain ready (optional)
- ✅ Production monitoring in place

Your app will be live at: `https://aleef-mvp.vercel.app` (or your custom domain)

Happy deploying! 🚀
