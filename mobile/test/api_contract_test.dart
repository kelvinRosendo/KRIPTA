import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/network/auth_interceptor.dart';
import 'package:kripta_mobile/data/repositories/auth_repository_impl.dart';
import 'package:kripta_mobile/data/repositories/repositorio_conteudo.dart';
import 'package:kripta_mobile/data/repositories/repositorio_gamificacao.dart';
import 'package:kripta_mobile/domain/entities/entities.dart';

import 'api_integration_test.dart' show MemoryTokens;

class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final (int, Object) Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    final (status, body) = reply(o);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'cadastro envia RM e ALUNO, login persiste token, expiração é propagada',
    () async {
      final tokens = MemoryTokens();
      var expired = 0;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/'));
      final interceptor = AuthInterceptor(
        tokenStore: tokens,
        onSessionExpired: () => expired++,
      );
      dio.interceptors.add(interceptor);
      dio.httpClientAdapter = Adapter((o) {
        expect(o.uri.path.startsWith('/api/'), true);
        if (o.path == '/auth/register') {
          expect((o.data as Map)['rm'], '123');
          expect((o.data as Map)['tipo'], 'ALUNO');
          return (201, {'id': 1});
        }
        if (o.path == '/auth/login') {
          return (
            200,
            {
              'token': 'valid',
              'expiresIn': 3600,
              'id': 1,
              'nome': 'Aluno',
              'email': 'a@example.test',
              'tipo': 'ALUNO',
            },
          );
        }
        expect(o.headers['Authorization'], 'Bearer valid');
        return (401, {'code': 'NAO_AUTORIZADO', 'message': 'Sessão expirada'});
      });
      final auth = AuthRepositoryImpl(dio: dio, tokenStore: tokens);
      expect(
        (await auth.cadastrar(
          nome: 'Aluno',
          email: 'a@example.test',
          senha: 'senha123',
          perfil: PerfilUsuario.aluno,
          rm: '123',
        )).isSuccess,
        true,
      );
      expect(tokens.token, 'valid');
      interceptor.invalidateTokenCache();
      expect((await auth.usuarioAtual()).failureOrNull?.statusCode, 401);
      expect(expired, 1);
      await auth.sair();
      expect(tokens.token, null);
      dio.close();
    },
  );
  test(
    'notificações e insígnias decodificam o contrato real sem sumir',
    () async {
      final dio = Dio()
        ..httpClientAdapter = Adapter(
          (o) => o.path == '/notificacoes'
              ? (
                  200,
                  [
                    {
                      'id': 9,
                      'title': 'Prova',
                      'message': null,
                      'date': '2026-11-03',
                      'read': true,
                    },
                  ],
                )
              : (
                  200,
                  [
                    {
                      'code': 'FIRST_TASK',
                      'name': 'Primeira tarefa',
                      'earned': true,
                      'earnedAt': '2026-11-03T12:00:00Z',
                      'icon': '🏅',
                    },
                  ],
                ),
        );
      expect(
        (await AvisoRepositoryImpl(dio: dio).listar()).valueOrNull!.single.lido,
        true,
      );
      expect(
        (await GamificacaoRepositoryImpl(
          dio: dio,
        ).conquistas()).valueOrNull!.single.conquistada,
        true,
      );
      dio.httpClientAdapter = Adapter(
        (_) => (
          200,
          [
            {'invalido': true},
          ],
        ),
      );
      expect((await TarefaRepositoryImpl(dio: dio).listar()).isFailure, true);
      dio.close();
    },
  );
  test('Kai propaga indisponibilidade e ausência de rede', () async {
    final dio = Dio()
      ..httpClientAdapter = Adapter(
        (_) =>
            (503, {'code': 'IA_INDISPONIVEL', 'message': 'Kai indisponível'}),
      );
    expect(
      (await KaiRepositoryImpl(dio: dio).enviar('Olá'))
          .failureOrNull
          ?.statusCode,
      503,
    );
    dio.httpClientAdapter = Adapter(
      (o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      ),
    );
    expect((await TarefaRepositoryImpl(dio: dio).listar()).isFailure, true);
    dio.close();
  });
}
