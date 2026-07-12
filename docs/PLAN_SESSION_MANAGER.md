# Plan: Workflow multi-agente — extracción de `SessionManager`

**Fecha:** 2026-07-10
**Rama base:** `dev`
**Objetivo:** `LoginProvider` (god node, 125 edges, betweenness 0.148) deja de ser el almacén de sesión de facto. La sesión pasa a un servicio de `core` (`SessionManager`) con persistencia segura. `LoginProvider` queda solo con el flujo de iniciar sesión.

## Contexto

- 72 usos de `LoginProvider` en 28 páginas + `app.dart` + `ApiClient` + `SessionTimeoutListener`/`SubscriptionGateListener`.
- Token hoy en campo **static** `ApiClient._authToken` (memoria, texto plano).
- `shared_preferences` ya es dependencia; `flutter_secure_storage` hay que agregarlo.
- La sesión hoy muere al cerrar la app — no hay restore.
- Smell adicional: `_userPassword` retenido en memoria para `updateProfile()`.

## Diseño destino

```
core/session/
  session_manager.dart   # dueño único de la sesión, registrado en CoreModule
```

- `SessionManager extends ChangeNotifier`: mantiene `Session` en memoria, persiste token en `flutter_secure_storage` (Keychain/Keystore), resto (role, IDs, perfil) en `shared_preferences`.
- Métodos: `saveSession()`, `restoreSession()`, `clear()`. Getters: `token`, `role`, `userId`, `patientId`, `doctorId`, `medicalRecordId`, `receptionistId`, `userProfile`, `subscriptionStatus`, `isDoctor`, `needsSubscriptionGate`.
- `ApiClient` lee token del `SessionManager` — muere el static.
- `LoginProvider`: solo `login()` / `reset()` / estado del form. En éxito llama `sessionManager.saveSession(...)`. Solo `login_page` lo consume.
- Páginas consumen sesión vía `ChangeNotifierProvider.value(sessionManager)` en `app.dart`.
- `updateProfile()` se muda a un `ProfileProvider` en `features/profile`.

---

## Fase 0 — Mapeo (fan-out ligero, ~4 agentes, paralelo)

Un agente por grupo de features lee los 28 consumidores y produce un mapa estructurado (JSON):

| Campo | Contenido |
|---|---|
| `file` | ruta del consumidor |
| `members` | qué miembros de `LoginProvider` lee (`patientId`, `isDoctor`, `reset()`, ...) |
| `kind` | *sesión* (migra a `SessionManager`) vs *flujo de login* (se queda) |
| `edge_cases` | patrones raros (mutaciones, `setPatientId`, listeners) |

El mapa alimenta las fases 1–4. Detecta casos raros **antes** de tocar código.

## Fase 1 — Arquitectura (panel de jueces, 3 + 1 agentes)

Tres agentes diseñan el contrato de `SessionManager` de forma independiente, cada uno con una lente:

1. **Seguridad** — token en `flutter_secure_storage`; decidir destino de `_userPassword` en memoria; qué se persiste y qué no.
2. **Costo de migración** — API que minimice el diff en las 28 páginas (getters con los mismos nombres que hoy).
3. **Idioma Flutter** — `ChangeNotifier` vs `ValueListenable`; restore al arranque; interacción con `SessionTimeoutListener` y el gate HTTP 402.

Un **juez** sintetiza el contrato final como ADR corto. Decisiones que debe fijar:

- [ ] ¿Restore de sesión al arrancar entra en scope?
- [ ] ¿`ApiClient` lee el token del manager, o el manager se lo inyecta?
- [ ] ¿Qué pasa con `savedPatientId` del flujo registro→login (`login_provider.dart:68-75`)?
- [ ] ¿`updateProfile()` se muda en este workflow o en uno posterior?

**Gate:** el ADR es el contrato vinculante para Fases 2–4.

## Fase 2 — Núcleo (1 agente, secuencial — archivos acoplados)

Un solo agente implementa contra el contrato:

- `core/session/session_manager.dart` + tests unitarios (save/restore/clear).
- `flutter_secure_storage` en `pubspec.yaml`.
- `ApiClient` sin campo static.
- `LoginProvider` adelgazado (solo login/form).
- Registro en `app.dart` (CoreModule + MultiProvider).
- `SessionTimeoutListener` / `SubscriptionGateListener` apuntando al manager.

**Gate:** `flutter analyze` limpio en lo tocado antes de continuar.

## Fase 3 — Migración (pipeline, ~6 agentes, paralelo)

28 páginas agrupadas por feature:

| Lote | Archivos |
|---|---|
| appointments | 4 páginas |
| chat | 4 páginas |
| dashboard | 5 páginas |
| forums | 6 páginas |
| patients + patient_diaries | 4 páginas |
| resto (profile, register, users, login) | 5 páginas |

Archivos disjuntos → paralelo seguro, **sin worktrees**. Cada agente migra su lote usando el mapa de Fase 0: `read<LoginProvider>().patientId` → `read<SessionManager>().patientId`. `LoginProvider` queda solo donde es flujo de login real (`login_page`).

## Fase 4 — Calidad (fan-out por dimensión + verificación adversarial)

Cuatro revisores, una dimensión cada uno:

| Dimensión | Qué verifica |
|---|---|
| Correctitud | `reset()` limpia todo; `patientId` de registro sobrevive al login; `needsSubscriptionGate` intacto |
| Seguridad | token nunca en texto plano; password no persiste |
| Conformidad arquitectónica | patrón CLAUDE.md respetado (module → provider, skeletons, Future.wait) |
| Completitud | cero lecturas de sesión residuales en `LoginProvider` fuera de login |

Cada hallazgo pasa por un **verificador adversarial** (¿es real?). Los confirmados van a agentes de fix. **Loop hasta seco** (2 rondas sin hallazgos nuevos).

## Fase 5 — Validación (secuencial)

1. `flutter analyze` → cero errores nuevos.
2. `flutter test` → suite existente + tests nuevos de `SessionManager` + test de widget del flujo login→dashboard.
3. `flutter build windows` (smoke de compilación).
4. Reporte final: qué cambió, decisiones del ADR, resultados de pruebas.

---

## Estimación y riesgos

- **Agentes:** ~20–25 total. Fases 0/3/4 paralelas; 2/5 secuenciales.
- **Riesgo principal:** flujo registro→login con `patientId` preservado — el mapa de Fase 0 lo marca explícito para que Fase 2 no lo rompa.
- **Riesgo secundario:** `SessionTimeoutListener` llama `reset()` vía `navigatorKey` sin context — verificar que el logout global siga funcionando.
- **Fuera de scope:** cambios de backend, UI nueva, refactor de otros god nodes (`DashboardProvider`, `ForumsProvider`).
