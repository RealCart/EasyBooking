# Auth feature

Paper screens: «11 · Вход», «12 · Подтверждение», «13 · Ваш аккаунт» (page «EasyBooking · Mobile»). The city picker for screen 13 is specified separately in `city_picker.md` after design approval.

## API contract (assumed)

There is no backend yet. This contract is an assumption; when the real API exists, only `data/` (remote source and models) should change.

All bodies are JSON. Error bodies follow the shared shape `{ "code": String?, "message": String?, "errors": { field: String | [String] }? }`, which `runGuarded` maps to `Failure` (`422`/`400` → `ValidationFailure`, `401` → `UnauthorizedFailure`, other → `ServerFailure`).

### `POST /auth/otp/send` — sends the SMS code

- Sent before sign-in: `Options(extra: {AuthInterceptor.skipAuthKey: true})`.
- Request: `{ "phone": "+77001234567" }` (E.164, Kazakhstan only).
- `200`: `{ "resendAfterSeconds": 30 }` (int ≥ 0).
- Errors: `422 {code: "invalid_phone"}`; `429 {code: "too_many_requests"}`.

### `POST /auth/otp/verify` — checks the code and signs in

- `skipAuth` as above.
- Request: `{ "phone": "+77001234567", "code": "482913" }` (6 digits).
- `200`: `{ "accessToken": String (non-empty), "refreshToken": String | null, "isNewUser": bool }`.
- Errors: `422 {code: "invalid_code"}` or `422 {code: "code_expired"}`; `429 {code: "too_many_requests"}`.

### `POST /auth/account` — creates the account of a new user

- Authenticated (bearer token from verify).
- Request: `{ "firstName", "lastName", "email", "teamName", "city", "timeZone" }`. `city` is the city id (e.g. `"almaty"`), `timeZone` its IANA id (e.g. `"Asia/Almaty"`).
- `201`: body ignored.
- Errors: `422` with `errors` keyed by the request field names.

## Session and routing

- Verify success → `AuthSession.signIn(tokens, isAccountSetupPending: isNewUser)`.
- Account creation success → `AuthSession.completeAccountSetup()`.
- Sign out → `AuthSession.signOut()`.
- `AppRouter.redirect` moves the user after every session change. Screens never navigate after sign-in or account creation:
  - signed out → only `/login`, `/login/verify`;
  - pending setup → only `/account-setup` (also after an app restart);
  - signed in → login and account setup redirect to `from` or `/today`.
- `from` (`AppRoutes.fromQuery`) must be forwarded: login → verify (query param). The redirect forwards it to account setup.

## Domain (`lib/features/auth/domain/`)

- `entity/otp_challenge_entity.dart`: `OtpChallengeEntity({required String phone /* E.164 */, required Duration resendAfter})`, Equatable.
- `entity/city_entity.dart`: `CityEntity({required String id, required String name, required String timeZone, required Duration utcOffset})`, Equatable.
- `entity/kazakhstan_cities.dart`: `abstract final class KazakhstanCities { static const List<CityEntity> all; static const CityEntity almaty; }`.
  - Cities: Алматы, Астана, Шымкент, Караганда, Актобе, Тараз, Павлодар, Усть-Каменогорск, Семей, Атырау, Костанай, Кызылорда, Уральск, Петропавловск, Актау, Туркестан, Талдыкорган, Кокшетау, Конаев.
  - Every city has `utcOffset` +5 h (Kazakhstan uses one zone since 2024).
  - IANA zones: `Asia/Almaty`, except Актобе `Asia/Aqtobe`, Атырау `Asia/Atyrau`, Уральск `Asia/Oral`, Актау `Asia/Aqtau`, Кызылорда `Asia/Qyzylorda`, Костанай `Asia/Qostanay`.
  - Ids are lowercase Latin slugs (`almaty`, `astana`, `shymkent`, `karaganda`, `aktobe`, `taraz`, `pavlodar`, `ust_kamenogorsk`, `semey`, `atyrau`, `kostanay`, `kyzylorda`, `uralsk`, `petropavlovsk`, `aktau`, `turkestan`, `taldykorgan`, `kokshetau`, `konaev`).
- `entity/auth_error_codes.dart`: `abstract final class AuthErrorCodes`:
  - API codes: `invalidPhone = 'invalid_phone'`, `invalidCode = 'invalid_code'`, `codeExpired = 'code_expired'`, `tooManyRequests = 'too_many_requests'`;
  - field codes: `required = 'required'`, `invalidEmail = 'invalid_email'`.
- `entity/account_fields.dart`: `abstract final class AccountFields { firstName = 'firstName', lastName = 'lastName', email = 'email', teamName = 'teamName', city = 'city' }`. These keys are used both in `ValidationFailure.fieldErrors` and in the API request.
- `repository/auth_repository.dart`:

  ```dart
  abstract interface class AuthRepository {
    Future<Either<Failure, OtpChallengeEntity>> sendCode(String phone);
    Future<Either<Failure, void>> verifyCode({required String phone, required String code});
    Future<Either<Failure, void>> createAccount(CreateAccountParams params);
    Future<Either<Failure, void>> signOut();
  }
  ```

- Use cases (`domain/usecases/`, one file each, positional `const` constructor with the repository):
  - **`SendCodeUsecase`** `implements Usecase<Future<Either<Failure, OtpChallengeEntity>>, String>`.
    - The input is any user-typed phone.
    - Normalize with `PhoneNumber.toE164`; `null` → `Left(ValidationFailure(code: AuthErrorCodes.invalidPhone))` without calling the repository.
  - **`VerifyCodeUsecase`** `implements Usecase<Future<Either<Failure, void>>, VerifyCodeParams>`.
    - `VerifyCodeParams({required String phone, required String code})`, Equatable.
    - A code that is not `Validators.otpLength` digits → `ValidationFailure(code: AuthErrorCodes.invalidCode)` without calling the repository.
  - **`CreateAccountUsecase`** `implements Usecase<Future<Either<Failure, void>>, CreateAccountParams>`.
    - `CreateAccountParams({required String firstName, required String lastName, required String email, required String teamName, required CityEntity? city})`, Equatable.
    - Trims the strings. Blank fields → `required`; an invalid email → `invalid_email`; a null city → `required`.
    - Any field error → `Left(ValidationFailure(fieldErrors: {AccountFields.x: code, ...}))` without calling the repository.
    - Otherwise it passes the trimmed params with a non-null city.
  - **`SignOutUsecase`** `implements Usecase<Future<Either<Failure, void>>, NoParams>`.

## Data (`lib/features/auth/data/`)

- **`sources/remote/auth_remote.dart`:** `AuthRemote` / `AuthRemoteImpl({required ApiClient apiClient})`.
  - Methods: `Future<OtpChallengeModel> sendCode(String phone)`, `Future<VerifyCodeResponseModel> verifyCode({required String phone, required String code})`, `Future<void> createAccount(CreateAccountRequestModel request)`.
  - Validate the JSON shape; on a mismatch throw `ParsingException`.
- **`models/`:**
  - `OtpChallengeModel.fromJson` + `toEntity({required String phone})`.
  - `VerifyCodeResponseModel.fromJson` (accessToken, refreshToken, isNewUser) + `toTokens()` → core `AuthTokens`.
  - `CreateAccountRequestModel.fromParams(CreateAccountParams)` + `toJson()`. City → `city: id`, `timeZone: timeZone`.
- **`repository/auth_repository_impl.dart`:** `AuthRepositoryImpl({required AuthRemote remote, required AuthSession session})`.
  - Every method uses `runGuarded`.
  - `verifyCode`: remote, then `session.signIn(response.toTokens(), isAccountSetupPending: response.isNewUser)`.
  - `createAccount`: remote, then `session.completeAccountSetup()`.
  - `signOut`: `session.signOut()`.

## Presentation contract (`lib/features/auth/presentation/`)

BLoCs use `RequestStatus` from core. Every state is `final class … extends Equatable` with `copyWith` and `reset<Field>` flags for nullable fields. Submit and resend handlers use the `droppable()` transformer from `core/utils/bloc/event_transformers.dart`.

### `bloc/login_bloc/` — `LoginBloc(sendCode: SendCodeUsecase)`

- **State:**
  - `phone` (String, default `''`, the national digits as typed);
  - `status` (`RequestStatus`);
  - `failure` (`Failure?`);
  - `challenge` (`OtpChallengeEntity?`);
  - getter `canSubmit` = `Validators.isValidPhone(phone) && !status.isLoading`.
- **Events:** `LoginPhoneChanged(String phone)`, `LoginSubmitted()`.
- **Behavior:**
  - A phone change resets `status` to `initial` and clears `failure` and `challenge`.
  - Submit: `loading`, then `success` with `challenge`, or `failure` with `failure`.
- **UI:** a `BlocListener` on the transition to `success` pushes `verifyCode` with the query `phone=<challenge.phone>`, `resendAfter=<seconds>` and `from` (if the login route had one).

### `bloc/verify_code_bloc/` — `VerifyCodeBloc(verifyCode: VerifyCodeUsecase, sendCode: SendCodeUsecase)`

- **State:**
  - `phone` (E.164), `code` (`''`);
  - `verifyStatus`, `verifyFailure`;
  - `resendStatus`, `resendFailure`;
  - `resendAvailableIn` (`Duration`, `Duration.zero` = resend allowed);
  - getter `canResend`.
- **Events:**
  - `VerifyCodeStarted({required String phone, required Duration resendAfter})`: the first event, added at creation;
  - `VerifyCodeChanged(String code)`: digits only, at most 6;
  - `VerifyCodeSubmitted()`;
  - `VerifyCodeResendRequested()`;
  - `VerifyCodeTimerTicked()`: sent by the bloc's own 1 s `Timer.periodic`, which is cancelled in `close()` and when the countdown reaches zero.
- **Behavior:**
  - Entering the 6th digit submits automatically. A code change clears `verifyFailure` and resets `verifyStatus` from `failure` to `initial`.
  - A verify failure clears `code`.
  - A resend success clears `code` and `verifyFailure` and restarts the countdown from the new `resendAfter`.
  - On verify success, do nothing more: the router redirects.

### `bloc/account_setup_bloc/` — `AccountSetupBloc(createAccount: CreateAccountUsecase, signOut: SignOutUsecase)`

- **State:**
  - `firstName`, `lastName`, `email`, `teamName` (String `''`), `city` (`CityEntity?`);
  - `status`, `failure` (non-field failures);
  - `fieldErrors` (`Map<String, String>`, `const {}`, keys `AccountFields`, values error codes or server texts).
- **Events:** `AccountFirstNameChanged`, `AccountLastNameChanged`, `AccountEmailChanged`, `AccountTeamNameChanged` (String), `AccountCitySelected(CityEntity)`, `AccountSetupSubmitted()`, `AccountSetupCancelled()`.
- **Behavior:**
  - A field change removes that field's error and clears `failure`.
  - A `ValidationFailure` with `fieldErrors` fills `fieldErrors`. Any other failure, including a `ValidationFailure` without field errors, goes to `failure`.
  - `AccountSetupCancelled` (the back button) calls `SignOutUsecase`: the router then returns to login.

### Messages (`presentation/auth_failure_message.dart`)

`extension AuthFailureMessage on Failure { String get authMessage }`:

| Failure | Message |
|---|---|
| `invalid_phone` | «Проверьте номер телефона» |
| `invalid_code` | «Неверный код» |
| `code_expired` | «Код истёк. Запросите новый» |
| `ServerFailure` with status 429 | «Слишком много попыток. Попробуйте позже» |
| anything else | `userMessage` |

Field codes: `required` → «Заполните поле»; `invalid_email` → «Проверьте адрес почты»; any other non-empty value → «Проверьте поле».

## Screens (`presentation/screens/`)

- **`LoginScreen` (11):** `AppDetailHeader` «Вход» with the back button only when the route can pop.
  - Title «Добро пожаловать», subtitle.
  - `AppPhoneCountryFields`: country «Казахстан (+7)», not tappable; phone input with `PhoneInputFormatter`.
  - Lock callout «Пришлём одноразовый код в SMS. Пароль не понадобится.»
  - The consent sentence **without** the «Условия и конфиденциальность» link (no URL yet).
  - Flow footer «Для владельцев и участников команды» + primary button «Получить код» (disabled unless `canSubmit`, loading while sending).
  - Failures in a snackbar.
- **`VerifyCodeScreen` (12):** header «Подтверждение»; title «Введите код из SMS»; «Отправили на {PhoneNumber.format(phone)}».
  - 6 code boxes in `widgets/otp_code_field.dart`. Use one hidden `TextField` (keyboard number, `autofillHints: oneTimeCode`), so SMS autofill and paste work.
  - The resend row uses `AppResendTimerRow` with `DateFormatter.countdown`.
  - «Изменить номер телефона» pops to login.
  - Info callout «Код действует 5 минут. Никому не сообщайте его, даже сотрудникам поддержки.»
  - Footer button «Подтвердить».
  - Verify failure text near the boxes; resend failure in a snackbar.
- **`AccountSetupScreen` (13):** header «Ваш аккаунт» (back → `AccountSetupCancelled`); title «Как к вам обращаться?»; subtitle «Эти данные увидят гости в документах.»
  - Fields: Имя, Фамилия, Email для документов (email keyboard), Название команды, Город и часовой пояс («{name} · UTC+5»). Tapping the city field opens the city picker (see `city_picker.md`).
  - Footer «Реквизиты для договоров добавите в настройках» + «Создать аккаунт».
  - Field errors under each field.

## Routes (`lib/app/router/app_router.dart`)

- **`login`:** `BlocProvider(create: (_) => GetIt.instance<LoginBloc>())`; passes `from` to the screen.
- **`verifyCode`:**
  - Route-level `redirect`: if `phone` is missing or `PhoneNumber.toE164` fails, go to login.
  - `resendAfter` (`AppRoutes.resendAfterQuery = 'resendAfter'`) defaults to 0 when missing or invalid.
  - `BlocProvider(create: (_) => GetIt.instance<VerifyCodeBloc>()..add(VerifyCodeStarted(...)))`.
- **`accountSetup`:** `BlocProvider(create: (_) => GetIt.instance<AccountSetupBloc>())`.
