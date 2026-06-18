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
import 'core/theme/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    final appointmentModule = AppointmentModule();
    final loginModule = LoginModule();
    final registerModule = RegisterModule();

    return MultiProvider(
      providers: [
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
        },
      ),
    );
  }
}
