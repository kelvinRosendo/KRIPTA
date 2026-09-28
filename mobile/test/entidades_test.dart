/// Testes de unidade das entidades e do `Result`.
///
/// Cobrem as regras que a UI e os repositórios mais usam e que quebram de
/// forma silenciosa: ordenação de tarefas atrasadas, cálculo de XP e o
/// `switch` de [Result] para [Failure].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/error/failure.dart';
import 'package:kripta_mobile/core/utils/app_number_format.dart';
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

  group('tituloDoNivel', () {
    test('usa a escala do protótipo', () {
      expect(tituloDoNivel(1), 'Iniciante');
      expect(tituloDoNivel(4), 'Curioso');
      expect(tituloDoNivel(6), 'Exploradora');
      expect(tituloDoNivel(10), 'Lenda');
    });

    test('trava os extremos em vez de estourar a lista', () {
      // Estudar demais não pode virar RangeError na tela.
      expect(tituloDoNivel(0), 'Iniciante');
      expect(tituloDoNivel(-3), 'Iniciante');
      expect(tituloDoNivel(11), 'Lenda');
      expect(tituloDoNivel(9999), 'Lenda');
    });
  });

  group('ResumoGamificacao', () {
    ResumoGamificacao comMinutos(int minutos) => ResumoGamificacao(
      xp: 1240,
      nivel: 4,
      sequenciaDias: 7,
      minutosHoje: minutos,
    );

    test('o anel mede o progresso contra a meta de 10 minutos', () {
      expect(comMinutos(0).progressoHoje, 0);
      expect(comMinutos(5).progressoHoje, 0.5);
      expect(comMinutos(7).progressoHoje, closeTo(0.7, 0.001));
      expect(comMinutos(10).progressoHoje, 1);
    });

    test('passar da meta não estoura o anel', () {
      // O `CircularProgressIndicator` crasha com value > 1, então o clamp
      // é o que protege a Home de um backend bem-intencionado demais.
      expect(comMinutos(25).progressoHoje, 1);
    });

    test('minutos que faltam nunca ficam negativos', () {
      expect(comMinutos(7).minutosRestantes, 3);
      expect(comMinutos(10).minutosRestantes, 0);
      expect(comMinutos(12).minutosRestantes, 0);
    });

    test('sabe dizer se a meta de hoje foi batida', () {
      expect(comMinutos(7).metaBatida, isFalse);
      expect(comMinutos(9).metaBatida, isFalse);
      expect(comMinutos(10).metaBatida, isTrue);
    });

    test('sem o campo minutesToday o anel fica em zero, não quebrado', () {
      // É o que o mapper entrega enquanto o backend não manda o campo.
      const resumo = ResumoGamificacao(xp: 10, nivel: 1, sequenciaDias: 0);
      expect(resumo.minutosHoje, 0);
      expect(resumo.progressoHoje, 0);
      expect(resumo.metaBatida, isFalse);
    });
  });

  group('AppNumberFormat', () {
    test('separa milhar com ponto, como no web', () {
      expect(AppNumberFormat.milhar(1240), '1.240');
      expect(AppNumberFormat.milhar(999), '999');
      expect(AppNumberFormat.milhar(12500), '12.500');
    });

    test('a forma compacta arredonda em 10 mil', () {
      expect(AppNumberFormat.compacto(999), '999');
      expect(AppNumberFormat.compacto(1240), '1,2 mil');
      expect(AppNumberFormat.compacto(12500), '13 mil');
    });
  });
}
