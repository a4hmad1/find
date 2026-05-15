# Supabase Setup

This app uses Supabase for GitHub OAuth, PostgreSQL, Storage, Realtime-capable messaging streams, and Row Level Security.

## 1. Create Project

Create a Supabase project and copy:

- Project URL
- anon public key

Put them in `.env`:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
```

## 2. Apply Database Migration

Use the Supabase SQL editor or the Supabase CLI.

CLI option:

```bash
supabase link --project-ref your-project-ref
supabase db push
```

Manual option:

1. Open Supabase Dashboard.
2. Go to SQL Editor.
3. Paste and run `supabase/migrations/202605130001_initial_schema.sql`.

The migration creates:

- `profiles`
- `posts`
- `post_images`
- `conversations`
- `messages`
- `saved_posts`
- `reports`
- `notifications`
- `categories`
- indexes
- helper functions
- triggers
- RLS policies
- public Storage bucket `post-images`

## 3. Storage

The migration creates the bucket:

```text
post-images
```

Rules:

- Public can view item images.
- Authenticated users can upload images.
- Users can delete images they uploaded.
- Admins can delete any image.

The app stores paths like:

```text
posts/{post_id}/{uuid}.jpg
```

## 4. GitHub OAuth

In Supabase Dashboard:

1. Open Authentication.
2. Open Providers.
3. Enable GitHub.
4. Add GitHub OAuth Client ID and Client Secret.
5. Add this redirect URL:

```text
krd.gov.find.find://login-callback
```

In GitHub Developer Settings for the OAuth app, set the callback URL to the Supabase callback URL shown by Supabase, usually:

```text
https://your-project-ref.supabase.co/auth/v1/callback
```

## 5. Android Deep Link

Already configured:

```xml
<data android:scheme="krd.gov.find.find" android:host="login-callback"/>
```

The Android application id is:

```text
krd.gov.find.find
```

## 6. iOS Deep Link

Already configured in `ios/Runner/Info.plist`:

```text
krd.gov.find.find
```

For a production iOS app, confirm the bundle identifier in Xcode and add the same redirect URL in Supabase.

## 7. Admin Role

After the first GitHub login, promote an account:

```sql
update public.profiles
set role = 'admin'
where github_username = 'your-github-username';
```

Roles:

- `user`
- `moderator`
- `admin`

## 8. RLS Summary

- Public reads approved and returned posts.
- Authenticated users create pending posts only.
- Users edit, close, return, delete only their own posts.
- Users cannot approve their own posts.
- Admins and moderators approve, reject, close, delete posts.
- Conversation and message reads are participant-only.
- Message insert is participant-only and rate-limited.
- Banned users cannot create posts or send messages.
- Reports can be created by authenticated users.
- Only admins and moderators can review all reports.
- Notifications are owner-readable; announcements are admin-created.

## 9. Local Run

```bash
flutter pub get
flutter run
```

If `.env` is empty, the app opens the Kurdish login screen with a Supabase setup warning and disables GitHub login.
