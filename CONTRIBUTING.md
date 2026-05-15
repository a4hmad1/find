# Contributing to Find

Thanks for helping improve Find.

## Development setup

1. Install Flutter.
2. Copy `.env.example` to `.env`.
3. Add your Supabase URL and anon key.
4. Run:

```bash
flutter pub get
flutter run
```

## Before opening a pull request

Run:

```bash
dart format .
flutter analyze
flutter test
```

## Contribution guidelines

- Keep the interface RTL-first and preserve Kurdish Sorani copy unless the change is intentionally about localization.
- Keep secrets out of the repository.
- Prefer small, focused pull requests.
- Include screenshots when changing UI.
- Explain any database or RLS changes clearly in the PR description.
