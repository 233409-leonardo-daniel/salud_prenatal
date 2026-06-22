import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'core/di/core_module.dart';
import 'core/services/qr_service.dart';
import 'features/patient_diaries/di/patient_diaries_module.dart';
import 'features/patient_diaries/presentation/providers/patient_diaries_provider.dart';
import 'features/patient_diaries/presentation/pages/patient_diary_page.dart';
import 'core/theme/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    final appointmentModule = AppointmentModule();
    final loginModule = LoginModule();
    final registerModule = RegisterModule();
    final patientsModule = PatientsModule();
    final coreModule = CoreModule();
    final patientDiariesModule = PatientDiariesModule();

    return MultiProvider(
      providers: [
        Provider<QrService>(create: (_) => coreModule.qrService),
        ChangeNotifierProvider(
          create: (_) => AppointmentsProvider(
            appointmentModule.getAppointmentsByUserIdUsecase,
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
            getProfileUseCase: loginModule.getProfileUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterProvider(
            registerPatientUseCase: registerModule.registerPatientUseCase,
            registerDoctorUseCase: registerModule.registerDoctorUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientsListProvider(
            patientsModule.getDoctorPatientsUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientDetailProvider(
            patientsModule.getPatientDetailsUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => InvitationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientDiariesProvider(
            getDiariesUseCase: patientDiariesModule.getDiariesUseCase,
            createDiaryUseCase: patientDiariesModule.createDiaryUseCase,
            updateDiaryUseCase: patientDiariesModule.updateDiaryUseCase,
            deleteDiaryUseCase: patientDiariesModule.deleteDiaryUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Salud Prenatal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/home': (context) => const DashboardPage(),
          '/patient-diaries': (context) => const PatientDiaryPage(),
        },
      ),
    );
  }
}
