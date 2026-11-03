/// Conversão de DTOs em entidades de domínio.
///
/// ## Onde o mapper decide coisas
///
/// Este arquivo concentra todas as decisões de "e se o dado não vier":
///
/// - **datas**: o DTO carrega `String` (é o que o JSON traz) e aqui vira
///   `DateTime` local via [AppDateFormat.tryParse], que tolera
///   `2026-09-28T12:00:00Z`, `2026-09-28T12:00:00` e `2026-09-28`;
/// - **enums**: valores desconhecidos caem num padrão seguro
///   ([PerfilUsuario.usuario], [PrioridadeTarefa.media], …) em vez de
///   lançar — um papel novo no backend não pode quebrar o login;
/// - **números ausentes**: vêm com `defaultValue` no próprio DTO.
///
/// Nada aqui importa `dio` ou `flutter`: é Dart puro, o que mantém o
/// domínio testável e o mapper coberto por testes unitários sem mock de
/// rede.
library;

import '../../core/utils/app_date_format.dart';
import '../../domain/entities/entities.dart';
import '../dto/dto.dart';

/// Conversores de DTO para entidade.
///
/// Métodos estáticos e sem estado: são funções com nome, e não um objeto
/// com dependências para injetar.
abstract final class DtoMapper {
  // ── Usuário ────────────────────────────────────────────────────────

  /// Converte a resposta de cadastro em [Usuario].
  static Usuario usuarioFromCadastro(CadastroResponseDto dto) => Usuario(
    id: dto.id,
    nome: dto.nome,
    email: dto.email,
    perfil: PerfilUsuario.fromWire(dto.tipo),
  );

  /// Extrai o usuário embutido na resposta de login.
  ///
  /// O [LoginResponseDto] é plano: traz token e usuário no mesmo objeto.
  static Usuario usuarioFromLogin(LoginResponseDto dto) => Usuario(
    id: dto.id,
    nome: dto.nome,
    email: dto.email,
    perfil: PerfilUsuario.fromWire(dto.tipo),
  );

  /// Converte `UserResponse` em [Usuario].
  static Usuario usuarioFromResponse(UsuarioResponseDto dto) => Usuario(
    id: dto.id,
    nome: dto.nome,
    email: dto.email,
    perfil: PerfilUsuario.fromWire(dto.tipo),
  );

  // ── Conteúdo ───────────────────────────────────────────────────────

  /// Converte uma disciplina, aplicando os padrões do card.
  static Disciplina disciplina(DisciplinaResponseDto dto) => Disciplina(
    id: dto.id,
    nome: dto.nome,
    cor: dto.cor,
    docente: dto.docente,
    descricao: dto.descricao,
    pendencias: dto.pendencias ?? 0,
    icone: dto.icone ?? '📚',
    favorita: dto.favorita ?? false,
  );

  /// Converte uma lista de disciplinas, ignorando itens ilegíveis.
  ///
  /// Um único item quebrado não deve derrubar a tela inteira de grade; o
  /// item problematico é simplesmente omitido.
  static List<Disciplina> disciplinas(List<DisciplinaResponseDto> dtos) =>
      dtos.map(disciplina).toList(growable: false);

  /// Converte uma unidade.
  static Unidade unidade(UnidadeResponseDto dto) => Unidade(
    id: dto.id,
    disciplinaId: dto.subjectId,
    nome: dto.name,
    descricao: dto.description,
    totalMateriais: dto.materialsCount ?? 0,
  );

  /// Converte uma lista de unidades.
  static List<Unidade> unidades(List<UnidadeResponseDto> dtos) =>
      dtos.map(unidade).toList(growable: false);

  /// Converte um material de estudo.
  static MaterialEstudo material(MaterialResponseDto dto) => MaterialEstudo(
    id: dto.id,
    unidadeId: dto.unitId,
    titulo: dto.title,
    tipo: TipoMaterial.fromWire(dto.type),
    url: dto.url,
    descricao: dto.description,
    concluido: dto.completed,
  );

  /// Converte uma lista de materiais.
  static List<MaterialEstudo> materiais(List<MaterialResponseDto> dtos) =>
      dtos.map(material).toList(growable: false);

  /// Converte uma tarefa.
  ///
  /// A situação vem em [TarefaResponseDto.completed] (mock do frontend)
  /// ou [TarefaResponseDto.status] (`PENDING`/`COMPLETED`, mais provável
  /// no Spring). O booleano tem precedência; o status é o plano B.
  static Tarefa tarefa(TarefaResponseDto dto) {
    final concluida =
        dto.completed ??
        (dto.status != null && dto.status!.toUpperCase() == 'COMPLETED');

    return Tarefa(
      id: dto.id,
      titulo: dto.title,
      descricao: dto.description,
      prazo: AppDateFormat.tryParse(dto.dueDate),
      prioridade: PrioridadeTarefa.fromWire(dto.priority),
      concluida: concluida,
      disciplinaId: dto.subjectId,
      // O nome da disciplina vem aninhado em `subject`, quando o backend
      // o inclui, evitando uma requisição por tarefa na listagem.
      disciplinaNome: _nomeDaDisciplina(dto.subject),
      xpConquistado: dto.gamification?.xpEarned ?? 0,
    );
  }

  /// Converte uma lista de tarefas.
  static List<Tarefa> tarefas(List<TarefaResponseDto> dtos) =>
      dtos.map(tarefa).toList(growable: false);

  /// Converte um aviso.
  ///
  /// `criadoEm` é obrigatório na entidade; se o backend mandar algo
  /// inválido, usa o instante atual em vez de estourar um `RangeError`.
  static Aviso aviso(AvisoResponseDto dto) => Aviso(
    id: dto.id,
    titulo: dto.title,
    mensagem: dto.message,
    criadoEm: AppDateFormat.tryParse(dto.createdAt) ?? DateTime.now(),
    disciplinaId: _idDaDisciplina(dto.subject),
    disciplinaNome: _nomeDaDisciplina(dto.subject),
  );

  /// Converte uma lista de avisos, do mais recente para o mais antigo.
  static List<Aviso> avisos(List<AvisoResponseDto> dtos) {
    final lista = dtos.map(aviso).toList();
    lista.sort((Aviso a, Aviso b) => b.criadoEm.compareTo(a.criadoEm));
    return List<Aviso>.unmodifiable(lista);
  }

  /// Converte um evento do calendário.
  ///
  /// `dia` não pode ser nulo: um evento sem data não tem onde ser
  /// desenhado na grade, então é descartado em [eventos].
  static EventoCalendario? evento(EventoCalendarioDto dto) {
    final dia = AppDateFormat.tryParse(dto.date);
    if (dia == null) return null;
    return EventoCalendario(
      dia: DateTime(dia.year, dia.month, dia.day),
      titulo: dto.title,
      tipo: TipoEvento.fromWire(dto.type),
    );
  }

  /// Converte a lista de eventos do período, removendo os sem data.
  static List<EventoCalendario> eventos(List<EventoCalendarioDto> dtos) {
    final lista = dtos.map(evento).whereType<EventoCalendario>().toList()
      ..sort(
        (EventoCalendario a, EventoCalendario b) => a.dia.compareTo(b.dia),
      );
    return List<EventoCalendario>.unmodifiable(lista);
  }

  // ── Gamificação e dashboard ────────────────────────────────────────

  /// Converte as estatísticas de nível e XP.
  static EstatisticasGamificacao estatisticas(EstatisticasGamificacaoDto dto) =>
      EstatisticasGamificacao(
        nivel: dto.level,
        xp: dto.xp,
        xpParaProximoNivel: dto.xpToNextLevel,
        progressoNivel: dto.levelProgress,
      );

  /// Converte o resumo exibido nos cards da Home.
  static ResumoGamificacao resumo(ResumoGamificacaoDto dto) =>
      ResumoGamificacao(
        xp: dto.xp,
        nivel: dto.level,
        sequenciaDias: dto.streak,
        minutosHoje: dto.minutesToday,
      );

  /// Converte uma insígnia.
  static Conquista conquista(ConquistaDto dto) => Conquista(
    id: dto.id,
    icone: dto.icon,
    titulo: dto.title,
    descricao: dto.description,
    conquistada: dto.unlocked,
    conquistadaEm: AppDateFormat.tryParse(dto.unlockedAt),
  );

  /// Concta uma lista de insígnias.
  static List<Conquista> conquistas(List<ConquistaDto> dtos) =>
      dtos.map(conquista).toList(growable: false);

  /// Converte o progresso geral.
  static Progresso progresso(ProgressoDto dto) =>
      Progresso(percentualGeral: dto.overallProgress);

  /// Converte a visão agregada da Home.
  ///
  /// `stats` é anulável no DTO porque `json_serializable` não aceita
  /// objeto aninhado como `defaultValue`; o zero aqui é o mesmo padrão
  /// que o DTO usa para os demais campos ausentes.
  static Dashboard dashboard(DashboardDto dto) => Dashboard(
    gamificacao: dto.stats == null
        ? const ResumoGamificacao(xp: 0, nivel: 1, sequenciaDias: 0)
        : resumo(dto.stats!),
    totalConquistas: dto.badgesCount,
    tarefasHoje: tarefasRef(dto.tasksToday),
    tarefasAmanha: tarefasRef(dto.tasksTomorrow),
    tarefasAtrasadas: tarefasRef(dto.overdueTasks),
  );

  /// Converte a lista de tarefas resumidas do dashboard.
  static List<TarefaRef> tarefasRef(List<TarefaResumoDto> dtos) => dtos
      .map(
        (TarefaResumoDto dto) => TarefaRef(
          id: dto.id,
          titulo: dto.title,
          prazo: AppDateFormat.tryParse(dto.dueDate),
          disciplinaNome: dto.subjectName,
          prioridade: dto.priority,
          concluida: dto.completed,
        ),
      )
      .toList(growable: false);

  // ── Kai ────────────────────────────────────────────────────────────

  /// Converte a resposta do agente.
  ///
  /// Uma resposta vazia é convertida em `null`, para a UI exibir uma
  /// mensagem de erro em vez de um balão vazio.
  static RespostaKai? respostaKai(KaiChatResponseDto dto) {
    final texto = dto.reply.trim();
    if (texto.isEmpty) return null;
    return RespostaKai(texto: texto);
  }

  // ── Auxiliares ─────────────────────────────────────────────────────

  /// Lê `id` do objeto `subject` aninhado, quando presente.
  static int? _idDaDisciplina(Map<String, dynamic>? subject) {
    final valor = subject?['id'];
    return valor is int ? valor : int.tryParse('${valor ?? ''}');
  }

  /// Lê `name` do objeto `subject` aninhado, quando presente.
  static String? _nomeDaDisciplina(Map<String, dynamic>? subject) {
    final valor = subject?['name'] ?? subject?['nome'];
    final nome = valor?.toString().trim();
    return (nome == null || nome.isEmpty) ? null : nome;
  }
}
