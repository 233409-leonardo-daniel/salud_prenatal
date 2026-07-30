# Salud Prenatal

App móvil Flutter de seguimiento prenatal. Conecta **pacientes**, **médicos** y **recepcionistas** alrededor de un expediente clínico compartido: bitácora de síntomas, citas, evaluación de riesgo, chat en tiempo real, foros de comunidad y suscripciones de pago para médicos.

El backend es un servicio REST externo (`https://saludprenatal.sytes.net/api/v1`); **este repo contiene solo el cliente Flutter**, no hay código de servidor aquí.

- Paquete: `salud_prenatal` · versión `1.0.0+5`
- Plataformas con proyecto nativo: Android, Windows, Web (Android es el objetivo real)
- Dart SDK: `^3.11.5`

---

## Qué hace

| Rol | Puede |
|---|---|
| **Paciente** (`paciente`) | Bitácora diaria de síntomas, ver su expediente y nivel de riesgo, agendar/consultar citas, chatear con su médico, participar en foros, vincularse a un médico por código/QR, pedir desvinculación |
| **Médico** (`doctor`) | Ver su lista de pacientes, crear/editar expediente y consultas, evaluar riesgo, gestionar citas, chat, generar códigos de invitación, resolver solicitudes de desvinculación. **Requiere suscripción activa** |
| **Recepcionista** (`recepcionista`) | Dashboard propio, gestión de citas |
| **Admin** (`admin`) | Reportes de foro y usuarios (pantallas de diseño en `stitch_prompt_admin_*.md`) |

Los roles llegan como strings del backend (`'doctor'` / `'doctor(a)'`, `'paciente'`, `'recepcionista'`, `'admin'`). `AppConstants` en [app_constants.dart](lib/core/constants/app_constants.dart) tiene las constantes, pero varias comprobaciones se hacen ad hoc contra el string.

---

## Arranque rápido

Requisitos: Flutter con Dart `^3.11.5`, Android SDK (o Visual Studio con toolchain C++ para el build de Windows).

```bash
flutter pub get
```

```bash
flutter run
```

La app abre en `/login`. Necesitas una cuenta del backend de producción — no hay modo offline ni seed local. Regístrate desde la pantalla de registro (paciente / médico / recepcionista).

### Otros comandos

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter test test/core/session/session_manager_test.dart
```

```bash
flutter build apk
```

```bash
flutter build windows
```

Regenerar el icono de la app tras cambiar `assets/icon/`:

```bash
dart run flutter_launcher_icons
```

### Notas de configuración

- **URL del backend**: hardcodeada en [lib/core/config/api_config.dart](lib/core/config/api_config.dart) (`baseUrl`, `timeout` 15s). No hay `.env` ni flavors — para apuntar a otro servidor se edita ese archivo.
- **Certificate pinning**: el cliente HTTP solo confía en el certificado de `saludprenatal.sytes.net` ([certificate_pinning.dart](lib/core/network/certificate_pinning.dart), huella en `chain.pem`). Si el servidor rota su certificado, **todas** las peticiones fallan hasta actualizar la huella:
  ```bash
  openssl x509 -in chain.pem -noout -fingerprint -sha256
  ```
- **Firebase / push**: `android/app/google-services.json` está en el repo. Firebase Messaging + `flutter_local_notifications` se inicializan en el arranque (`NotificationService`), antes de que exista sesión, para que los recordatorios diarios lleguen igual. Si Firebase no arranca (p. ej. emulador sin Google Play) la app sigue funcionando y solo loguea el fallo.
- **Suscripciones**: checkout y portal de cliente se abren en el navegador (Stripe Checkout vía `url_launcher`); el retorno entra por deep link con `app_links`. No hay SDK de pagos en la app.

---

## Arquitectura

Clean architecture **feature-first**, sin code-gen. Cada feature en `lib/features/<nombre>/` tiene la misma forma de cuatro carpetas:

```
data/
  datasources/    *RemoteDataSource — llamadas http vía ApiClient, decodifica JSON,
                  lanza Exception('...: Status: <code>') en no-2xx (mensajes en español)
  models/         DTOs (fromJson/toJson)
  mappers/        DTO <-> entidad de dominio (donde existen)
  repositories/   *RepositoryImpl que implementa la interfaz de dominio
domain/
  entities/       objetos de dominio planos
  repositories/   interfaces abstractas
  usecases/       una clase por caso de uso, expone execute(...)
di/
  <feature>_module.dart   cablea datasource -> repository -> usecases a mano
presentation/
  pages/          pantallas (a veces con un *_state.dart al lado)
  providers/      ChangeNotifier consumidos con package:provider
  widgets/        widgets locales de la feature
```

Flujo de una petición:

```
Page/Widget
  → Provider (ChangeNotifier, estado de carga/error)
    → UseCase.execute()
      → Repository (interfaz de dominio)
        → RepositoryImpl
          → RemoteDataSource
            → ApiClient (http + pinning + token)
              → REST API
```

### Raíz de composición

No hay framework de DI. [lib/main.dart](lib/main.dart) solo llama `runApp(MyApp())`; el cableado real está en [lib/app.dart](lib/app.dart):

1. `CoreModule` ([core_module.dart](lib/core/di/core_module.dart)) crea `SessionManager` → `ApiClient` (con cliente pinned y `tokenProvider` que jala el token de la sesión) → `QrService`.
2. Se instancian los 12 módulos de feature, cada uno con su cadena datasource → repository → usecases.
3. Wiring en dos fases para romper el ciclo `SessionManager` ↔ usecases: `sessionManager.attachProfileLoader(...)` se llama después de construir `LoginModule`.
4. Un `MultiProvider` registra cada provider de feature, recibiendo los usecases de los módulos.
5. Rutas nombradas: `/login`, `/register`, `/dashboard`, `/home`, `/patient-diaries`, `/forums`, `/subscription`. Muchas pantallas se abren con `Navigator.push` directo en lugar de rutas nombradas.

> **Importante**: los módulos se crean **una sola vez** en `initState`, no en `build`. Antes se creaban en `build` y cada rebuild de `MyApp` producía un `SessionManager` nuevo y vacío — se perdían token, userId y perfil justo después del login.

Para agregar una feature: seguir el mismo patrón (datasource → repository → usecase → módulo → registro del provider en `app.dart`).

### Sesión

[SessionManager](lib/core/session/session_manager.dart) es el dueño único del estado de sesión (token, rol, `userId`, `patientId`, `doctorId`, `medicalRecordId`, `receptionistId`, `subscriptionStatus`, perfil). Reemplazó al almacén de facto que vivía en `LoginProvider`.

Persistencia por sensibilidad:
- token → `flutter_secure_storage` (cifrado en reposo)
- ids / rol / estado de suscripción → `shared_preferences`
- `userProfile` → **solo en memoria** (es PII: email, teléfono, cédula); se recarga vía `profileLoader`

`restore()` reconstruye la sesión desde storage y valida el token con una sonda de liveness (un `getProfile`); si falla, limpia la sesión. **Ojo: `restore()` hoy no se invoca desde el código de la app** — solo desde los tests. La app siempre arranca en `/login`.

`clear()` (logout) notifica de forma síncrona antes de borrar storage, para que `isAuthenticated` pase a `false` y el `tokenProvider` de `ApiClient` devuelva `null` de inmediato. El token FCM **no** se desregistra en logout: es de dispositivo, no de sesión.

### Networking

[ApiClient](lib/core/network/api_client.dart) es un wrapper delgado sobre `http` (`get`/`getById`/`post`/`put`/`patch`/`delete`/`postMultipartFile`):
- Toma el token por callback (`tokenProvider`), no lo guarda; una lista `_noAuthEndpoints` marca las rutas públicas.
- Emite el stream broadcast estático `ApiClient.onPaymentRequired` cuando cualquier respuesta es **HTTP 402** (suscripción de médico inactiva). [SubscriptionGateListener](lib/core/widgets/subscription_gate_listener.dart) escucha globalmente y redirige a `/subscription`.
- Navega sin `BuildContext` usando `MyApp.navigatorKey` (`GlobalKey<NavigatorState>`), porque el listener vive fuera del árbol de cualquier página.
- Los datasources lanzan `Exception` plano; los providers capturan y quitan el prefijo `Exception: ` para mostrar el mensaje.

**Chat** usa un `WebSocket` aparte (`/chat/ws`, token en query string) manejado en [chat_remote_data_source.dart](lib/features/chat/data/datasources/chat_remote_data_source.dart), con reconexión automática. `sendMessage` devuelve `false` si el socket no estaba abierto y la capa superior marca el mensaje como fallido en vez de dejarlo colgado en "enviando"; el historial y los contactos sí van por REST.

### Temas

Centralizado en [lib/core/theme/theme.dart](lib/core/theme/theme.dart) (`AppTheme.lightTheme` / `darkTheme`, `themeMode: ThemeMode.system`).

**Coexisten dos sistemas de color y el código nuevo debe usar `Theme.of(context)`, no `AppColors`.** Los getters estáticos `AppColors.*` leen un global mutable `AppColors.isDarkMode` (asignado en `MaterialApp.builder` desde `MediaQuery`) y **no** registran dependencia con el árbol de widgets: una página que solo lee `AppColors` no se reconstruye al cambiar light/dark y muestra colores viejos hasta que se reconstruya por otro motivo.

En código nuevo:
- colores semánticos sin slot en `ColorScheme` (`textDark`, `textMuted`, `primaryLight`, `skeletonBase`, los seis `risk*`) → `Theme.of(context).extension<AppColorsExt>()!` ([app_colors_ext.dart](lib/core/theme/app_colors_ext.dart))
- `primary` / `background` / `cardBackground` / `error` → `Theme.of(context).colorScheme`
- tamaños de fuente → `Theme.of(context).textTheme` (`titleLarge` 20, `bodyLarge` 16, `bodyMedium` 14, `bodySmall` 12), no `fontSize:` hardcodeado

`AppColors` y `AppColorsExt` se alimentan de los **mismos** literales por variante en `theme.dart`, así que los dos sistemas no divergen. `AppColors` es legacy: dejar las páginas existentes como están y migrar un widget solo cuando ya se está reescribiendo (migrar las ~39 páginas está deliberadamente fuera de alcance).

---

## Estructura de carpetas

```
lib/
  main.dart                 runApp + filtro de un warning ruidoso de accesibilidad
  app.dart                  raíz de composición: módulos, MultiProvider, MaterialApp, rutas
  core/
    config/                 ApiConfig (baseUrl, timeout)
    constants/              AppConstants (roles, paths de endpoints)
    di/                     CoreModule
    enums/                  AppointmentStatus
    network/                ApiClient, certificate_pinning
    presentation/pages/     QrScannerPage
    services/               NotificationService (FCM + locales), QrService
    session/                SessionManager
    theme/                  theme.dart, app_colors_ext.dart, util.dart
    utils/                  relative_time
    widgets/                SubscriptionGateListener, LatestDiaryRecordCard
  features/                 appointments, chat, dashboard, forums, login,
                            patient_diaries, patients, privacy_policy, profile,
                            register, subscriptions, unlink_requests, users
test/
  core/session/             session_manager_test.dart
  features/privacy_policy/  privacy_policy_test.dart
  widget_test.dart
docs/
  PLAN_SESSION_MANAGER.md   plan del refactor de sesión
  REFACTOR_SESSION_MANAGER.md
  integration/nlp-integration.md
assets/
  icon/                     icono de app + foreground adaptativo
  logo_integrador-*.png
android/ web/ windows/       proyectos nativos
stitch_prompt_*.md           prompts de design system (Google Stitch), no documentación
chain.pem                    cadena de certificados del servidor (base del pinning)
```

`profile` es la única feature que no sigue la forma de cuatro carpetas: solo tiene `presentation/` y reutiliza usecases de `login`.

---

## Convenciones de UI/UX

- **Nunca bloquear una acción del usuario con un `await` antes de mostrar algo.** Lanzar el fetch, abrir ya la UI y renderizar el estado de carga dentro: abrir el `showModalBottomSheet` / `Navigator.push` de inmediato y usar `FutureBuilder` o el flag de carga del provider, en lugar de `await`-ear antes de abrir.
- Preferir **skeleton** (formas que imitan el layout final, p. ej. `_ContactsSkeletonList` en [chat_list_page.dart](lib/features/chat/presentation/pages/chat_list_page.dart)) sobre un spinner pelón cuando el área de carga tiene forma conocida de lista/tarjeta. Spinner solo para cargas opacas de página completa.
- Los bloques de skeleton **deben** usar `AppColors.skeletonBase`, nunca un par de hex fijos. Se deriva del tema actual (`textDark` mezclado sobre `cardBackground`) para que siempre contraste con la tarjeta/hoja de fondo; un hex fijo por variante tarde o temprano coincide exacto con `cardBackground` y el skeleton queda invisible (ya pasó una vez en el diálogo de contactos).
- Cuando una pantalla necesita datos de varios providers/usecases independientes, dispararlos concurrentes con `Future.wait(...)`, no `await` en serie.

---

## Estado del proyecto

Lo que conviene saber antes de tocar el código:

- **Sin CI**, sin overrides de lint más allá de `package:flutter_lints/flutter.yaml` ([analysis_options.yaml](analysis_options.yaml)).
- **Cobertura de tests mínima**: 3 archivos de test para 247 archivos Dart. `SessionManager` y `privacy_policy` son los únicos con pruebas reales.
- **Nombres inconsistentes en usecases**: algunos terminan en `UseCase`, otros en `Usecase`. En `appointments` conviven `get_appointments_use_case.dart` y `get_appointments_usecase.dart` como clases **distintas** — verificar el nombre real de la clase antes de asumir cuál usa un provider.
- Rama de trabajo: `dev`. Rama principal: `master`.
- `pubspec.yaml` sigue con `description: "A new Flutter project."`.
- El comentario de `restore()` menciona una guarda `inactivityTimeout` que ya no existe (los tests lo confirman explícitamente).

## Contribuir

1. Ramificar desde `dev`.
2. Seguir la forma de cuatro carpetas de la feature y registrar el provider nuevo en [lib/app.dart](lib/app.dart).
3. Colores y tipografía vía `Theme.of(context)` en código nuevo.
4. Antes de abrir PR:
   ```bash
   flutter analyze && flutter test
   ```
5. Los mensajes de commit del repo están en español, en minúsculas y descriptivos (`plan de paciente`, `desvincular paciente y cambio de plan`).
