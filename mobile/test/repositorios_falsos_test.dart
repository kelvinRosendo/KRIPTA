/// Testes dos dublês do modo de desenvolvimento.
///
/// O que importa aqui não é o conteúdo do seed, e sim que os três cenários
/// mudem de verdade o que o repository devolve, e que o estado sobreviva
/// entre chamadas — é isso que faz a Home refletir uma tarefa concluída na
/// aba Tarefas.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/error/failure.dart';
import 'package:kripta_mobile/core/utils/result.dart';
import 'package:kripta_mobile/dev/dados_de_exemplo.dart';
import 'package:kripta_mobile/dev/repositorios_falsos.dart';
import 'package:kripta_mobile/domain/entities/entities.dart';
import 'package:kripta_mobile/domain/repositories/repositories.dart';

/// Referência de "hoje" para os testes.
///
/// Precisa ser o relógio real, e não uma data fixa: [Tarefa.atrasada] e
/// [Tarefa.venceHoje] consultam [DateTime.now] por dentro. Com um "hoje"
/// fixo no passado, todas as tarefas do seed apareceriam como atrasadas.
/// Avaliada uma vez para que o teste não atravesse a meia-noite.
final DateTime agora = DateTime.now();

/// Primeiro dia do mês corrente, para as consultas de calendário.
final DateTime inicioDoMes = DateTime(agora.year, agora.month, 1);

/// Último dia do mês corrente.
final DateTime fimDoMes = DateTime(agora.year, agora.month + 1, 0);

BancoFalso _banco(Cenario cenario) =>
    BancoFalso(agora: agora, cenario: cenario);

void main() {
  group('AuthRepositoryFalso', () {
    test('autentica em qualquer cenário, inclusive no de erro', () async {
      // Sem isto o cenário de erro cairia no login: o AuthController trata
      // falha de usuarioAtual como sessão anônima.
      for (final cenario in Cenario.values) {
        final auth = AuthRepositoryFalso(_banco(cenario));
        expect(await auth.temSessaoAtiva(), isTrue, reason: '$cenario');
        expect(await auth.usuarioAtual(), isA<Success<Usuario>>());
      }
    });

    test('sair derruba a sessão e entrar reativa', () async {
      final auth = AuthRepositoryFalso(_banco(Cenario.cheio));

      await auth.sair();
      expect(await auth.temSessaoAtiva(), isFalse);

      final entrou = await auth.entrar(email: 'nova@kripta.dev', senha: 'x');
      expect(entrou.isSuccess, isTrue);
      expect(await auth.temSessaoAtiva(), isTrue);
      expect(entrou.valueOrNull?.email, 'nova@kripta.dev');
    });
  });

  group('cenário cheio', () {
    test('listas devolvem o seed', () async {
      final banco = _banco(Cenario.cheio);

      final disciplinas = await DisciplinaRepositoryFalso(banco).listar();
      final avisos = await AvisoRepositoryFalso(banco).listar();
      final materiais = await MaterialRepositoryFalso(banco)
          .listarPorUnidade(101);

      expect(disciplinas.valueOrNull, isNotEmpty);
      expect(avisos.valueOrNull, isNotEmpty);
      expect(materiais.valueOrNull, hasLength(4));
    });

    test('unidades são filtradas por disciplina', () async {
      final banco = _banco(Cenario.cheio);
      final unidades = await UnidadeRepositoryFalso(banco).listar(1);

      expect(unidades.valueOrNull, hasLength(3));
      expect(
        unidades.valueOrNull!.every((Unidade u) => u.disciplinaId == 1),
        isTrue,
      );
    });
  });

  group('cenário vazio', () {
    test('toda lista volta vazia, sem falhar', () async {
      final banco = _banco(Cenario.vazio);

      final disciplinas = await DisciplinaRepositoryFalso(banco).listar();
      final tarefas = await TarefaRepositoryFalso(banco).listar();
      final avisos = await AvisoRepositoryFalso(banco).listar();
      final conquistas = await GamificacaoRepositoryFalso(banco).conquistas();
      final calendario = await CalendarioRepositoryFalso(banco)
          .listarPeriodo(inicio: inicioDoMes, fim: fimDoMes);

      expect(disciplinas.isSuccess, isTrue);
      expect(disciplinas.valueOrNull, isEmpty);
      expect(tarefas.valueOrNull, isEmpty);
      expect(avisos.valueOrNull, isEmpty);
      expect(conquistas.valueOrNull, isEmpty);
      expect(calendario.valueOrNull, isEmpty);
    });

    test('a Home ainda mostra os números de gamificação', () async {
      // É o que permite ver o cartão de nível junto do estado vazio.
      final banco = _banco(Cenario.vazio);
      final dashboard = await DashboardRepositoryFalso(banco).carregar();

      final dados = dashboard.valueOrNull!;
      expect(dados.gamificacao.nivel, greaterThan(0));
      expect(dados.totalAbertas, 0);
    });
  });

  group('cenário erro', () {
    test('toda leitura devolve NetworkFailure retentável', () async {
      final banco = _banco(Cenario.erro);

      final resultados = <Result<Object?>>[
        await DisciplinaRepositoryFalso(banco).listar(),
        await TarefaRepositoryFalso(banco).listar(),
        await AvisoRepositoryFalso(banco).listar(),
        await DashboardRepositoryFalso(banco).carregar(),
        await GamificacaoRepositoryFalso(banco).progresso(),
        await KaiRepositoryFalso(banco).enviar('oi'),
      ];

      for (final resultado in resultados) {
        final falha = resultado.failureOrNull;
        expect(falha, isA<NetworkFailure>());
        expect(falha!.kind, FailureKind.rede);
        // A UI só oferece "Tentar novamente" para falha retentável.
        expect(falha.isRetryable, isTrue);
      }
    });
  });

  group('DashboardRepositoryFalso', () {
    test('agrupa as tarefas por prazo', () async {
      final banco = _banco(Cenario.cheio);
      final dashboard = (await DashboardRepositoryFalso(
        banco,
      ).carregar()).valueOrNull!;

      expect(dashboard.tarefasHoje, hasLength(2));
      expect(dashboard.tarefasAmanha, hasLength(2));
      expect(dashboard.tarefasAtrasadas, hasLength(2));
    });

    test('leva a gamificação do seed para o resumo da Home', () async {
      final banco = _banco(Cenario.cheio);
      final dashboard = (await DashboardRepositoryFalso(
        banco,
      ).carregar()).valueOrNull!;

      // O anel do "foguinho" depende de `minutosHoje`, então o dublê precisa
      // entregá-lo — ou a Home mostraria a meta zerada sem o backend.
      expect(dashboard.gamificacao.minutosHoje, 7);
      expect(dashboard.gamificacao.sequenciaDias, 7);
      expect(dashboard.gamificacao.nivel, 4);
      expect(dashboard.gamificacao.tituloNivel, 'Curioso');
      expect(dashboard.totalConquistas, 3);
    });

    test('reflete tarefa concluída entre chamadas', () async {
      // É o contrato que faz a Home atualizar ao riscar uma tarefa.
      final banco = _banco(Cenario.cheio);
      final tarefas = TarefaRepositoryFalso(banco);
      final dashboardRepo = DashboardRepositoryFalso(banco);

      final antes = (await dashboardRepo.carregar()).valueOrNull!;
      final abertasAntes = antes.totalAbertas;
      expect(abertasAntes, greaterThan(0));

      final riscada = await tarefas.alternarConclusao(1);
      expect(riscada.valueOrNull?.concluida, isTrue);
      expect(riscada.valueOrNull?.xpConquistado, 20);

      final depois = (await dashboardRepo.carregar()).valueOrNull!;
      expect(depois.totalAbertas, abertasAntes - 1);
      expect(depois.tarefasHoje, hasLength(antes.tarefasHoje.length - 1));

      // Desmarcar devolve ao estado anterior.
      await tarefas.alternarConclusao(1);
      final revertido = (await dashboardRepo.carregar()).valueOrNull!;
      expect(revertido.totalAbertas, abertasAntes);
    });
  });

  group('TarefaRepositoryFalso', () {
    test('filtra por situação', () async {
      final repo = TarefaRepositoryFalso(_banco(Cenario.cheio));

      final pendentes = await repo.listar(status: StatusTarefa.pendente);
      final concluidas = await repo.listar(status: StatusTarefa.concluida);

      expect(pendentes.valueOrNull, hasLength(8));
      expect(concluidas.valueOrNull, hasLength(2));
    });

    test('criar e excluir alteram a lista', () async {
      final repo = TarefaRepositoryFalso(_banco(Cenario.cheio));

      final criada = await repo.criar(
        titulo: 'Tarefa nova',
        prazo: agora,
        disciplinaId: 1,
      );
      expect(criada.valueOrNull?.disciplinaNome, 'Matemática');
      expect((await repo.listar()).valueOrNull, hasLength(11));

      await repo.excluir(criada.valueOrNull!.id);
      expect((await repo.listar()).valueOrNull, hasLength(10));
    });

    test('busca id inexistente devolve not found', () async {
      final repo = TarefaRepositoryFalso(_banco(Cenario.cheio));
      final resultado = await repo.buscar(9999);

      expect(resultado.failureOrNull?.kind, FailureKind.naoEncontrado);
    });
  });

  group('CalendarioRepositoryFalso', () {
    test('respeita o intervalo pedido', () async {
      final repo = CalendarioRepositoryFalso(_banco(Cenario.cheio));

      final noMes = await repo.listarPeriodo(
        inicio: inicioDoMes,
        fim: fimDoMes,
      );
      final emOutroMes = await repo.listarPeriodo(
        inicio: DateTime(agora.year, agora.month + 2, 1),
        fim: DateTime(agora.year, agora.month + 2, 28),
      );

      expect(noMes.valueOrNull, isNotEmpty);
      expect(emOutroMes.valueOrNull, isEmpty);
    });

    test('os eventos caem no mês corrente', () async {
      // Senão o calendário abriria sem nenhum marcador.
      final repo = CalendarioRepositoryFalso(_banco(Cenario.cheio));
      final resultado = await repo.listarPeriodo(
        inicio: inicioDoMes,
        fim: fimDoMes,
      );

      expect(
        resultado.valueOrNull!.every(
          (EventoCalendario e) =>
              e.dia.month == agora.month &&
              e.dia.year == agora.year &&
              e.dia.hour == 0,
        ),
        isTrue,
      );
    });
  });

  group('KaiRepositoryFalso', () {
    test('responde conforme a palavra-chave', () async {
      final repo = KaiRepositoryFalso(_banco(Cenario.cheio));

      final roteiro = await repo.enviar('Monte um roteiro de estudos');
      final pendencias = await repo.enviar('Minhas pendências?');
      final livre = await repo.enviar('bom dia');

      expect(roteiro.valueOrNull!.texto, contains('30 min'));
      expect(pendencias.valueOrNull!.texto, contains('duas tarefas'));
      expect(livre.valueOrNull!.texto, contains('modo de desenvolvimento'));
    });

    test('avisa indisponibilidade no cenário de erro', () async {
      final repo = KaiRepositoryFalso(_banco(Cenario.erro));
      final resultado = await repo.disponivel();

      expect(resultado.valueOrNull, isFalse);
    });
  });

  group('cenário do ambiente', () {
    test('cai em cheio quando a variável não é reconhecida', () {
      // String.fromEnvironment é resolvido em tempo de compilação; aqui
      // verificamos o fallback do parser, que é o que roda sem --dart-define.
      expect(cenarioDoAmbiente(), Cenario.cheio);
    });
  });
}
