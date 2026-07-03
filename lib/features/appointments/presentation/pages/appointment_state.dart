enum AppointmentsListStatus { initial, loading, success, error }
enum CreateAppointmentStatus { initial, loading, success, error }
enum DeleteAppointmentStatus { initial, loading, success, error }
enum UpdateAppointmentStatus { initial, loading, success, error }

/// Estado de las operaciones de AppointmentsProvider que no son la carga
/// inicial de citas del usuario (listado filtrado, actualización de estatus
/// y verificación de disponibilidad). Antes vivía como `ViewState` inline
/// dentro de appointment_provider.dart.
enum AppointmentActionStatus { initial, loading, success, error }
