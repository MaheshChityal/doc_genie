# DocGenie

DocGenie is a Flutter banking app with a **Maker–Checker** workflow for payment
instructions (RTGS / NEFT / Fund Transfer). A maker scans/uploads a document, an
OCR step pre-fills a transaction form, the maker submits it, and a checker reviews
and approves/rejects it.

- **State:** Riverpod `StateNotifier` over a shared `GenericState`
  (`Initial / Loading / Loaded<T> / Error`) in `lib/common/generic_state.dart`.
- **Networking:** a `Dio` singleton `AppClient` (`lib/common/app_client.dart`) with
  a 401 auto-refresh interceptor and a 30-minute session (`lib/services/session_manager.dart`).
- **Structure:** feature-first — `lib/feature/<name>/{screen,controller,repository,model}`.

## Getting Started

```bash
flutter pub get
flutter run -d chrome     # web (PDF preview uses the browser's native viewer)
```

Mock logins (no password check while mocked): `M001` = Maker, `C001` = Checker.

---

## Going live — removing mock data & switching to the real API

**Everything "dummy" is gated behind flags.** The real Dio request/response code
already exists behind each mock block, so going live is mostly flipping switches.

### Step 1 — The switch (all that's required)

Set the real base URL, then flip these flags to `false`:

| File | Change |
|---|---|
| `lib/config/app_config.dart` | `baseUrl` → real API URL (currently `https://api.example.com/`) |
| `lib/feature/auth/repository/auth_repository.dart` | `useMockAuth = false` |
| `lib/common/app_client.dart` | `mockAuth = false` (mock token refresh) |
| `lib/feature/home/repository/home_repository.dart` | `useMock = false` |
| `lib/feature/maker/repository/auto_repository.dart` | `useMock = false` |
| `lib/feature/maker/repository/manual_repository.dart` | `useMock = false` |
| `lib/feature/checker/repository/checker_repository.dart` | `useMock = false` |

After this, every screen hits real endpoints. Nothing else is strictly required.

### Step 2 — Delete the dummy code (optional cleanup, once verified)

In each repository, delete the `if (useMock) { … return; }` block (and its flag),
then remove the now-orphaned helpers:

- **auto_repository.dart** — delete `_mockDocs()`; remove the `sample_pdf.dart` import.
  Keep `_toIsoDate()` (used by the real submit).
- **manual_repository.dart** — delete `_mockFields()`.
- **checker_repository.dart** — delete `_mockDocs()`, `_generatedMockDocs()`,
  `_baseMockDocs`; remove the `sample_pdf.dart` import.
- **home_repository.dart** — delete the mock `HomeModel(...)` block.
- **auth_repository.dart** — delete the mock login-response block.
- **app_client.dart** `_doRefresh()` — delete the `if (mockAuth) { … }` block and the
  `mockAuth` const.
- Delete the dummy PDF file: `lib/constants/sample_pdf.dart`.

Then run `flutter analyze` — it flags any leftover unused imports/variables to clean up.

### Step 3 — Confirm the API contract

The real code builds/parses specific JSON. Verify these against the backend:

- **Auth** — login/refresh field names (`accessToken`/`token`, `refreshToken`, `role`,
  `user`).
- **`maker/getAuto` & `maker/getManual`** — flat objects that must include
  **`fileBytes`** (base64 of the PDF, for the left-pane preview), plus `fileName`,
  `makerBy`/`submittedBy`, `status`.
- **Auto submit** (`maker/auto-scan`) — flat payload with `source: 0`, `remark`, and
  `remitterName` / `mobileNumber` / `remitterAddress` / `beneficiaryAddress` /
  `purposeOfTransfer`.
- **Manual submit** (`maker/documents`) — nested `fields` with `source: 1`.
  ⚠️ currently sent **without** a Bearer token (`RequestType.post`) — switch to
  `postWithToken` if the endpoint requires auth.
- **Checker** (`checker/documents`, `checker/documents/{id}/decide`) — the checker
  `fields` use different keys (`beneName`, `beneIfscCode`…) than the maker form; the
  remark from the confirm dialog is **not** currently sent.
- **Endpoint paths** — `maker/getAuto` / `maker/getManual` in
  `lib/constants/api_constants.dart` were assumed; confirm the real paths.
- **PDF byte field** — models decode `fileBytes` / `file` / `fileBase64` / `document`;
  make sure one matches the API response key.

### Notes
- `flutter_secure_storage` holds the tokens, role, user, and session expiry.
- The session auto-logs-out after 30 minutes (warning popup 2 minutes before), and
  re-checks elapsed time when a web tab is restored (`lib/services/session_manager.dart`).
- The PDF preview renders via the browser's native viewer on **web**; other platforms
  show a fallback (`lib/widgets/pdf_preview*.dart`).
