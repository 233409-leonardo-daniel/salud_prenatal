class PatientRegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String birthdate;
  final int? doctorId;

  const PatientRegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.birthdate,
    this.doctorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'birthdate': birthdate,
      if (doctorId != null) 'doctor_id': doctorId,
    };
  }
}

class ReceptionistRegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String password;

  const ReceptionistRegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
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
