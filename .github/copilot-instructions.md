# Project Guidelines

## Code Style
- Keep changes scoped to the project you are editing (`cashurance`, `cashurance-admin-web`, or `cashurance-backend`).
- Flutter code follows `flutter_lints` (`cashurance/analysis_options.yaml`). Run analyzer before finishing Flutter changes.
- Admin web code follows ESLint in `cashurance-admin-web/eslint.config.js`. Run lint before finishing frontend changes.
- Backend uses CommonJS (`require/module.exports`) with Express. Keep route/controller/config separation intact.

## Architecture
- This workspace is a monorepo with three active applications:
  - `cashurance`: Flutter client app (`lib/screens`, `lib/services`, `lib/widgets`).
  - `cashurance-admin-web`: React + Vite admin UI (`src/`).
  - `cashurance-backend`: Express + SQLite API (`src/routes`, `src/controllers`, `src/config`, `src/middleware`).
- Backend API is versioned under `/api/v1/*` with a health endpoint at `/health`.
- Treat implementation in code as source of truth. `ImplementationPlan` is a planning artifact and may describe future architecture not yet implemented.

## Build and Test
- Install dependencies per project:
  - `cd cashurance && flutter pub get`
  - `cd cashurance-admin-web && npm install`
  - `cd cashurance-backend && npm install`
- Common dev commands:
  - Flutter app: `cd cashurance && flutter run`
  - Admin web: `cd cashurance-admin-web && npm run dev`
  - Backend API: `cd cashurance-backend && node server.js`
- Validation commands:
  - Flutter: `cd cashurance && flutter analyze && flutter test`
  - Admin web: `cd cashurance-admin-web && npm run lint && npm run build`
  - Backend: no real test suite is configured yet (`npm test` intentionally fails).

## Conventions
- Do not manually edit generated/build outputs (for example `cashurance/build/` and platform-generated artifacts).
- Flutter API base URL is defined in `cashurance/lib/services/api_service.dart` and can be overridden with `--dart-define=API_BASE_URL=...`.
- Backend persists data in `cashurance-backend/database.sqlite`; startup runs table creation/migration logic in `cashurance-backend/src/config/database.js`.
- Keep API contract changes synchronized across:
  - Backend routes/controllers in `cashurance-backend/src/**`
  - Flutter API client in `cashurance/lib/services/api_service.dart`

## Project Docs
- Flutter starter docs: `cashurance/README.md`
- Admin starter docs: `cashurance-admin-web/README.md`
- Product/target architecture notes: `ImplementationPlan`
