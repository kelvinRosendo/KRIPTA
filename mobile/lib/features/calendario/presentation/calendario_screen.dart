/// Calendário mensal com eventos, prazos e provas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/entities.dart';
import '../../tarefas/application/listas_controller.dart';

/// Tela de calendário.
///
/// A grade é construída localmente a partir do mês exibido; só os eventos
/// vêm do servidor. Trocar de mês troca a chave da família
/// [calendarioProvider], o que dispara uma nova carga sem invalidar o mês
/// anterior.
class CalendarioScreen extends ConsumerStatefulWidget {
  /// Cria a tela de calendário.
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  /// Mês exibido, sempre no primeiro dia para casar com [chaveMes].
  DateTime _mes = mesCorrente();

  /// Dia selecionado, para o painel de eventos do dia.
  DateTime _diaSelecionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final chave = chaveMes(_mes);
    final eventos = ref.watch(calendarioProvider(chave));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda', style: AppTypography.screenTitle),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: Column(
            children: <Widget>[
              _NavegacaoMes(
                mes: _mes,
                aoAnterior: () => setState(
                  () => _mes = _mes.subtract(const Duration(days: 30)),
                ),
                aoProximo: () =>
                    setState(() => _mes = _mes.add(const Duration(days: 30))),
                aoHoje: () => setState(() {
                  _mes = mesCorrente();
                  _diaSelecionado = DateTime.now();
                }),
              ),
              Expanded(
                child: switch (eventos) {
                  AsyncError<List<EventoCalendario>>(:final error) => ErroView(
                    falha: error is Failure
                        ? error
                        : const UnexpectedFailure(
                            message: 'Falha ao carregar a agenda.',
                          ),
                    aoTentarNovamente: () =>
                        ref.invalidate(calendarioProvider(chave)),
                  ),
                  AsyncData<List<EventoCalendario>>(:final value) => _Corpo(
                    mes: _mes,
                    diaSelecionado: _diaSelecionado,
                    eventos: value,
                    aoSelecionarDia: (DateTime dia) =>
                        setState(() => _diaSelecionado = dia),
                  ),
                  _ => const CarregandoView(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho com o mês e os botões de navegação.
class _NavegacaoMes extends StatelessWidget {
  /// Cria o cabeçalho.
  const _NavegacaoMes({
    required this.mes,
    required this.aoAnterior,
    required this.aoProximo,
    required this.aoHoje,
  });

  /// Mês exibido.
  final DateTime mes;

  /// Vai ao mês anterior.
  final VoidCallback aoAnterior;

  /// Vai ao próximo mês.
  final VoidCallback aoProximo;

  /// Volta ao mês atual.
  final VoidCallback aoHoje;

  static const List<String> _meses = <String>[
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Mês anterior',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: aoAnterior,
          ),
          Expanded(
            child: Text(
              '${_meses[mes.month - 1]} ${mes.year}',
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle,
            ),
          ),
          TextButton(
            onPressed: aoHoje,
            child: const Text('Hoje', style: AppTypography.pill),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: aoProximo,
          ),
        ],
      ),
    );
  }
}

/// Grade do mês mais o painel do dia selecionado.
class _Corpo extends StatelessWidget {
  /// Cria o corpo.
  const _Corpo({
    required this.mes,
    required this.diaSelecionado,
    required this.eventos,
    required this.aoSelecionarDia,
  });

  /// Mês exibido.
  final DateTime mes;

  /// Dia selecionado.
  final DateTime diaSelecionado;

  /// Eventos do período carregado (inclui dias vizinhos).
  final List<EventoCalendario> eventos;

  /// Notifica a seleção de dia.
  final ValueChanged<DateTime> aoSelecionarDia;

  @override
  Widget build(BuildContext context) {
    final porDia = <DateTime, List<EventoCalendario>>{};
    for (final evento in eventos) {
      final dia = DateTime(evento.dia.year, evento.dia.month, evento.dia.day);
      porDia.putIfAbsent(dia, () => <EventoCalendario>[]).add(evento);
    }

    final dias = _diasDaGrade(mes);
    final hoje = DateTime.now();
    final hojeDia = DateTime(hoje.year, hoje.month, hoje.day);
    final selecionado = DateTime(
      diaSelecionado.year,
      diaSelecionado.month,
      diaSelecionado.day,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.lg,
      ),
      children: <Widget>[
        _Grade(
          mes: mes,
          dias: dias,
          porDia: porDia,
          hoje: hojeDia,
          selecionado: selecionado,
          aoSelecionarDia: aoSelecionarDia,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(_rotuloDia(selecionado), style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.xs),
        if (porDia[selecionado]
            case final List<EventoCalendario> doDia?) ...<Widget>[
          for (final EventoCalendario evento in doDia) ...<Widget>[
            _CardEvento(evento: evento),
            const SizedBox(height: AppSpacing.listGap),
          ],
        ] else
          const VazioView(
            titulo: 'Dia livre',
            subtitulo: 'Nenhum evento ou prazo nesta data.',
            icone: Icons.event_available_rounded,
          ),
      ],
    );
  }

  /// Os 42 dias da grade: 6 semanas começando no domingo anterior.
  ///
  /// Sempre 42 células (não 35) porque nenhum mês tem só 5 semanas de
  /// calendário com segunda semana cheia; cortar em 35 esconderia a
  /// última linha em meses como fevereiro em ano bissexto.
  static List<DateTime> _diasDaGrade(DateTime mes) {
    final primeiro = DateTime(mes.year, mes.month, 1);
    // `weekday` começa em segunda (1); a grade começa no domingo (7).
    final inicio = primeiro.subtract(Duration(days: primeiro.weekday % 7));

    return List<DateTime>.generate(
      42,
      (int i) => DateTime(inicio.year, inicio.month, inicio.day + i),
      growable: false,
    );
  }

  /// Rótulo do dia selecionado.
  static String _rotuloDia(DateTime dia) {
    const dias = <String>[
      'SEGUNDA',
      'TERÇA',
      'QUARTA',
      'QUINTA',
      'SEXTA',
      'SÁBADO',
      'DOMINGO',
    ];
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ehHoje = dia == hoje;

    return '${dias[dia.weekday - 1]} · ${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}${ehHoje ? ' · HOJE' : ''}';
  }
}

/// Grade mensal de seis semanas.
class _Grade extends StatelessWidget {
  /// Cria a grade.
  const _Grade({
    required this.mes,
    required this.dias,
    required this.porDia,
    required this.hoje,
    required this.selecionado,
    required this.aoSelecionarDia,
  });

  /// Mês em foco, para esmaecer os dias vizinhos.
  final DateTime mes;

  /// Os 42 dias.
  final List<DateTime> dias;

  /// Eventos indexados por dia.
  final Map<DateTime, List<EventoCalendario>> porDia;

  /// Dia de hoje.
  final DateTime hoje;

  /// Dia selecionado.
  final DateTime selecionado;

  /// Notifica a seleção.
  final ValueChanged<DateTime> aoSelecionarDia;

  static const List<String> _dow = <String>['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                for (final String d in _dow)
                  Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: AppTypography.statLabel,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (int semana = 0; semana < 6; semana++)
            Row(
              children: <Widget>[
                for (int coluna = 0; coluna < 7; coluna++)
                  Expanded(
                    child: _Celula(
                      dia: dias[semana * 7 + coluna],
                      mesEmFoco: mes,
                      porDia: porDia,
                      hoje: hoje,
                      selecionado: selecionado,
                      aoSelecionarDia: aoSelecionarDia,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Uma célula do calendário.
class _Celula extends StatelessWidget {
  /// Cria a célula.
  const _Celula({
    required this.dia,
    required this.mesEmFoco,
    required this.porDia,
    required this.hoje,
    required this.selecionado,
    required this.aoSelecionarDia,
  });

  /// Dia exibido.
  final DateTime dia;

  /// Mês em foco na grade (primeiro dia do mês exibido).
  ///
  /// A grade sempre tem 42 células, então nas pontas aparecem dias do mês
  /// anterior/seguinte. Eles ficam esmaecidos mas selecionáveis: é assim
  /// que se navega de 31 de janeiro para 1 de fevereiro sem trocar de aba.
  final DateTime mesEmFoco;

  /// Eventos indexados por dia.
  final Map<DateTime, List<EventoCalendario>> porDia;

  /// Dia de hoje.
  final DateTime hoje;

  /// Dia selecionado.
  final DateTime selecionado;

  /// Notifica a seleção.
  final ValueChanged<DateTime> aoSelecionarDia;

  @override
  Widget build(BuildContext context) {
    final chave = DateTime(dia.year, dia.month, dia.day);
    final eventos = porDia[chave] ?? const <EventoCalendario>[];
    final ehSelecionado = chave == selecionado;
    final ehHoje = chave == hoje;
    final foraDoMes =
        dia.month != mesEmFoco.month || dia.year != mesEmFoco.year;

    return InkWell(
      onTap: () => aoSelecionarDia(dia),
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: ehSelecionado ? AppColors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: ehHoje && !ehSelecionado
              ? Border.all(color: AppColors.indigo, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '${dia.day}',
              style: AppTypography.itemMeta.copyWith(
                fontWeight: FontWeight.w600,
                color: ehSelecionado
                    ? Colors.white
                    : foraDoMes
                    ? AppColors.textLow
                    : AppColors.textHigh,
              ),
            ),
            const SizedBox(height: 3),
            // Até 3 marcadores; mais que isso viria um "+".
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final EventoCalendario e in eventos.take(3))
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: ehSelecionado ? Colors.white : corTipo(e.tipo),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Cor do marcador conforme o tipo do evento.
  static Color corTipo(TipoEvento tipo) => switch (tipo) {
    TipoEvento.tarefa => AppColors.indigo,
    TipoEvento.prova => AppColors.crimson,
    TipoEvento.evento => AppColors.teal,
  };
}

/// Card de um evento do dia selecionado.
class _CardEvento extends StatelessWidget {
  /// Cria o card.
  const _CardEvento({required this.evento});

  /// Evento exibido.
  final EventoCalendario evento;

  @override
  Widget build(BuildContext context) {
    final cor = _Celula.corTipo(evento.tipo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(evento.titulo, style: AppTypography.itemTitle),
                const SizedBox(height: 2),
                Text(evento.tipo.rotulo, style: AppTypography.itemMeta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
