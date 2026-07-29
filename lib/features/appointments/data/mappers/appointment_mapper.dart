import '../../domain/entities/appointment.dart';
import '../models/appointment_dto.dart';

class AppointmentMapper {
  static Appointment dtoToEntity(AppointmentDto dto) {
    return Appointment(
      id: dto.id,
      doctorId: dto.doctorId,
      patientId: dto.patientId,
      dateTime: DateTime.tryParse(dto.date) ?? DateTime.now(),
      status: AppointmentStatusExtension.fromString(dto.status),
      reason: dto.reason,
    );
  }

  static AppointmentDto entityToDto(Appointment entity) {
    return AppointmentDto(
      id: entity.id,
      doctorId: entity.doctorId,
      patientId: entity.patientId,
      date: entity.dateTime.toIso8601String(),
      status: entity.status.value,
      reason: entity.reason,
    );
  }
}
