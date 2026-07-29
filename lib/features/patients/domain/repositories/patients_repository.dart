import '../entities/patient.dart';
import '../../../profile/domain/entities/user_profile.dart';

abstract class PatientsRepository {
  Future<List<PatientEntity>> getPatientsByDoctor(String doctorId);
  Future<UserProfile> getPatientDetails(String userId);
}
