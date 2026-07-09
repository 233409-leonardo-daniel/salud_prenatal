import '../entities/forum_report.dart';
import '../repositories/forums_repository.dart';

class CreateReportUseCase {
  final ForumsRepository repository;

  CreateReportUseCase(this.repository);

  Future<void> call(ForumReport report) {
    return repository.createReport(report);
  }
}
