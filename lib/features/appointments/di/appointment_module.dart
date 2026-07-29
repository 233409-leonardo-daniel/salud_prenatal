import '../data/datasources/appointment_remote_data_source.dart';
import '../data/repositories/appointment_repository_impl.dart';
import '../domain/repositories/appointment_repository.dart';
import '../domain/usecases/get_appointments_usecase.dart';
import '../domain/usecases/create_appointment_usecase.dart';
import '../domain/usecases/update_appointment_usecase.dart';
import '../domain/usecases/delete_appointment_usecase.dart';
import '../domain/usecases/get_filtered_appointments_usecase.dart';
import '../domain/usecases/get_appointment_by_id_usecase.dart';
import '../domain/usecases/update_appointment_status_usecase.dart';
import '../../../../core/network/api_client.dart';

class AppointmentModule {
  late final AppointmentRepository appointmentRepository;
  late final GetAppointmentsByUserIdUsecase getAppointmentsByUserIdUsecase;
  late final CreateAppointmentUsecase createAppointmentUsecase;
  late final UpdateAppointmentUsecase updateAppointmentUsecase;
  late final DeleteAppointmentUsecase deleteAppointmentUsecase;

  late final GetFilteredAppointmentsUsecase getAppointmentsUseCase;
  late final GetAppointmentByIdUsecase getAppointmentByIdUseCase;
  late final UpdateAppointmentStatusUsecase updateAppointmentStatusUseCase;

  AppointmentModule(ApiClient apiClient) {
    _initDependencies(apiClient);
  }

  void _initDependencies(ApiClient apiClient) {
    appointmentRepository = AppointmentRepositoryImpl(
      AppointmentRemoteDataSourceImpl(apiClient: apiClient),
    );
    getAppointmentsByUserIdUsecase = GetAppointmentsByUserIdUsecase(appointmentRepository);
    createAppointmentUsecase = CreateAppointmentUsecase(appointmentRepository);
    updateAppointmentUsecase = UpdateAppointmentUsecase(appointmentRepository);
    deleteAppointmentUsecase = DeleteAppointmentUsecase(appointmentRepository);

    getAppointmentsUseCase = GetFilteredAppointmentsUsecase(appointmentRepository);
    getAppointmentByIdUseCase = GetAppointmentByIdUsecase(appointmentRepository);
    updateAppointmentStatusUseCase = UpdateAppointmentStatusUsecase(appointmentRepository);
  }
}
