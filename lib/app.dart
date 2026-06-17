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
import 'theme/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentModule = AppointmentModule();

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
