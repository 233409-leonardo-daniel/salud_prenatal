# Diagramas de arquitectura — Salud Prenatal

Cada bloque es un diagrama Mermaid independiente. Cópialos tal cual en cualquier
visor compatible (GitHub, Mermaid Live Editor, Obsidian, etc.).

## 1. Capas de una feature (Clean Architecture, feature-first)

```mermaid
flowchart TB
    subgraph Presentation["presentation/"]
        Page["pages/*Page"]
        Widget["widgets/*"]
        Prov["providers/*Provider (ChangeNotifier)"]
    end

    subgraph Domain["domain/ (no depende de nada de afuera)"]
        Entity["entities/*Entity"]
        RepoIface["repositories/*Repository (abstract)"]
        UseCase["usecases/*Usecase"]
    end

    subgraph Data["data/"]
        Model["models/*Model (fromJson/toJson)"]
        RepoImpl["repositories/*RepositoryImpl"]
        DataSource["datasources/*RemoteDataSource"]
    end

    subgraph DI["di/"]
        Module["*Module(apiClient)"]
    end

    Page --> Prov
    Widget --> Page
    Prov --> UseCase
    UseCase --> RepoIface
    RepoImpl -.implementa.-> RepoIface
    RepoImpl --> DataSource
    Model -.extends.-> Entity
    DataSource --> ApiClient["core/network/ApiClient"]

    Module --> DataSource
    Module --> RepoImpl
    Module --> UseCase
    Module --> Prov

    style Domain fill:#e8f5e9,stroke:#2e7d32
    style Data fill:#e3f2fd,stroke:#1565c0
    style Presentation fill:#fff3e0,stroke:#ef6c00
    style DI fill:#f3e5f5,stroke:#6a1b9a
```

## 2. Composition root (`app.dart`) — dónde se arma y dónde se inyecta

```mermaid
flowchart TB
    Main["main.dart"] --> MyApp["MyApp (StatefulWidget)"]

    MyApp -->|initState, una sola vez| CoreModule["CoreModule\n(ApiClient único, QrService)"]
    MyApp -->|initState| LoginModule["LoginModule(apiClient)"]
    MyApp -->|initState| ProfileModule["ProfileModule(apiClient)"]
    MyApp -->|initState| DashboardModule["DashboardModule(apiClient)"]
    MyApp -->|initState| PatientsModule["PatientsModule(apiClient)\n(altas + bajas + invitaciones)"]
    MyApp -->|initState| AppointmentsModule["AppointmentModule(apiClient)"]
    MyApp -->|initState| ChatModule["ChatModule(apiClient)"]
    MyApp -->|initState| ForumsModule["ForumsModule(apiClient)"]
    MyApp -->|initState| OtherModules["... register, subscriptions,\npatient_diaries, users, etc."]

    CoreModule -.mismo ApiClient.-> LoginModule
    CoreModule -.mismo ApiClient.-> ProfileModule
    CoreModule -.mismo ApiClient.-> DashboardModule
    CoreModule -.mismo ApiClient.-> PatientsModule
    CoreModule -.mismo ApiClient.-> AppointmentsModule
    CoreModule -.mismo ApiClient.-> ChatModule
    CoreModule -.mismo ApiClient.-> ForumsModule

    MyApp -->|build, MultiProvider| Providers["MultiProvider"]
    LoginModule -->|usecases inyectados al constructor| Providers
    ProfileModule --> Providers
    DashboardModule --> Providers
    PatientsModule -->|PatientProvider, PatientUnlinkProvider,\nDoctorUnlinkProvider, InvitationProvider| Providers
    AppointmentsModule --> Providers
    ChatModule --> Providers
    ForumsModule --> Providers

    Providers --> Routes["Named routes\n/login /register /dashboard /home\n/patient-diaries /forums /subscription"]
    Routes --> Pages["*Page widgets\n(consumen Provider vía context.watch/read)"]

    style CoreModule fill:#fce4ec,stroke:#ad1457
```

## 3. Cómo trabaja Provider (lectura y notificación)

```mermaid
flowchart LR
    subgraph Widget tree
        PageA["PatientsListPage"]
        PageB["PatientDetailSheet"]
    end

    PageA -->|context.watch| CN["ChangeNotifierProvider<PatientProvider>\n(vive arriba en el árbol, wireado en app.dart)"]
    PageB -->|context.watch| CN

    CN --> UC["Usecase.call(...)"]
    UC --> Repo["RepositoryImpl"]
    Repo --> DS["RemoteDataSource"]
    DS --> API["API REST"]

    API -.response.-> DS
    DS -.entity/model.-> Repo
    Repo -.entity.-> UC
    UC -.resultado.-> CN
    CN -->|notifyListeners()| PageA
    CN -->|notifyListeners()| PageB

    note1["Solo los widgets que hacen watch/context.select\nse reconstruyen; el resto del árbol no."]
    CN -.-> note1
```

## 4. Flujo de una petición completa (ejemplo: login)

```mermaid
sequenceDiagram
    participant U as Usuario
    participant P as LoginPage
    participant Prov as LoginProvider
    participant UC as LoginUsecase
    participant Repo as LoginRepositoryImpl
    participant DS as LoginRemoteDataSource
    participant Api as ApiClient
    participant Srv as API REST

    U->>P: toca "Iniciar sesión"
    P->>Prov: login(email, password)
    Prov->>UC: execute(email, password)
    UC->>Repo: login(email, password)
    Repo->>DS: login(email, password)
    DS->>Api: post('/auth/login', body)
    Api->>Srv: HTTP POST
    Srv-->>Api: 200 { token, user }
    Api-->>DS: response
    DS-->>Repo: UserProfileModel
    Repo-->>UC: UserProfileEntity
    UC-->>Prov: UserProfileEntity
    Prov->>Api: setAuthToken(token)  // static, global
    Prov->>Prov: notifyListeners()
    Prov-->>P: rebuild (context.watch)
    P->>P: Navigator.pushNamed('/dashboard')
```

## 5. Dependencias globales y listeners transversales

```mermaid
flowchart TB
    ApiClient["ApiClient\n(token estático compartido por\nTODAS las instancias ApiClient())"]
    Stream["ApiClient.onPaymentRequired\n(broadcast stream, emite en HTTP 402)"]
    NavKey["MyApp.navigatorKey\n(GlobalKey<NavigatorState>)"]

    ApiClient -->|cualquier request 402| Stream

    subgraph Listeners["Widgets sin BuildContext propio, envuelven toda la app"]
        SessionTL["SessionTimeoutListener\n(20 min inactividad, shared_preferences\n+ ciclo de vida de la app)"]
        SubGate["SubscriptionGateListener\n(escucha onPaymentRequired)"]
    end

    Stream --> SubGate
    SubGate -->|navigatorKey.currentState.pushNamed| NavKey
    SessionTL -->|logout + navigatorKey.currentState.pushNamed| NavKey
    NavKey --> RouteLogin["/login"]
    NavKey --> RouteSub["/subscription"]

    QrService["QrService (CoreModule)"] -.disponible para\ncualquier feature.-> Features["features/* que escanean QR"]

    style ApiClient fill:#ffebee,stroke:#c62828
    style Listeners fill:#e8eaf6,stroke:#283593
```

## 6. Vertical slice real: `patients` tras la fusión con `unlink_requests`

```mermaid
flowchart TB
    subgraph patients["features/patients/"]
        direction TB
        subgraph dom["domain/"]
            E1["PatientEntity"]
            E2["UnlinkRequestEntity"]
            R1["PatientRepository"]
            R2["UnlinkRequestRepository"]
            UC1["Alta: InvitationUsecases"]
            UC2["Baja: Create/Get/Cancel/Resolve\nUnlinkRequestUsecase"]
        end
        subgraph dat["data/"]
            DS1["PatientRemoteDataSource"]
            DS2["UnlinkRequestRemoteDataSource"]
        end
        subgraph pres["presentation/"]
            P1["PatientProvider"]
            P2["PatientUnlinkProvider (lado paciente)"]
            P3["DoctorUnlinkProvider (lado doctor)"]
            W1["DoctorUnlinkRequestsSheet"]
        end
        Mod["PatientsModule\n(un solo módulo, compone alta y baja:\nmisma relación paciente-doctor)"]
    end

    Mod --> DS1
    Mod --> DS2
    Mod --> P1
    Mod --> P2
    Mod --> P3
    UC1 --> R1
    UC2 --> R2
    R1 -.impl.-> DS1
    R2 -.impl.-> DS2
    P2 --> UC2
    P3 --> UC2
    W1 --> P3

    style patients fill:#e0f7fa,stroke:#00695c
```
