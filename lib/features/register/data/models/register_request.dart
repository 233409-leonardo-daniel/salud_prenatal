class PatientRegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String birthdate;
  final String bloodType;
  final int weeksAtRegistration;
  final String lastMenstrualPeriod;

  const PatientRegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.birthdate,
    required this.bloodType,
    required this.weeksAtRegistration,
    required this.lastMenstrualPeriod,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'birthdate': birthdate,
      'blood_type': bloodType,
      'weeks_at_registration': weeksAtRegistration,
      'last_menstrual_period': lastMenstrualPeriod,
    };
  }
}

class DoctorRegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String professionalLicense;
  final String specialty;
  final String office;

  const DoctorRegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.professionalLicense,
    required this.specialty,
    required this.office,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'professional_license': professionalLicense,
      'specialty': specialty,
      'office': office,
    };
  }
}
