/// Testes de unidade das entidades e do `Result`.
///
/// Cobrem as regras que a UI e os repositórios mais usam e que quebram de
/// forma silenciosa: ordenação de tarefas atrasadas, cálculo de XP e o
/// `switch` de [Result] para [Failure].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/error/failure.dart';
import 'package:kripta_mobile/core/utils/result.dart';
import 'package:kripta_mobile/domain/entities/entities.dart';

void main() {
  group('Tarefa', () {
    Tarefa comPrazo(DateTime? prazo, {bool concluida = false}) =>
        Tarefa(id: 1, titulo: 'Revisar', prazo: prazo, concluida: concluida);

    test('atrasada ignora a hora, comparando só o dia', () {
      // Vence hoje às 23h, mas são 10h: não está atrasada.
      expect(comPrazo(DateTime(2026, 9, 28, 23)).atrasada, isFalse);
      // Venceu ontem: atrasada.
      expect(comPrazo(DateTime(2026, 9, 27, 23, 59)).atrasada, isTrue);
    });

    test('tarefa concluída nunca fica atrasada', () {
      expect(comPrazo(DateTime(2026, 1, 1), concluida: true).atrasada, isFalse);
    });

    test('tarefa sem prazo nunca fica atrasada', () {
      expect(comPrazo(null).atrasada, isFalse);
    });

    test('venceHoje só é verdadeiro no dia do prazo', () {
      expect(comPrazo(DateTime(2026, 9, 28, 23)).venceHoje, isTrue);
      expect(comPrazo(DateTime(2026, 9, 29, 1)).venceHoje, isFalse);
    });
  });

  group('PerfilUsuario.fromWire', () {
    test('conhece os papéis do backend', () {
      expect(PerfilUsuario.fromWire('ADMIN'), PerfilUsuario.admin);
      expect(PerfilUsuario.fromWire('USUARIO'), PerfilUsuario.usuario);
    });

    test('papel desconhecido não quebra o login', () {
      // Um papel novo no backend não pode impedir o app de abrir.
      expect(PerfilUsuario.fromWire('PROFESSOR'), PerfilUsuario.usuario);
      expect(PerfilUsuario.fromWire(null), PerfilUsuario.usuario);
    });
  });

  group('TipoMaterial.fromWire', () {
    test('mapeia os valores do wire', () {
      expect(TipoMaterial.fromWire('PDF'), TipoMaterial.pdf);
      expect(TipoMaterial.fromWire('VIDEO'), TipoMaterial.video);
    });

    test('valor desconhecido cai no padrão', () {
      // O backend pode ganhar um tipo novo; a UI deve mostrar o genérico
      // em vez de quebrar o cartão de material.
      expect(TipoMaterial.fromWire('DESCONHECIDO'), TipoMaterial.outro);
    });
  });

  group('Result', () {
    const falha = FailureResult<int>(UnexpectedFailure(message: 'x'));

    test('when recebe o valor em Success', () {
      expect(
        const Success<int>(42)
            .when(casoSucesso: (int v) => v, casoFalha: (Failure f) => -1),
        42,
      );
    });

    test('when recebe a falha em FailureResult', () {
      expect(
        falha.when(
          casoSucesso: (int v) => v,
          casoFalha: (Failure f) => f.message,
        ),
        'x',
      );
    });

    test('map preserva a falha e não executa o transform', () {
      var chamado = false;
      final mapeado = falha.map<String>((int v) {
        chamado = true;
        return '$v';
      });

      expect(chamado, isFalse, reason: 'transform não deve rodar em falha');
      expect(mapeado, isA<FailureResult<String>>());
    });

    test('map aplica o transform no sucesso', () {
      expect(
        const Success<int>(42).map((int v) => v * 2),
        const Success<int>(84),
      );
    });

    test('isSuccess e isFailure são mutuamente exclusivos', () {
      expect(const Success<int>(1).isSuccess, isTrue);
      expect(const Success<int>(1).isFailure, isFalse);
      expect(falha.isFailure, isTrue);
      expect(falha.isSuccess, isFalse);
    });
  });
}
