import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';
import '../mappers/appointment_mapper.dart';
import '../models/appointment_dto.dart';
import '../../../../core/enums/appointment_status.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  AppointmentRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Appointment>> getAppointmentsByUserId(String userId, {bool isDoctor = false}) async {
    final dtos = await remoteDataSource.getAppointmentsByUserId(userId, isDoctor: isDoctor);
    return dtos.map((dto) => AppointmentMapper.dtoToEntity(dto)).toList();
  }

  @override
  Future<List<Appointment>> getAppointments({int? doctorId, int? patientId, String? status, String? date}) async {
    final dtos = await remoteDataSource.getAppointments(doctorId: doctorId, patientId: patientId, status: status, date: date);
    return dtos.map((dto) => AppointmentMapper.dtoToEntity(dto)).toList();
  }

  @override
  Future<Appointment> getAppointmentById(int id) async {
    final dto = await remoteDataSource.getAppointmentById(id);
    return AppointmentMapper.dtoToEntity(dto);
  }

  @override
  Future<void> createAppointment(Appointment appointment) async {
    final dto = AppointmentMapper.entityToDto(appointment);
    await remoteDataSource.createAppointment(dto);
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    final dto = AppointmentMapper.entityToDto(appointment);
    await remoteDataSource.updateAppointment(dto);
  }

  @override
  Future<void> updateAppointmentStatus(int id, AppointmentStatus status) async {
    final statusDto = StatusUpdateDto(status: status.value);
    await remoteDataSource.updateAppointmentStatus(id, statusDto);
  }

  @override
  Future<void> deleteAppointment(int id) async {
    await remoteDataSource.deleteAppointment(id);
  }

  @override
  Future<Map<String, dynamic>> checkAvailability(int doctorId, String date) async {
    return remoteDataSource.checkAvailability(doctorId, date);
  }
}
