/// Dublês em memória dos repositories, para rodar o app sem backend.
///
/// Cada dublê implementa o contrato de `domain/repositories` e lê de um
/// [Exemplo] compartilhado. Como o estado é único e mutável, marcar uma
/// tarefa como concluída e navegar entre telas mantém a alteração — que é
/// justamente o que se quer ao explorar a interface.
///
/// A [BancoFalso] é a "fonte de verdade" do modo de desenvolvimento: os
/// dublês de dashboard e de tarefas leem a *mesma* lista, então concluir
/// uma tarefa na aba Tarefas também reduz o contador da Home.
library;

import '../core/error/failure.dart';
import '../core/utils/result.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/repositories.dart';
import 'dados_de_exemplo.dart';

/// Atraso simulado de rede, para os estados de carregamento aparecerem.
///
/// Sem ele, `Future.value` resolveria antes do primeiro `build` e o
/// spinner nunca seria pintado — impossível conferir a UI de carregamento.
const Duration atrasoLeitura = Duration(milliseconds: 300);

/// Atraso maior para o Kai, para o "digitando…" ficar visível.
const Duration atrasoKai = Duration(milliseconds: 900);

Future<T> _atraso<T>(T valor, {Duration atraso = atrasoLeitura}) async {
  await Future<void>.delayed(atraso);
  return valor;
}

Result<T> _semRede<T>() => FailureResult<T>(
  const NetworkFailure(
    message: 'Sem conexão com o servidor (modo de desenvolvimento).',
  ),
);

Result<T> _naoEncontrado<T>(String oQue) => FailureResult<T>(
  NotFoundFailure(message: '$oQue não encontrado (modo de desenvolvimento).'),
);

DateTime _diaDe(DateTime data) => DateTime(data.year, data.month, data.day);

/// Estado compartilhado pelos dublês.
class BancoFalso {
  /// Cria o banco com o seed gerado a partir de [agora].
  ///
  /// [cenario] existe para os testes exercitarem os três comportamentos; em
  /// produção ele vem de `--dart-define` e não pode ser mudado em runtime.
  BancoFalso({DateTime? agora, Cenario? cenario})
    : cenario = cenario ?? cenarioDoAmbiente(),
      seed = Exemplo.gerar(agora: agora);

  /// Cenário selecionado por `--dart-define=CE_NARIO`.
  final Cenario cenario;

  /// Dados de exemplo, compartilhados e mutáveis.
  final Exemplo seed;

  /// `true` quando o cenário pede listas vazias.
  bool get vazio => cenario == Cenario.vazio;

  /// `true` quando o cenário pede falha de rede.
  bool get semRede => cenario == Cenario.erro;
}

/// Dublê de [AuthRepository].
///
/// **Autentica sempre, em qualquer cenário** — inclusive em
/// [Cenario.erro]. Não é um detalhe: [AuthController.restaurarSessao]
/// transforma uma falha de `usuarioAtual` em sessão anônima, e o
/// [go_router] mandaria para o login. O cenário de erro existe para
/// exercitar `ErroView` **dentro do app**, não o formulário de entrada.
///
/// [sair] desliga a sessão de verdade, para dar para testar o logout e o
/// login subsequente (que aceita qualquer credencial).
class AuthRepositoryFalso implements AuthRepository {
  /// Cria o dublê sobre [banco].
  AuthRepositoryFalso(BancoFalso banco) : _usuario = banco.seed.usuario;

  Usuario _usuario;
  bool _autenticado = true;

  @override
  Future<Result<Usuario>> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required PerfilUsuario perfil,
  }) async {
    _usuario = _usuario.copyWith(nome: nome, email: email, perfil: perfil);
    _autenticado = true;
    return _atraso(Success<Usuario>(_usuario));
  }

  @override
  Future<Result<Usuario>> entrar({
    required String email,
    required String senha,
  }) async {
    _usuario = _usuario.copyWith(email: email);
    _autenticado = true;
    return _atraso(Success<Usuario>(_usuario));
  }

  @override
  Future<Result<Usuario>> usuarioAtual() => _atraso(Success<Usuario>(_usuario));

  @override
  Future<Result<Usuario>> atualizarPerfil({
    required String nome,
    required String email,
  }) async {
    _usuario = _usuario.copyWith(nome: nome, email: email);
    return _atraso(Success<Usuario>(_usuario));
  }

  @override
  Future<Result<void>> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async => _atraso(const Success<void>(null), atraso: const Duration());

  @override
  Future<void> sair() async {
    _autenticado = false;
  }

  @override
  Future<bool> temSessaoAtiva() async => _autenticado;
}

/// Dublê de [DisciplinaRepository].
class DisciplinaRepositoryFalso implements DisciplinaRepository {
  /// Cria o dublê sobre [banco].
  DisciplinaRepositoryFalso(this._banco);

  final BancoFalso _banco;
  int _proximoId = 900;

  @override
  Future<Result<List<Disciplina>>> listar() async {
    if (_banco.semRede) return _semRede();
    return _atraso(
      Success<List<Disciplina>>(
        _banco.vazio
            ? const <Disciplina>[]
            : List<Disciplina>.of(_banco.seed.disciplinas),
      ),
    );
  }

  @override
  Future<Result<Disciplina>> buscar(int id) async {
    if (_banco.semRede) return _semRede();
    if (_banco.vazio) return _naoEncontrado<Disciplina>('Disciplina');
    for (final d in _banco.seed.disciplinas) {
      if (d.id == id) return _atraso(Success<Disciplina>(d));
    }
    return _naoEncontrado<Disciplina>('Disciplina');
  }

  @override
  Future<Result<Disciplina>> criar({
    required String nome,
    required String cor,
  }) async {
    if (_banco.semRede) return _semRede();
    final disciplina = Disciplina(
      id: _proximoId++,
      nome: nome,
      cor: cor,
      pendencias: 0,
    );
    _banco.seed.disciplinas.add(disciplina);
    return _atraso(Success<Disciplina>(disciplina));
  }

  @override
  Future<Result<Disciplina>> atualizar({
    required int id,
    required String nome,
    required String cor,
  }) async {
    if (_banco.semRede) return _semRede();
    final indice = _banco.seed.disciplinas.indexWhere(
      (Disciplina d) => d.id == id,
    );
    if (indice < 0) return _naoEncontrado<Disciplina>('Disciplina');
    final atualizada = _banco.seed.disciplinas[indice].copyWith(
      nome: nome,
      cor: cor,
    );
    _banco.seed.disciplinas[indice] = atualizada;
    return _atraso(Success<Disciplina>(atualizada));
  }

  @override
  Future<Result<void>> excluir(int id) async {
    if (_banco.semRede) return _semRede();
    _banco.seed.disciplinas.removeWhere((Disciplina d) => d.id == id);
    return _atraso(const Success<void>(null), atraso: const Duration());
  }
}

/// Dublê de [UnidadeRepository].
class UnidadeRepositoryFalso implements UnidadeRepository {
  /// Cria o dublê sobre [banco].
  UnidadeRepositoryFalso(this._banco);

  final BancoFalso _banco;
  int _proximoId = 900;

  @override
  Future<Result<List<Unidade>>> listar(int disciplinaId) async {
    if (_banco.semRede) return _semRede();
    return _atraso(
      Success<List<Unidade>>(
        _banco.vazio
            ? const <Unidade>[]
            : List<Unidade>.of(
                _banco.seed.unidadesPorDisciplina[disciplinaId] ??
                    const <Unidade>[],
              ),
      ),
    );
  }

  @override
  Future<Result<Unidade>> criar({
    required int disciplinaId,
    required String nome,
    String? descricao,
  }) async {
    if (_banco.semRede) return _semRede();
    final unidade = Unidade(
      id: _proximoId++,
      disciplinaId: disciplinaId,
      nome: nome,
      descricao: descricao,
    );
    _banco.seed.unidadesPorDisciplina
        .putIfAbsent(disciplinaId, () => <Unidade>[])
        .add(unidade);
    return _atraso(Success<Unidade>(unidade));
  }

  @override
  Future<Result<Unidade>> atualizar({
    required int id,
    required String nome,
    String? descricao,
  }) async {
    if (_banco.semRede) return _semRede();
    for (final lista in _banco.seed.unidadesPorDisciplina.values) {
      final indice = lista.indexWhere((Unidade u) => u.id == id);
      if (indice < 0) continue;
      final atualizada = Unidade(
        id: id,
        disciplinaId: lista[indice].disciplinaId,
        nome: nome,
        descricao: descricao,
        totalMateriais: lista[indice].totalMateriais,
      );
      lista[indice] = atualizada;
      return _atraso(Success<Unidade>(atualizada));
    }
    return _naoEncontrado<Unidade>('Unidade');
  }

  @override
  Future<Result<void>> excluir(int id) async {
    if (_banco.semRede) return _semRede();
    for (final lista in _banco.seed.unidadesPorDisciplina.values) {
      lista.removeWhere((Unidade u) => u.id == id);
    }
    return _atraso(const Success<void>(null), atraso: const Duration());
  }
}

/// Dublê de [MaterialRepository].
class MaterialRepositoryFalso implements MaterialRepository {
  /// Cria o dublê sobre [banco].
  MaterialRepositoryFalso(this._banco);

  final BancoFalso _banco;
  int _proximoId = 9000;

  @override
  Future<Result<List<MaterialEstudo>>> listarPorUnidade(int unidadeId) async {
    if (_banco.semRede) return _semRede();
    return _atraso(
      Success<List<MaterialEstudo>>(
        _banco.vazio
            ? const <MaterialEstudo>[]
            : List<MaterialEstudo>.of(
                _banco.seed.materiaisPorUnidade[unidadeId] ??
                    const <MaterialEstudo>[],
              ),
      ),
    );
  }

  @override
  Future<Result<MaterialEstudo>> criar({
    required int unidadeId,
    required String titulo,
    required TipoMaterial tipo,
    String? url,
    String? descricao,
  }) async {
    if (_banco.semRede) return _semRede();
    final material = MaterialEstudo(
      id: _proximoId++,
      unidadeId: unidadeId,
      titulo: titulo,
      tipo: tipo,
      url: url,
      descricao: descricao,
    );
    _banco.seed.materiaisPorUnidade
        .putIfAbsent(unidadeId, () => <MaterialEstudo>[])
        .add(material);
    return _atraso(Success<MaterialEstudo>(material));
  }

  @override
  Future<Result<MaterialEstudo>> atualizar({
    required int id,
    required String titulo,
    required TipoMaterial tipo,
    String? url,
    String? descricao,
  }) async {
    if (_banco.semRede) return _semRede();
    final par = _localizar(id);
    if (par == null) return _naoEncontrado<MaterialEstudo>('Material');
    final (lista, indice) = par;
    final atualizado = lista[indice].copyWith(
      titulo: titulo,
      tipo: tipo,
      url: url,
      descricao: descricao,
    );
    lista[indice] = atualizado;
    return _atraso(Success<MaterialEstudo>(atualizado));
  }

  @override
  Future<Result<MaterialEstudo>> alternarConclusao(int id) async {
    if (_banco.semRede) return _semRede();
    final par = _localizar(id);
    if (par == null) return _naoEncontrado<MaterialEstudo>('Material');
    final (lista, indice) = par;
    final material = lista[indice];
    final atualizado = material.copyWith(concluido: !material.concluido);
    lista[indice] = atualizado;
    return _atraso(Success<MaterialEstudo>(atualizado));
  }

  @override
  Future<Result<void>> excluir(int id) async {
    if (_banco.semRede) return _semRede();
    final par = _localizar(id);
    if (par != null) par.$1.removeAt(par.$2);
    return _atraso(const Success<void>(null), atraso: const Duration());
  }

  /// Localiza um material em qualquer unidade, devolvendo lista e índice.
  (List<MaterialEstudo>, int)? _localizar(int id) {
    for (final lista in _banco.seed.materiaisPorUnidade.values) {
      final indice = lista.indexWhere((MaterialEstudo m) => m.id == id);
      if (indice >= 0) return (lista, indice);
    }
    return null;
  }
}

/// Dublê de [TarefaRepository].
class TarefaRepositoryFalso implements TarefaRepository {
  /// Cria o dublê sobre [banco].
  TarefaRepositoryFalso(this._banco);

  final BancoFalso _banco;
  int _proximoId = 900;

  @override
  Future<Result<List<Tarefa>>> listar({StatusTarefa? status}) async {
    if (_banco.semRede) return _semRede();
    final todas = _banco.seed.tarefas;
    final filtradas = switch (status) {
      null => todas,
      StatusTarefa.pendente => todas.where((Tarefa t) => !t.concluida).toList(),
      StatusTarefa.concluida => todas.where((Tarefa t) => t.concluida).toList(),
    };
    return _atraso(
      Success<List<Tarefa>>(
        _banco.vazio ? const <Tarefa>[] : List<Tarefa>.of(filtradas),
      ),
    );
  }

  @override
  Future<Result<Tarefa>> buscar(int id) async {
    if (_banco.semRede) return _semRede();
    if (_banco.vazio) return _naoEncontrado<Tarefa>('Tarefa');
    for (final t in _banco.seed.tarefas) {
      if (t.id == id) return _atraso(Success<Tarefa>(t));
    }
    return _naoEncontrado<Tarefa>('Tarefa');
  }

  @override
  Future<Result<Tarefa>> criar({
    required String titulo,
    String? descricao,
    DateTime? prazo,
    PrioridadeTarefa prioridade = PrioridadeTarefa.media,
    int? disciplinaId,
  }) async {
    if (_banco.semRede) return _semRede();
    final tarefa = Tarefa(
      id: _proximoId++,
      titulo: titulo,
      descricao: descricao,
      prazo: prazo,
      prioridade: prioridade,
      disciplinaId: disciplinaId,
      disciplinaNome: _nomeDaDisciplina(disciplinaId),
    );
    _banco.seed.tarefas.add(tarefa);
    return _atraso(Success<Tarefa>(tarefa));
  }

  @override
  Future<Result<Tarefa>> atualizar({
    required int id,
    required String titulo,
    String? descricao,
    DateTime? prazo,
    required PrioridadeTarefa prioridade,
    int? disciplinaId,
  }) async {
    if (_banco.semRede) return _semRede();
    final indice = _banco.seed.tarefas.indexWhere((Tarefa t) => t.id == id);
    if (indice < 0) return _naoEncontrado<Tarefa>('Tarefa');
    final atualizada = _banco.seed.tarefas[indice].copyWith(
      titulo: titulo,
      descricao: descricao,
      prazo: prazo,
      prioridade: prioridade,
      disciplinaId: disciplinaId,
      disciplinaNome: _nomeDaDisciplina(disciplinaId),
    );
    _banco.seed.tarefas[indice] = atualizada;
    return _atraso(Success<Tarefa>(atualizada));
  }

  @override
  Future<Result<Tarefa>> alternarConclusao(int id) async {
    if (_banco.semRede) return _semRede();
    final indice = _banco.seed.tarefas.indexWhere((Tarefa t) => t.id == id);
    if (indice < 0) return _naoEncontrado<Tarefa>('Tarefa');
    final atual = _banco.seed.tarefas[indice];
    // O XP só vem no `PATCH` da API real; aqui o valor é inventado, mas
    // segue a mesma regra para a animação da Home ter o que mostrar.
    final atualizada = atual.copyWith(
      concluida: !atual.concluida,
      xpConquistado: atual.concluida ? 0 : 20,
    );
    _banco.seed.tarefas[indice] = atualizada;
    return _atraso(Success<Tarefa>(atualizada));
  }

  @override
  Future<Result<void>> excluir(int id) async {
    if (_banco.semRede) return _semRede();
    _banco.seed.tarefas.removeWhere((Tarefa t) => t.id == id);
    return _atraso(const Success<void>(null), atraso: const Duration());
  }

  String? _nomeDaDisciplina(int? id) {
    if (id == null) return null;
    for (final d in _banco.seed.disciplinas) {
      if (d.id == id) return d.nome;
    }
    return null;
  }
}

/// Dublê de [CalendarioRepository].
class CalendarioRepositoryFalso implements CalendarioRepository {
  /// Cria o dublê sobre [banco].
  CalendarioRepositoryFalso(this._banco);

  final BancoFalso _banco;

  @override
  Future<Result<List<EventoCalendario>>> listarPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    if (_banco.semRede) return _semRede();
    if (_banco.vazio) {
      return _atraso(
        const Success<List<EventoCalendario>>(<EventoCalendario>[]),
      );
    }
    final eventos =
        _banco.seed.eventos.where((EventoCalendario e) {
          final dia = _diaDe(e.dia);
          return !dia.isBefore(_diaDe(inicio)) && !dia.isAfter(_diaDe(fim));
        }).toList()..sort(
          (EventoCalendario a, EventoCalendario b) => a.dia.compareTo(b.dia),
        );
    return _atraso(Success<List<EventoCalendario>>(eventos));
  }
}

/// Dublê de [AvisoRepository].
class AvisoRepositoryFalso implements AvisoRepository {
  /// Cria o dublê sobre [banco].
  AvisoRepositoryFalso(this._banco);

  final BancoFalso _banco;

  @override
  Future<Result<List<Aviso>>> listar() async {
    if (_banco.semRede) return _semRede();
    final avisos = _banco.vazio ? <Aviso>[] : List<Aviso>.of(_banco.seed.avisos)
      ..sort((Aviso a, Aviso b) => b.criadoEm.compareTo(a.criadoEm));
    return _atraso(Success<List<Aviso>>(avisos));
  }
}

/// Dublê de [GamificacaoRepository].
///
/// Nenhuma tela consome este contrato hoje — a Home usa o resumo embutido
/// no [Dashboard] — mas está implementado para o [GamificacaoRepository]
/// não ficar sem implementação caso o perfil passe a chamar.
class GamificacaoRepositoryFalso implements GamificacaoRepository {
  /// Cria o dublê sobre [banco].
  GamificacaoRepositoryFalso(this._banco);

  final BancoFalso _banco;

  @override
  Future<Result<EstatisticasGamificacao>> estatisticas() async {
    if (_banco.semRede) return _semRede();
    return _atraso(Success<EstatisticasGamificacao>(_banco.seed.estatisticas));
  }

  @override
  Future<Result<List<Conquista>>> conquistas() async {
    if (_banco.semRede) return _semRede();
    return _atraso(
      Success<List<Conquista>>(
        _banco.vazio
            ? const <Conquista>[]
            : List<Conquista>.of(_banco.seed.conquistas),
      ),
    );
  }

  @override
  Future<Result<Progresso>> progresso() async {
    if (_banco.semRede) return _semRede();
    return _atraso(Success<Progresso>(_banco.seed.progresso));
  }
}

/// Dublê de [DashboardRepository].
///
/// Recalcula as listas de tarefas a cada chamada, a partir da lista viva
/// de [BancoFalso.seed]. É o que faz a Home refletir uma tarefa concluída
/// na aba Tarefas.
class DashboardRepositoryFalso implements DashboardRepository {
  /// Cria o dublê sobre [banco].
  DashboardRepositoryFalso(this._banco);

  final BancoFalso _banco;

  @override
  Future<Result<Dashboard>> carregar() async {
    if (_banco.semRede) return _semRede();
    return _atraso(Success<Dashboard>(_dashboard));
  }

  Dashboard get _dashboard {
    final seed = _banco.seed;
    final hoje = _diaDe(DateTime.now());
    final amanha = hoje.add(const Duration(days: 1));

    List<TarefaRef> aberto(bool Function(Tarefa) teste) => seed.tarefas
        .where((Tarefa t) => !t.concluida && teste(t))
        .map(Exemplo.paraReferencia)
        .toList();

    return Dashboard(
      gamificacao: ResumoGamificacao(
        xp: seed.estatisticas.xp,
        nivel: seed.estatisticas.nivel,
        sequenciaDias: seed.sequenciaDias,
        minutosHoje: seed.minutosHoje,
      ),
      totalConquistas: seed.totalConquistas,
      // Em [Cenario.vazio] o seed existe, mas nada é listado: a Home mostra
      // o cartão de gamificação e o estado vazio de tarefas ao mesmo tempo.
      tarefasHoje: _banco.vazio
          ? const <TarefaRef>[]
          : aberto((Tarefa t) => t.venceHoje),
      tarefasAmanha: _banco.vazio
          ? const <TarefaRef>[]
          : aberto((Tarefa t) => t.prazo != null && _diaDe(t.prazo!) == amanha),
      tarefasAtrasadas: _banco.vazio
          ? const <TarefaRef>[]
          : aberto((Tarefa t) => t.atrasada),
    );
  }
}

/// Dublê de [KaiRepository].
///
/// Não há IA involved: devolve uma resposta escrita à mão conforme a
/// pergunta. Em [Cenario.erro] devolve falha, para conferir a mensagem de
/// erro no chat.
class KaiRepositoryFalso implements KaiRepository {
  /// Cria o dublê sobre [banco].
  KaiRepositoryFalso(this._banco);

  final BancoFalso _banco;

  /// Respostas por palavra-chave, comparadas em caixa baixa.
  ///
  /// As chaves são prefixos, não palavras inteiras: 'pend' casa com
  /// "pendência", "pendências" e "pendencia" sem acento.
  static const Map<String, String> _respostas = <String, String>{
    'roteiro':
        'Para hoje, sugiro:\n'
        '1. 30 min de Matemática (lista 3, questões 4 a 9);\n'
        '2. 20 min de Biologia (quadro comparativo);\n'
        '3. 15 min de leitura do capítulo 4 de História.\n'
        'São cerca de 65 minutos, o que cabe bem antes da prova.',
    'pend':
        'Você tem duas tarefas para hoje (lista 3 de Matemática e a leitura '
        'de História), duas para amanhã e duas atrasadas. '
        'Comece pela lista 3, que é a de prioridade alta.',
  };

  /// Resposta usada quando a pergunta não casa com nenhuma palavra-chave.
  static const String respostaPadrao =
      'Entendi! Em modo de desenvolvimento eu respondo com mensagens '
      'pré-escritas, mas a tela, o envio e o histórico funcionam de verdade.';

  @override
  Future<Result<RespostaKai>> enviar(String mensagem) async {
    await Future<void>.delayed(atrasoKai);
    if (_banco.semRede) return _semRede();

    final pergunta = mensagem.toLowerCase();
    var resposta = respostaPadrao;
    for (final entrada in _respostas.entries) {
      if (pergunta.contains(entrada.key)) {
        resposta = entrada.value;
        break;
      }
    }
    return Success<RespostaKai>(RespostaKai(texto: resposta));
  }

  @override
  Future<Result<bool>> disponivel() async =>
      _atraso(Success<bool>(!_banco.semRede));
}
