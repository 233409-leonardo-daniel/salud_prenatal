# Refactor: SessionManager — Contexto y estado

**Rama:** `refactor/session-manager`
**Fecha:** 2026-07-11
**Origen:** `LoginProvider` era el almacén de sesión de facto (god node del grafo: 125 edges, betweenness 0.148). El objetivo fue sacar todo el estado de sesión a un servicio de `core` con dueño único y persistencia segura, dejando `LoginProvider` solo con el flujo de login.

> Este refactor se ejecutó con una orquestación multi-agente (workflow de 6 fases). Las fases de **Calidad** y **Validación** NO llegaron a correr por límite de tokens de sesión. Ver la sección "Lo que falta".

---

## Qué se hizo (fases completadas)

- **Fase 0 — Mapeo:** se mapearon los 27 consumidores de `LoginProvider` (qué miembros lee cada uno; sesión vs flujo de login).
- **Fase 1 — Arquitectura:** 3 diseños con lentes distintas (seguridad / costo de migración / idioma Flutter) sintetizados en un ADR vinculante.
- **Fase 2 — Núcleo:** implementación del `SessionManager` y cableado.
- **Fase 3 — Migración:** swap de tipo `LoginProvider → SessionManager` en las 28 páginas.

## Archivos

**Creados**
- `lib/core/session/session_manager.dart` — dueño único de sesión (263 líneas, `ChangeNotifier`).
- `lib/features/profile/presentation/providers/profile_provider.dart` — `updateProfile()` migrado aquí.
- `test/core/session/session_manager_test.dart` — tests unitarios (sin ejecutar todavía).

**Modificados (41 archivos)** — núcleo: `app.dart`, `core/di/core_module.dart`, `core/network/api_client.dart`, `core/widgets/session_timeout_listener.dart`, `login_provider.dart` (adelgazado ~202 líneas menos), `user_profile.dart`, `chat_remote_data_source.dart`, `chat/di/chat_module.dart`, `patient_detail_provider.dart`, `pubspec.yaml`/`pubspec.lock`, plugins de Windows; + las 28 páginas consumidoras.

---

## Decisiones de arquitectura (ADR)

| # | Decisión | Resumen |
|---|---|---|
| 1 | **Restore de sesión al arranque: SÍ** | `app.dart` reemplaza `initialRoute:'/login'` por un widget `SessionBootstrap` que hace `await restore()`. Dos guardas: sonda de liveness (`getProfile`; si 401/red → `clear` → `/login`) y chequeo de inactividad (reutiliza el timestamp de `SessionTimeoutListener`; si >20 min → `clear` → `/login`). |
| 2 | **Token: modelo PULL por callback** | `ApiClient({TokenProvider? tokenProvider})` con `typedef TokenProvider = String? Function()`. `CoreModule` cablea `ApiClient(tokenProvider: () => sessionManager.token)`. Se **eliminó** el campo static `_authToken` y `setAuthToken`/`clearAuthToken`/`authToken`. `onPaymentRequired` (402) sigue static. |
| 3 | **`updateProfile` se muda a `ProfileProvider`** | Nuevo provider en `features/profile` con la misma firma; en éxito llama `session.setUserProfile()`. Único consumidor recableado: `edit_profile_page`. |
| 4 | **`_userPassword` ELIMINADO** | No migra. Era la peor deuda de seguridad (password en texto plano en RAM). `UserProfile.toJson` omite la clave `password` cuando es null. |
| 5 | **Flujo registro→login preservado sin `savedPatientId`** | `login()` ya **no** pre-limpia la sesión al entrar en loading, así el `patientId` puesto por el registro sobrevive. `saveFromLogin` lo conserva con `response.patientId ?? _patientId`. `register_page` sigue llamando `setPatientId` (ahora en `SessionManager`, persistido). Bonus: login fallido ya no borra estado. |
| 6 | **`getProfileUseCase` sale de `LoginProvider`** | `SessionManager.attachProfileLoader(...)` lo consume (lo usan `saveFromLogin` y `restore`); se adjunta en `app.dart` tras construir `loginModule` para romper el ciclo de creación. |
| 7 | **`clear()` sincrónico primero** | Anula memoria + `notifyListeners` sincrónico, luego `await` del borrado de secure storage/prefs. `reset()` (que `profile_page` sigue llamando) delega en `_session.clear()` sin await en el call-site. |

**Persistencia:** token → `flutter_secure_storage` (nueva dep); ids/role/subscription → `shared_preferences`; `userProfile` solo en memoria (se re-obtiene en restore).

---

## Lo que falta (crítico — nadie lo verificó)

Las fases de Calidad y Validación **no corrieron**. El código está escrito pero **no compilado, no analizado, no probado**:

- [ ] **`flutter pub get`** — confirmar que `flutter_secure_storage` resuelve.
- [ ] **`flutter analyze`** — cero errores. Alto riesgo de imports rotos o referencias colgadas tras quitar getters de `LoginProvider`.
- [ ] **`flutter test`** — suite existente + los tests nuevos de `SessionManager` (nunca ejecutados).
- [ ] **`flutter build windows` / `apk`** — smoke de compilación; verificar `flutter_secure_storage_windows` en los plugins generados.
- [ ] **Revisión de calidad adversarial** — nunca se corrió; ningún hallazgo confirmado. Verificar a mano:
  - `reset()`/`clear()` limpian TODO el estado.
  - `patientId` del flujo registro→login sobrevive.
  - `needsSubscriptionGate`/`isDoctor` idénticos al comportamiento previo.
  - `SessionTimeoutListener` (logout global vía `navigatorKey`) sigue funcionando.
  - Cero token en texto plano; cero `_userPassword` residual.
  - Ningún consumidor quedó leyendo un getter que ya no existe.

## Fuera de scope (deuda conocida, decidida a propósito)

- Manejo de **HTTP 401 en media sesión** (broadcast espejo del 402). Solo la sonda de arranque cubre el token vencido.
- Refresco de `subscriptionStatus` al recibir 402 (el gate solo navega; el estado queda stale).
- Doble fuente de verdad de `medicalRecordId` (`SessionManager` vs `DashboardProvider`) — los fallback `session.medicalRecordId ?? dashboard.medicalRecord?.medicalRecordId` se mantienen.
- Consolidar los role-checks inline de las páginas (`contains('doctor')`, `=='doctor'` sin `'doctor(a)'`, typos de receptionist). `isReceptionist`/`isPatient` quedan disponibles pero sin adoptar.
- **Endpoint dedicado de cambio de contraseña** — consecuencia de eliminar `_userPassword`; requiere confirmar el contrato del backend `PUT /users/{id}`.
- Flujo de refresh token.

## Nota aparte (no es de este refactor)

- `docs/integration/nlp-integration.md` apareció sin trackear pero **no pertenece a este refactor** (trata de extracción de síntomas NLP / recomendaciones SOMANZ). No se tocó. Revisar/commitear por separado.

---

## Cómo continuar

El workflow quedó cacheado. Para retomar solo Calidad + Validación cuando reseteen los tokens:

```
Workflow resumeFromRunId: wf_f85bbad8-04b
```

Las fases 0–3 vuelven de caché al instante; corren en vivo solo Calidad y Validación.

Alternativa manual mínima (lo más urgente):

```
flutter pub get && flutter analyze && flutter test
```
