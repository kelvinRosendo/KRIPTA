import '../../core/config/api_endpoints.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/result.dart';
import 'api_repository_base.dart';

/// Consome publicações e eventos da instituição.
class AcademicRepository extends ApiRepositoryBase {
  /// Compartilha o cliente autenticado.
  AcademicRepository({required super.dio});
  @override
  final log = AppLogger('academic');

  /// Lista somente conteúdo aprovado.
  Future<Result<List<Map<String, dynamic>>>> approved() => guard(
    () async => corpoLista(await dio.get<Object>(ApiEndpoints.approvedContent)),
  );

  /// Cria evento pessoal no dia civil selecionado.
  Future<Result<void>> createEvent(String title, DateTime day) =>
      guard(() async {
        await dio.post<Object>(
          ApiEndpoints.calendarEvents,
          data: {
            'title': title,
            'date': day.toIso8601String().substring(0, 10),
            'scope': 'PESSOAL',
            'type': 'EVENT',
          },
        );
      });

  /// Registra a leitura idempotente de uma notificação.
  Future<Result<void>> readNotice(int id) => guard(() async {
    await dio.patch<Object>(ApiEndpoints.readNotice(id));
  });
}
