import '../entities/patient.dart';
import '../../../login/domain/entities/user_profile.dart';

abstract class PatientsRepository {
  Future<List<PatientEntity>> getPatientsByDoctor(String doctorId);
  Future<UserProfile> getPatientDetails(String userId);
}
