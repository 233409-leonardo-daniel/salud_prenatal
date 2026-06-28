import '../data/datasources/appointment_remote_data_source.dart';
import '../data/repositories/appointment_repository_impl.dart';
import '../domain/repositories/appointment_repository.dart';
import '../domain/usecases/get_appointments_usecase.dart';
import '../domain/usecases/create_appointment_usecase.dart';
import '../domain/usecases/update_appointment_usecase.dart';
import '../domain/usecases/delete_appointment_usecase.dart';
import '../domain/usecases/get_appointments_use_case.dart';
import '../domain/usecases/get_appointment_by_id_use_case.dart';
import '../domain/usecases/update_appointment_status_use_case.dart';
import '../domain/usecases/check_availability_use_case.dart';

class AppointmentModule {
  late final AppointmentRepository appointmentRepository;
  late final GetAppointmentsByUserIdUsecase getAppointmentsByUserIdUsecase;
  late final CreateAppointmentUsecase createAppointmentUsecase;
  late final UpdateAppointmentUsecase updateAppointmentUsecase;
  late final DeleteAppointmentUsecase deleteAppointmentUsecase;
  
  late final GetAppointmentsUseCase getAppointmentsUseCase;
  late final GetAppointmentByIdUseCase getAppointmentByIdUseCase;
  late final UpdateAppointmentStatusUseCase updateAppointmentStatusUseCase;
  late final CheckAvailabilityUseCase checkAvailabilityUseCase;

  AppointmentModule() {
    _initDependencies();
  }

  void _initDependencies() {
    appointmentRepository = AppointmentRepositoryImpl(
      AppointmentRemoteDataSourceImpl(),
    );
    getAppointmentsByUserIdUsecase = GetAppointmentsByUserIdUsecase(appointmentRepository);
    createAppointmentUsecase = CreateAppointmentUsecase(appointmentRepository);
    updateAppointmentUsecase = UpdateAppointmentUsecase(appointmentRepository);
    deleteAppointmentUsecase = DeleteAppointmentUsecase(appointmentRepository);
    
    getAppointmentsUseCase = GetAppointmentsUseCase(appointmentRepository);
    getAppointmentByIdUseCase = GetAppointmentByIdUseCase(appointmentRepository);
    updateAppointmentStatusUseCase = UpdateAppointmentStatusUseCase(appointmentRepository);
    checkAvailabilityUseCase = CheckAvailabilityUseCase(appointmentRepository);
  }
}
