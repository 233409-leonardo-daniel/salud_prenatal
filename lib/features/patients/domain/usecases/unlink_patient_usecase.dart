import '../repositories/patients_repository.dart';

/// Desvincula a una paciente del doctor (DELETE
/// /doctors/{doctor_id}/patients/{patient_id}). No borra a la paciente ni su
/// expediente: solo rompe la relación doctor-paciente.
class UnlinkPatientUseCase {
  final PatientsRepository repository;

  UnlinkPatientUseCase(this.repository);

  Future<void> call(String doctorId, String patientId) async {
    return await repository.unlinkPatient(doctorId, patientId);
  }
}
