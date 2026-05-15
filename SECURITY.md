# Security Policy

## Reporting a vulnerability

Please do not open public issues for security vulnerabilities.

If you discover a security problem, contact the maintainer privately through the contact links on the GitHub profile and include:

- a clear description of the issue
- steps to reproduce it
- affected files or flows
- the potential impact

## Sensitive areas

Pay special attention to:

- authentication and OAuth redirects
- Row Level Security policies
- storage bucket permissions
- direct messaging access controls
- moderator and administrator actions

## Secret handling

- Never commit `.env`.
- Never place Supabase service-role keys in the Flutter app.
- Rotate exposed credentials immediately if they are leaked.
