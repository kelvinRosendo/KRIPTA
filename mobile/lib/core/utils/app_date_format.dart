/// Formatação e comparação de datas em pt-BR.
///
/// O mobile exibe os mesmos rótulos do web (`formatDate`, `formatDateTime`
/// e `timeAgo` em `services/dashboard.js`), com timezone local — o
/// usuário precisa ler o prazo no fuso dele, não no do servidor.
///
/// Observação de contrato: o backend guarda `Instant`/ISO-8601 com sufixo
/// `Z` (ver `RegisterRequest`/`DevShiftDate` do frontend). Todas as
/// conversões usam `toLocal()` antes de formatar.
///
/// ## Inicialização obrigatória
///
/// O `intl` só formata nomes de mês e dia da semana depois de carregar os
/// símbolos daquele locale. Sem [AppDateFormat.inicializar] rodando, o
/// primeiro `DateFormat('EEE', 'pt_BR')` estoura `LocaleDataException`
/// dentro de um `build` — que é como o bug chegou ao usuário, derrubando a
/// tela inteira da Home. Por isso todo entrypoint faz
/// `await AppDateFormat.inicializar();` antes do `runApp`.
library;

import 'dart:ui' show Locale;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Formatação de datas do KRIPTA.
abstract final class AppDateFormat {
  /// Locale do app. O TCC é de São Paulo/SP, então o padrão é pt-BR.
  static const String locale = 'pt_BR';

  /// O mesmo locale como [Locale], para o `MaterialApp`.
  ///
  /// Fica aqui para que o app inteiro tenha uma única fonte de verdade: se
  /// um dia o app passar a oferecer outro idioma, muda-se só esta linha e
  /// o `intl` acompanha.
  static const Locale localePtBr = Locale('pt', 'BR');

  /// Inicialização em andamento, para tolerar chamadas concorrentes.
  static Future<void>? _inicializacao;

  /// Carrega os símbolos de data do locale. Idempotente.
  ///
  /// Chame uma vez, no entrypoint, antes de `runApp`:
  ///
  /// ```dart
  /// void main() async {
  ///   await AppDateFormat.inicializar();
  ///   runApp(const KriptaApp());
  /// }
  /// ```
  static Future<void> inicializar() =>
      _inicializacao ??= initializeDateFormatting(locale, null);

  /// Falha cedo e com instrução, em vez de deixar o `intl` estourar.
  static void _exigirInicializado() {
    if (_inicializacao == null) {
      throw StateError(
        'AppDateFormat.inicializar() não foi chamado. Rode '
        '`await AppDateFormat.inicializar();` antes de `runApp()` no '
        'entrypoint (main.dart e main_debug.dart).',
      );
    }
  }

  /// Cria e memoiza um [DateFormat] do locale do app.
  static DateFormat _formatado(String padrao) {
    final existente = _cache[padrao];
    if (existente != null) return existente;
    _exigirInicializado();
    return _cache[padrao] = DateFormat(padrao, locale);
  }

  /// Cache dos [DateFormat] — construí-los é caro e formatamos muito
  /// durante a construção de listas.
  static final Map<String, DateFormat> _cache = <String, DateFormat>{};

  /// `dd/MM` — listas de tarefas e calendário.
  static DateFormat get _dayMonth => _formatado('dd/MM');

  /// `dd/MM 'de' yyyy` — quando o ano importa.
  static DateFormat get _dayMonthYear => _formatado("dd/MM 'de' yyyy");

  /// `dd/MM, HH:mm` — prazos com hora.
  static DateFormat get _dayMonthTime => _formatado('dd/MM, HH:mm');

  /// Data por extenso, para a saudação da Home.
  static DateFormat get _fullDate => _formatado("EEEE, d 'de' MMMM 'de' yyyy");

  /// Dia da semana abreviado (`seg`, `ter`...).
  static DateFormat get _weekdayShort => _formatado('EEE');

  /// Mês e ano, para o cabeçalho do calendário.
  static DateFormat get _monthYear => _formatado('MMMM yyyy');

  /// `dd/MM` — usado nas listas de tarefas e no calendário.
  static String shortDate(DateTime date) => _dayMonth.format(date.toLocal());

  /// `dd/MM 'de' yyyy` — usado quando o ano importa.
  static String mediumDate(DateTime date) =>
      _dayMonthYear.format(date.toLocal());

  /// `dd/MM, HH:mm` — usado em prazos com hora.
  static String dateTime(DateTime date) => _dayMonthTime.format(date.toLocal());

  /// Data por extenso, para a saudação da Home.
  static String fullDate(DateTime date) =>
      _capitalize(_fullDate.format(date.toLocal()));

  /// Dia da semana abreviado (`seg`, `ter`...).
  static String weekdayShort(DateTime date) =>
      _weekdayShort.format(date.toLocal());

  /// Mês e ano, para o cabeçalho do calendário.
  static String monthYear(DateTime date) =>
      _capitalize(_monthYear.format(date.toLocal()));

  /// `ISO-8601` em UTC, formato aceito pelo backend.
  ///
  /// O Spring Boot desserializa para `Instant`, que exige offset; por isso
  /// `toUtc().toIso8601String()` e nunca o `toIso8601String()` cru.
  static String toApi(DateTime date) => date.toUtc().toIso8601String();

  /// `yyyy-MM-dd`, o formato de query usado em `/calendario`.
  static String toApiDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// Converte string ISO em [DateTime] local, tolerando formatos inválidos.
  ///
  /// O backend pode devolver `2026-09-28T12:00:00Z` (com `Z`), o Java
  /// padrão `2026-09-28T12:00:00` (sem offset) ou apenas `2026-09-28`
  /// (data pura, usada por `/calendario`). Todos são aceitos.
  static DateTime? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  /// Diferença em dias inteiros entre [date] e hoje, ignorando a hora.
  ///
  /// Negativo = atrasado, `0` = hoje, `1` = amanhã. É a mesma conta que
  /// `devDayDiff` faz no frontend web, para os rótulos "hoje" / "amanhã" /
  /// "atrasada" baterem entre as plataformas.
  static int daysFromToday(DateTime date, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = date.toLocal();
    final targetDay = DateTime(target.year, target.month, target.day);
    return targetDay.difference(today).inDays;
  }

  /// Tempo decorrido em linguagem natural (`agora`, `há 5min`, `ontem`).
  ///
  /// Espelha `timeAgo` de `services/announcements.js`.
  static String timeAgo(DateTime date, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final diff = now.difference(date.toLocal());

    if (diff.isNegative) return dateTime(date);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return shortDate(date);
  }

  /// Saudação conforme o horário local (usada na Home).
  static String greeting({DateTime? reference}) {
    final hour = (reference ?? DateTime.now()).hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// Primeiro dia do mês de [date].
  static DateTime firstDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// Último dia do mês de [date].
  static DateTime lastDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  /// Nome do mês em maiúsculas, como no calendário do web (`SET`).
  ///
  /// Corta o nome inteiro em três letras em vez de usar o padrão `MMM` do
  /// `intl`, que em pt-BR devolve `set.` — com ponto, e o cabeçalho do
  /// calendário ficaria `SET.`.
  static String monthShortUpper(DateTime date) {
    final nome = _monthYear.format(date.toLocal()).split(' ').first;
    return nome.substring(0, 3).toUpperCase();
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
