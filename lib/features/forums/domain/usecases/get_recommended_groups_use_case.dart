import '../entities/community_group.dart';
import '../repositories/forums_repository.dart';

/// Grupos etiquetados con el cluster de riesgo de la usuaria; sin cluster o
/// sin coincidencias, el backend devuelve todos los grupos.
class GetRecommendedGroupsUseCase {
  final ForumsRepository repository;

  GetRecommendedGroupsUseCase(this.repository);

  Future<List<CommunityGroup>> call() {
    return repository.getRecommendedGroups();
  }
}
