# Scanly

Scan a document, get a PDF instantly (offline), and an editable Word/Excel file via AI.
Flutter + Supabase + Claude API. Built phase by phase; see `claude-code-prompt-scanner-app.md`.

## Status
- Phase 0: project setup (done)
- Phase 1: scan + local PDF (in progress)

## Setup from zero (Windows)
1. Install Flutter (stable) and add `flutter\bin` to PATH.
2. Install Android Studio + SDK + cmdline-tools; set `JAVA_HOME` to Studio's `jbr` folder and `ANDROID_HOME` to the SDK.
3. `flutter doctor --android-licenses`, then `flutter doctor` (Android toolchain must be green).
4. `flutter pub get`, then `flutter run` with a phone (USB debugging on) or emulator.

## Accounts and keys you will need
| When | What | Where it goes |
|---|---|---|
| Phase 2 | Supabase project (region close to Uganda) | `SUPABASE_URL`, `SUPABASE_ANON_KEY` in `.env` (copy `.env.example`) |
| Phase 2 | Anthropic API key (platform.claude.com) | `supabase secrets set` using `supabase/.env` only. Never in the app or git |
| Phase 6 | Google Play Console | Subscription product IDs |

## Layout
- `lib/core` shared theme, router. `lib/features/*` feature-first modules.
- `lib/l10n` ARB strings (English now; add `app_lg.arb`, `app_sw.arb` later). Regenerate with `flutter gen-l10n`.
- `supabase/migrations`, `supabase/functions`, `prompts/`, `test_assets/`.

## Checks
`flutter analyze` and `flutter test` must pass before a phase is closed.
