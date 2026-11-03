/// Formatação de números em pt-BR.
///
/// Só o separador de milhar, com o ponto: o protótipo web escreve `1.240`
/// e `12.500` nos cards de XP (`stat` em `screen-home`), e um `1240` cru no
/// Flutter destoa do lado a lado com o resto da interface.
///
/// Deliberadamente **não** usa `initializeNumberFormatting`: ao contrário
/// dos símbolos de data, os de número já vêm no pacote `intl`, então esta
/// classe funciona sem nenhum passo de inicialização no entrypoint.
library;

import 'package:intl/intl.dart' show NumberFormat;

/// Formatação numérica do KRIPTA.
abstract final class AppNumberFormat {
  /// Separador de milhar pt-BR. Criado uma vez: `NumberFormat` é caro de
  /// construir e o `build` das listas o chamaria a cada quadro.
  static final NumberFormat _milhar = NumberFormat.decimalPattern('pt_BR');

  /// `1240` vira `1.240`.
  static String milhar(int valor) => _milhar.format(valor);

  /// `1240` vira `1,2 mil`, para espaços estreitos como a grade de insígnias.
  static String compacto(int valor) {
    if (valor < 1000) return '$valor';
    final double milhares = valor / 1000;
    // Uma casa decimal só quando ela muda o número: 1,2 mil e não 1,0 mil.
    final int casas = milhares >= 10 ? 0 : 1;
    // `toStringAsFixed` escreve `1.2` com ponto; em pt-BR a vírgula é o
    // separador decimal, então troca aqui em vez de confiar nele.
    return '${milhares.toStringAsFixed(casas).replaceAll('.', ',')} mil';
  }
}
