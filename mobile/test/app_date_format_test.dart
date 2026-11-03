/// Regressão do crash que derrubava a Home inteira.
///
/// Sem `AppDateFormat.inicializar()` rodando, o `intl` lança
/// `LocaleDataException` no primeiro `DateFormat` em pt-BR — e como a
/// saudação da Home é o primeiro sliver do `CustomScrollView`, a exceção
/// subia e matava a tela inteira, gamificação junto.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kripta_mobile/core/utils/app_date_format.dart';

void main() {
  // Precisa ser o primeiro teste do arquivo: `package:test` roda na ordem de
  // declaração e o estado é estático, então só dá para observar o estado
  // "não inicializado" antes do `setUpAll` do grupo abaixo rodar. Cada
  // arquivo de teste roda no seu próprio isolate, então os 30 testes dos
  // outros arquivos não interferem.
  test('formatar antes de inicializar lança erro que diz o que fazer', () {
    expect(
      () => AppDateFormat.shortDate(DateTime(2026, 9, 28)),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          allOf(contains('inicializar()'), contains('main_debug.dart')),
        ),
      ),
    );
  });

  group('após inicializar', () {
    setUpAll(AppDateFormat.inicializar);

    test('formata data curta em dd/MM', () {
      expect(AppDateFormat.shortDate(DateTime(2026, 9, 28)), '28/09');
    });

    test('formata data com ano', () {
      expect(AppDateFormat.mediumDate(DateTime(2026, 9, 28)), '28/09 de 2026');
    });

    test('formata data com hora', () {
      expect(
        AppDateFormat.dateTime(DateTime(2026, 9, 28, 23, 59)),
        '28/09, 23:59',
      );
    });

    test('formata dia da semana abreviado em pt-BR', () {
      // 28/09/2026 é uma segunda-feira. O intl escreve o ponto de
      // abreviação, como manda o português.
      expect(AppDateFormat.weekdayShort(DateTime(2026, 9, 28)), 'seg.');
    });

    test('data por extenso usa o mês em português', () {
      expect(
        AppDateFormat.fullDate(DateTime(2026, 9, 28)),
        contains('setembro'),
      );
    });

    test('mês e ano saem capitalizados', () {
      expect(AppDateFormat.monthYear(DateTime(2026, 9, 1)), 'Setembro 2026');
    });

    test('mês abreviado em caixa alta para o calendário', () {
      expect(AppDateFormat.monthShortUpper(DateTime(2026, 9, 1)), 'SET');
    });

    test('inicializar é idempotente', () async {
      // O entrypoint chama uma vez, mas testes e hot restart podem chamar de
      // novo; não pode estourar nem recarregar os símbolos.
      await AppDateFormat.inicializar();
      expect(AppDateFormat.shortDate(DateTime(2026, 9, 28)), '28/09');
    });
  });

  group('dias relativos', () {
    setUpAll(AppDateFormat.inicializar);

    final referencia = DateTime(2026, 9, 28, 12);

    test('classifica hoje, amanhã e atrasada', () {
      expect(
        AppDateFormat.daysFromToday(
          DateTime(2026, 9, 28, 23),
          reference: referencia,
        ),
        0,
      );
      expect(
        AppDateFormat.daysFromToday(
          DateTime(2026, 9, 29, 8),
          reference: referencia,
        ),
        1,
      );
      expect(
        AppDateFormat.daysFromToday(
          DateTime(2026, 9, 26, 8),
          reference: referencia,
        ),
        -2,
      );
    });

    test('timeAgo escreve em português', () {
      expect(
        AppDateFormat.timeAgo(
          referencia.subtract(const Duration(minutes: 5)),
          reference: referencia,
        ),
        'há 5min',
      );
      expect(AppDateFormat.timeAgo(referencia, reference: referencia), 'agora');
    });
  });
}
