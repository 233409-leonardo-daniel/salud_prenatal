import '../data/datasources/dashboard_remote_data_source.dart';
import '../../../../core/network/api_client.dart';

class DashboardModule {
  late final DashboardRemoteDataSource remoteDataSource;

  DashboardModule(ApiClient apiClient) {
    remoteDataSource = DashboardRemoteDataSourceImpl(apiClient: apiClient);
  }
}
