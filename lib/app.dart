import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salud_prenatal/core/network/api_client.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/login/presentation/pages/login_page.dart';
import 'features/register/presentation/pages/register_page.dart';
import 'features/appointments/di/appointment_module.dart';
import 'features/appointments/presentation/providers/appointment_provider.dart';
import 'features/appointments/presentation/providers/create_appointment_provider.dart';
import 'features/appointments/presentation/providers/update_appointment_provider.dart';
import 'features/appointments/presentation/providers/delete_appointment_provider.dart';
import 'features/login/di/login_module.dart';
import 'features/login/presentation/providers/login_provider.dart';
import 'features/register/di/register_module.dart';
import 'features/register/presentation/providers/register_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/patients/di/patients_module.dart';
import 'features/patients/presentation/providers/patients_list_provider.dart';
import 'features/patients/presentation/providers/patient_detail_provider.dart';
import 'features/patients/presentation/providers/invitation_provider.dart';
import 'features/dashboard/di/dashboard_module.dart';
import 'core/di/core_module.dart';
import 'core/services/qr_service.dart';
import 'core/services/notification_service.dart';
import 'core/session/session_manager.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/patient_diaries/di/patient_diaries_module.dart';
import 'features/patient_diaries/presentation/providers/patient_diaries_provider.dart';
import 'features/patient_diaries/presentation/pages/patient_diary_page.dart';
import 'features/privacy_policy/di/privacy_policy_module.dart';
import 'features/privacy_policy/presentation/providers/privacy_policy_provider.dart';
import 'core/theme/theme.dart';
import 'features/users/di/user_module.dart';
import 'features/users/presentation/providers/user_provider.dart';
import 'features/chat/di/chat_module.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/presentation/providers/conversations_provider.dart';
import 'features/chat/presentation/providers/contacts_provider.dart';
import 'features/forums/di/forums_module.dart';
import 'features/forums/presentation/providers/forums_provider.dart';
import 'features/forums/presentation/pages/forums_hub_page.dart';
import 'features/subscriptions/di/subscriptions_module.dart';
import 'features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'features/subscriptions/presentation/pages/subscription_plan_page.dart';

import 'core/widgets/subscription_gate_listener.dart';

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final coreModule = CoreModule();
    final apiClient = coreModule.apiClient;
    
    // Inicializar notificaciones push y registrar el token a nivel de
    // dispositivo desde el arranque, haya o no sesión iniciada: así los
    // recordatorios diarios llegan aunque el usuario no esté logueado.
    NotificationService.initialize(apiClient);
    NotificationService.registerDevice();

    final appointmentModule = AppointmentModule(apiClient);
    final loginModule = LoginModule(apiClient);
    final registerModule = RegisterModule(apiClient);
    final patientsModule = PatientsModule(apiClient);
    final patientDiariesModule = PatientDiariesModule(apiClient);
    final privacyPolicyModule = PrivacyPolicyModule();
    final userModule = UserModule(apiClient);
    final chatModule = ChatModule(
      apiClient,
      tokenProvider: () => coreModule.sessionManager.token,
    );
    final dashboardModule = DashboardModule(apiClient);
    final forumsModule = ForumsModule(apiClient);
    final subscriptionsModule = SubscriptionsModule(apiClient);

    // Fase 2 del wiring: adjunta el cargador de perfil al SessionManager para
    // romper el ciclo (se hace tras construir loginModule).
    coreModule.sessionManager.attachProfileLoader(
      (id) => loginModule.getProfileUseCase.execute(id),
    );

    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => apiClient),
        Provider<QrService>(create: (_) => coreModule.qrService),
        // Dueño único de la sesión; su ciclo de vida lo posee CoreModule, por
        // eso se registra con .value (sin auto-dispose ni doble instancia).
        ChangeNotifierProvider<SessionManager>.value(
          value: coreModule.sessionManager,
        ),
        ChangeNotifierProvider(
          create: (_) => AppointmentsProvider(
            appointmentModule.getAppointmentsByUserIdUsecase,
            appointmentModule.getAppointmentsUseCase,
            appointmentModule.updateAppointmentStatusUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CreateAppointmentProvider(
            appointmentModule.createAppointmentUsecase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UpdateAppointmentProvider(
            appointmentModule.updateAppointmentUsecase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DeleteAppointmentProvider(
            appointmentModule.deleteAppointmentUsecase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LoginProvider(
            loginUseCase: loginModule.loginUseCase,
            session: coreModule.sessionManager,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            updateProfileUseCase: loginModule.updateProfileUseCase,
            session: coreModule.sessionManager,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterProvider(
            registerPatientUseCase: registerModule.registerPatientUseCase,
            registerDoctorUseCase: registerModule.registerDoctorUseCase,
            registerReceptionistUseCase: registerModule.registerReceptionistUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            getAllUsersUseCase: dashboardModule.getAllUsersUseCase,
            getPatientsByDoctorUseCase: dashboardModule.getPatientsByDoctorUseCase,
            getMedicalRecordByPatientUseCase: dashboardModule.getMedicalRecordByPatientUseCase,
            getConsultationsByMedicalRecordUseCase: dashboardModule.getConsultationsByMedicalRecordUseCase,
            getConsultationsFromPatientEndpointUseCase: dashboardModule.getConsultationsFromPatientEndpointUseCase,
            getPatientDashboardUseCase: dashboardModule.getPatientDashboardUseCase,
            getDoctorDashboardUseCase: dashboardModule.getDoctorDashboardUseCase,
            getReceptionistDashboardUseCase: dashboardModule.getReceptionistDashboardUseCase,
            createMedicalRecordUseCase: dashboardModule.createMedicalRecordUseCase,
            evaluateRiskUseCase: dashboardModule.evaluateRiskUseCase,
            createConsultationUseCase: dashboardModule.createConsultationUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PatientsListProvider(patientsModule.getDoctorPatientsUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientDetailProvider(
            patientsModule.getPatientDetailsUseCase,
            apiClient,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => InvitationProvider(
            generateInvitationCodeUseCase: patientsModule.generateInvitationCodeUseCase,
            redeemInvitationCodeUseCase: patientsModule.redeemInvitationCodeUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientDiariesProvider(
            getDiariesUseCase: patientDiariesModule.getDiariesUseCase,
            createDiaryUseCase: patientDiariesModule.createDiaryUseCase,
            updateDiaryUseCase: patientDiariesModule.updateDiaryUseCase,
            deleteDiaryUseCase: patientDiariesModule.deleteDiaryUseCase,
            getDiarySymptomsUseCase: patientDiariesModule.getDiarySymptomsUseCase,
            getSymptomHistoryUseCase: patientDiariesModule.getSymptomHistoryUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PrivacyPolicyProvider(
            saveAcceptedPoliciesUseCase:
                privacyPolicyModule.saveAcceptedPoliciesUseCase,
            getAcceptedPoliciesUseCase:
                privacyPolicyModule.getAcceptedPoliciesUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(
            userModule.getDoctorsUseCase,
            userModule.getPatientsUseCase,
            userModule.getUserByIdUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(chatModule.repository),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationsProvider(
            chatModule.getConversationsUseCase,
            chatModule.repository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ContactsProvider(chatModule.getChatContactsUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionsProvider(
            getSubscriptionStatusUseCase: subscriptionsModule.getSubscriptionStatusUseCase,
            createCheckoutSessionUseCase: subscriptionsModule.createCheckoutSessionUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ForumsProvider(
            getSocialProfileUseCase: forumsModule.getSocialProfileUseCase,
            createSocialProfileUseCase: forumsModule.createSocialProfileUseCase,
            updateSocialProfileUseCase: forumsModule.updateSocialProfileUseCase,
            getProfileTimelineUseCase: forumsModule.getProfileTimelineUseCase,
            createGroupUseCase: forumsModule.createGroupUseCase,
            getGroupsUseCase: forumsModule.getGroupsUseCase,
            getRecommendedGroupsUseCase: forumsModule.getRecommendedGroupsUseCase,
            createPostUseCase: forumsModule.createPostUseCase,
            getGlobalFeedUseCase: forumsModule.getGlobalFeedUseCase,
            getRecommendedFeedUseCase: forumsModule.getRecommendedFeedUseCase,
            getGroupFeedUseCase: forumsModule.getGroupFeedUseCase,
            createCommentUseCase: forumsModule.createCommentUseCase,
            getCommentsUseCase: forumsModule.getCommentsUseCase,
            createReportUseCase: forumsModule.createReportUseCase,
            getUserByIdUseCase: userModule.getUserByIdUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Salud Prenatal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/login',
        builder: (context, child) {
          final brightness = MediaQuery.of(context).platformBrightness;
          AppColors.isDarkMode = brightness == Brightness.dark;
          return SubscriptionGateListener(child: child!);
        },
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/home': (context) => const DashboardPage(),
          '/patient-diaries': (context) => const PatientDiaryPage(),
          '/forums': (context) => const ForumsHubPage(),
          '/subscription': (context) => const SubscriptionPlanPage(),
        },
      ),
    );
  }
}
