import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/network/auth_interceptor.dart';
import 'package:kripta_mobile/core/storage/secure_token_store.dart';
import 'package:kripta_mobile/data/repositories/auth_repository_impl.dart';
import 'package:kripta_mobile/data/repositories/repositorio_conteudo.dart';
import 'package:kripta_mobile/data/repositories/repositorio_gamificacao.dart';
import 'package:kripta_mobile/data/repositories/academic_repository.dart';
import 'package:kripta_mobile/domain/entities/entities.dart';

class MemoryTokens implements TokenStore {
  String? token;
  @override
  Future<void> clear() async {
    token = null;
  }

  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }
}

void main() {
  const base = String.fromEnvironment('TEST_API_URL');
  test(
    'Flutter usa PostgreSQL: sessão, tarefas entre clientes, materiais, agenda, XP e Kai',
    () async {
      final store = MemoryTokens();
      final dio = Dio(BaseOptions(baseUrl: base));
      final interceptor = AuthInterceptor(
        tokenStore: store,
        onSessionExpired: () {},
      );
      dio.interceptors.add(interceptor);
      final auth = AuthRepositoryImpl(dio: dio, tokenStore: store);
      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final user = await auth.cadastrar(
        nome: 'Teste Flutter',
        email: 'flutter$suffix@example.test',
        senha: 'TesteSeguro123!',
        perfil: PerfilUsuario.aluno,
        rm: suffix,
      );
      expect(user.isSuccess, true, reason: user.failureOrNull?.message);
      interceptor.invalidateTokenCache();
      expect(
        (await auth.usuarioAtual()).valueOrNull?.perfil,
        PerfilUsuario.aluno,
      );
      final web = Dio(
        BaseOptions(
          baseUrl: base,
          headers: {'Authorization': 'Bearer ${store.token}'},
        ),
      );
      final task = await web.post<Map<String, dynamic>>(
        '/tarefas',
        data: {
          'title': 'Criada por outro cliente',
          'priority': 'MEDIUM',
          'dueDate': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final id = task.data!['id'] as int;
      final tasks = TarefaRepositoryImpl(dio: dio);
      expect((await tasks.listar()).valueOrNull!.any((t) => t.id == id), true);
      expect((await tasks.alternarConclusao(id)).valueOrNull!.concluida, true);
      await tasks.alternarConclusao(id);
      expect(
        (await web.get<Map<String, dynamic>>('/tarefas/$id'))
            .data!['completed'],
        true,
      );
      final game = GamificacaoRepositoryImpl(dio: dio);
      expect((await game.estatisticas()).valueOrNull!.xp, 25);
      expect(
        (await game.conquistas()).valueOrNull!.single.titulo,
        'Primeira tarefa',
      );
      expect(
        (await DashboardRepositoryImpl(
          dio: dio,
        ).carregar()).valueOrNull!.gamificacao.xp,
        25,
      );
      final subject = (await DisciplinaRepositoryImpl(
        dio: dio,
      ).criar(nome: 'Matéria real', cor: '#112233')).valueOrNull!;
      final unit = (await UnidadeRepositoryImpl(
        dio: dio,
      ).criar(disciplinaId: subject.id, nome: 'Unidade real')).valueOrNull!;
      expect(unit.disciplinaId, subject.id);
      final material = (await MaterialRepositoryImpl(dio: dio).criar(
        unidadeId: unit.id,
        titulo: 'Link',
        tipo: TipoMaterial.link,
        url: 'https://example.com',
      )).valueOrNull!;
      expect(material.unidadeId, unit.id);
      final academic = AcademicRepository(dio: dio);
      expect((await academic.approved()).isSuccess, true);
      expect(
        (await academic.createEvent(
          'Evento Flutter',
          DateTime.now(),
        )).isSuccess,
        true,
      );
      final notices = (await AvisoRepositoryImpl(
        dio: dio,
      ).listar()).valueOrNull!;
      final notice = notices.firstWhere((n) => n.titulo == 'Evento Flutter');
      expect((await academic.readNotice(notice.id)).isSuccess, true);
      expect(
        (await AvisoRepositoryImpl(
          dio: dio,
        ).listar()).valueOrNull!.firstWhere((n) => n.id == notice.id).lido,
        true,
      );
      expect(
        (await CalendarioRepositoryImpl(dio: dio).listarPeriodo(
          inicio: DateTime.now(),
          fim: DateTime.now(),
        )).valueOrNull!.any((e) => e.titulo == 'Evento Flutter'),
        true,
      );
      expect(
        (await KaiRepositoryImpl(dio: dio).enviar('Olá'))
            .failureOrNull
            ?.statusCode,
        503,
      );
      await auth.sair();
      interceptor.invalidateTokenCache();
      expect(await auth.temSessaoAtiva(), false);
      final login = await auth.entrar(
        email: 'flutter$suffix@example.test',
        senha: 'TesteSeguro123!',
      );
      expect(login.isSuccess, true);
      interceptor.invalidateTokenCache();
      expect((await game.estatisticas()).valueOrNull!.xp, 25);
      await expectLater(
        dio.delete<Object>('/users/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'conflito de vínculos',
            409,
          ),
        ),
      );
      expect((await auth.usuarioAtual()).isSuccess, true);
      dio.close();
      web.close();
    },
    skip: base.isEmpty
        ? 'Defina TEST_API_URL para executar contra a API real.'
        : false,
  );
}
