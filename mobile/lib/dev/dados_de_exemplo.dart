/// Cenários e dados de exemplo do modo de desenvolvimento.
///
/// Usado apenas por `main_debug.dart`. Nada aqui é importado pela
/// aplicação de produção.
library;

import '../domain/entities/entities.dart';

/// Comportamento do modo de desenvolvimento.
enum Cenario {
  /// Listas preenchidas, mutações funcionando. Serve para navegar.
  cheio,

  /// Listas vazias. Serve para conferir os estados `VazioView`.
  vazio,

  /// Falha de rede em toda leitura. Serve para conferir `ErroView` e o
  /// botão "Tentar novamente".
  erro,
}

/// Lê o cenário de `--dart-define=CE_NARIO`.
///
/// Sem a variável (ou com valor desconhecido), assume [Cenario.cheio].
Cenario cenarioDoAmbiente() {
  const bruto = String.fromEnvironment('CE_NARIO', defaultValue: 'cheio');
  return switch (bruto.toLowerCase()) {
    'vazio' => Cenario.vazio,
    'erro' => Cenario.erro,
    _ => Cenario.cheio,
  };
}

/// Conjunto de dados fictício usado pelos dublês de repository.
///
/// As datas são calculadas a partir de [DateTime.now] de propósito: um seed
/// com datas fixas ficaria defasado, e o calendário passaria a mostrar um
/// mês vazio.
class Exemplo {
  /// Monta o seed. Cada chamada devolve um conjunto novo e mutável.
  factory Exemplo.gerar({DateTime? agora}) {
    final base = agora ?? DateTime.now();
    return Exemplo._(
      usuario: const Usuario(
        id: 1,
        nome: 'Ana Souza',
        email: 'ana@kripta.dev',
        perfil: PerfilUsuario.usuario,
      ),
      disciplinas: const <Disciplina>[
        Disciplina(
          id: 1,
          nome: 'Matemática',
          cor: '#3D3DB4',
          docente: 'Prof. Carlos Menezes',
          descricao: 'Funções, trigonometria e sequências.',
          pendencias: 2,
          icone: '📐',
          favorita: true,
        ),
        Disciplina(
          id: 2,
          nome: 'História',
          cor: '#B4472D',
          docente: 'Prof. Marina Albuquerque',
          descricao: 'Do Império à República.',
          pendencias: 1,
          icone: '🏛️',
        ),
        Disciplina(
          id: 3,
          nome: 'Biologia',
          cor: '#2E7D5B',
          docente: 'Prof. Renato Vieira',
          descricao: 'Citologia e genética.',
          icone: '🧬',
        ),
        Disciplina(
          id: 4,
          nome: 'Literatura',
          cor: '#7A3E9D',
          docente: 'Prof. Helena Duarte',
          descricao: 'Modernismo brasileiro.',
          pendencias: 3,
          icone: '📖',
        ),
      ],
      unidadesPorDisciplina: const <int, List<Unidade>>{
        1: <Unidade>[
          Unidade(
            id: 101,
            disciplinaId: 1,
            nome: 'Unidade 1 — Funções e gráficos',
            descricao: 'Domínio, imagem, injetividade e gráficos.',
            totalMateriais: 4,
          ),
          Unidade(
            id: 102,
            disciplinaId: 1,
            nome: 'Unidade 2 — Trigonometria',
            descricao: 'Razões trigonométricas e lei dos senos.',
            totalMateriais: 3,
          ),
          Unidade(
            id: 103,
            disciplinaId: 1,
            nome: 'Unidade 3 — Sequências',
            descricao: 'PA, PG e soma de termos.',
            totalMateriais: 2,
          ),
        ],
        2: <Unidade>[
          Unidade(
            id: 201,
            disciplinaId: 2,
            nome: 'Unidade 1 — Brasil Imperial',
            descricao: 'Primeira República e o governo oligárquico.',
            totalMateriais: 3,
          ),
        ],
        3: <Unidade>[
          Unidade(
            id: 301,
            disciplinaId: 3,
            nome: 'Unidade 1 — Citologia',
            descricao: 'Células e organelas.',
            totalMateriais: 2,
          ),
        ],
        4: <Unidade>[
          Unidade(
            id: 401,
            disciplinaId: 4,
            nome: 'Unidade 1 — Modernismo',
            descricao: 'Semana de Arte Moderna e Regionalismo.',
            totalMateriais: 2,
          ),
        ],
      },
      materiaisPorUnidade: const <int, List<MaterialEstudo>>{
        101: <MaterialEstudo>[
          MaterialEstudo(
            id: 1001,
            unidadeId: 101,
            titulo: 'Aula 1 — O que é função',
            tipo: TipoMaterial.video,
            url: 'https://exemplo.dev/aula-1',
            descricao: 'Vídeo de 18 min, com os exemplos do slide 4.',
          ),
          MaterialEstudo(
            id: 1002,
            unidadeId: 101,
            titulo: 'Lista de exercícios 1',
            tipo: TipoMaterial.pdf,
            url: 'https://exemplo.dev/lista-1',
            descricao: '12 questões, as três primeiras corrigidas.',
            concluido: true,
          ),
          MaterialEstudo(
            id: 1003,
            unidadeId: 101,
            titulo: 'Apostila — gráficos de funções',
            tipo: TipoMaterial.documento,
            descricao: 'Páginas 32 a 58.',
          ),
          MaterialEstudo(
            id: 1004,
            unidadeId: 101,
            titulo: 'Anotação: função injetiva',
            tipo: TipoMaterial.nota,
            descricao: 'Resumido do quadro.',
          ),
        ],
        102: <MaterialEstudo>[
          MaterialEstudo(
            id: 1021,
            unidadeId: 102,
            titulo: 'Aula 6 — Seno, cosseno e tangente',
            tipo: TipoMaterial.video,
            url: 'https://exemplo.dev/aula-6',
          ),
          MaterialEstudo(
            id: 1022,
            unidadeId: 102,
            titulo: 'Tabela de valores',
            tipo: TipoMaterial.nota,
            descricao: 'Ângulos notáveis de 0 a 90 graus.',
          ),
          MaterialEstudo(
            id: 1023,
            unidadeId: 102,
            titulo: 'Exercícios — lei dos senos',
            tipo: TipoMaterial.pdf,
            url: 'https://exemplo.dev/senos',
          ),
        ],
        103: <MaterialEstudo>[
          MaterialEstudo(
            id: 1031,
            unidadeId: 103,
            titulo: 'Progressão aritmética — exemplos',
            tipo: TipoMaterial.nota,
          ),
          MaterialEstudo(
            id: 1032,
            unidadeId: 103,
            titulo: 'Lista de exercícios 4',
            tipo: TipoMaterial.pdf,
            url: 'https://exemplo.dev/lista-4',
          ),
        ],
        201: <MaterialEstudo>[
          MaterialEstudo(
            id: 2001,
            unidadeId: 201,
            titulo: 'Aula — República Velha',
            tipo: TipoMaterial.video,
            url: 'https://exemplo.dev/republica',
            descricao: 'Contexto das Regências e do café com leite.',
          ),
          MaterialEstudo(
            id: 2002,
            unidadeId: 201,
            titulo: 'Mapa das Regências',
            tipo: TipoMaterial.link,
            url: 'https://exemplo.dev/mapa',
            descricao: 'De 1822 a 1889.',
          ),
          MaterialEstudo(
            id: 2003,
            unidadeId: 201,
            titulo: 'Leitura — o Segundo Reinado',
            tipo: TipoMaterial.link,
            url: 'https://exemplo.dev/leitura',
          ),
        ],
        301: <MaterialEstudo>[
          MaterialEstudo(
            id: 3001,
            unidadeId: 301,
            titulo: 'Aula — células eucarióticas',
            tipo: TipoMaterial.video,
            url: 'https://exemplo.dev/celulas',
          ),
          MaterialEstudo(
            id: 3002,
            unidadeId: 301,
            titulo: 'Quadro comparativo — procarioto x eucarioto',
            tipo: TipoMaterial.documento,
            descricao: 'Preencher a tabela da atividade.',
          ),
        ],
        401: <MaterialEstudo>[
          MaterialEstudo(
            id: 4001,
            unidadeId: 401,
            titulo: 'Manifesto Antropófago',
            tipo: TipoMaterial.pdf,
            url: 'https://exemplo.dev/manifesto',
            descricao: 'Texto de Oswald de Andrade, 1928.',
          ),
          MaterialEstudo(
            id: 4002,
            unidadeId: 401,
            titulo: 'Cronologia do Modernismo',
            tipo: TipoMaterial.nota,
            concluido: true,
          ),
        ],
      },
      tarefas: <Tarefa>[
        Tarefa(
          id: 1,
          titulo: 'Resolver exercícios da lista 3',
          descricao: 'Questões 4 a 9.',
          prazo: _dia(base, 0, hora: 22),
          prioridade: PrioridadeTarefa.alta,
          disciplinaId: 1,
          disciplinaNome: 'Matemática',
        ),
        Tarefa(
          id: 2,
          titulo: 'Leitura do capítulo 4 — Brasil Imperial',
          prazo: _dia(base, 0, hora: 23),
          prioridade: PrioridadeTarefa.media,
          disciplinaId: 2,
          disciplinaNome: 'História',
        ),
        Tarefa(
          id: 3,
          titulo: 'Trabalho de Citologia',
          descricao: 'Apresentação de 6 slides.',
          prazo: _dia(base, -1, hora: 21),
          prioridade: PrioridadeTarefa.alta,
          disciplinaId: 3,
          disciplinaNome: 'Biologia',
        ),
        Tarefa(
          id: 4,
          titulo: 'Mapa mental do Modernismo',
          prazo: _dia(base, -3, hora: 18),
          prioridade: PrioridadeTarefa.media,
          disciplinaId: 4,
          disciplinaNome: 'Literatura',
        ),
        Tarefa(
          id: 5,
          titulo: 'Revisão para a prova de funções',
          prazo: _dia(base, 1, hora: 19),
          prioridade: PrioridadeTarefa.alta,
          disciplinaId: 1,
          disciplinaNome: 'Matemática',
        ),
        Tarefa(
          id: 6,
          titulo: 'Caderno de campo — ecossistemas',
          prazo: _dia(base, 1, hora: 20),
          prioridade: PrioridadeTarefa.media,
          disciplinaId: 3,
          disciplinaNome: 'Biologia',
        ),
        Tarefa(
          id: 7,
          titulo: 'Análise do poema de Oswald de Andrade',
          prazo: _dia(base, 3, hora: 20),
          prioridade: PrioridadeTarefa.media,
          disciplinaId: 4,
          disciplinaNome: 'Literatura',
        ),
        Tarefa(
          id: 8,
          titulo: 'Lista de exercícios de sequências',
          prazo: _dia(base, 5, hora: 20),
          prioridade: PrioridadeTarefa.baixa,
          disciplinaId: 1,
          disciplinaNome: 'Matemática',
        ),
        Tarefa(
          id: 9,
          titulo: 'Questões do simulado mensal',
          prazo: _dia(base, -6, hora: 20),
          prioridade: PrioridadeTarefa.media,
          disciplinaId: 2,
          disciplinaNome: 'História',
          concluida: true,
          xpConquistado: 20,
        ),
        Tarefa(
          id: 10,
          titulo: 'Introdução à análise semiótica',
          prazo: _dia(base, 10, hora: 20),
          prioridade: PrioridadeTarefa.baixa,
          disciplinaId: 4,
          disciplinaNome: 'Literatura',
          concluida: true,
          xpConquistado: 15,
        ),
      ],
      avisos: <Aviso>[
        Aviso(
          id: 1,
          titulo: 'Reajuste de datas da prova de Matemática',
          mensagem:
              'A prova de funções foi movida para o dia 24. '
              'Quem já entregou a lista 3 mantém o prazo original.',
          criadoEm: base.subtract(const Duration(hours: 3)),
          disciplinaId: 1,
          disciplinaNome: 'Matemática',
        ),
        Aviso(
          id: 2,
          titulo: 'Aula de Biologia cancelada hoje',
          mensagem:
              'A aula não acontece hoje; o conteúdo foi antecipado '
              'para a aula de ontem.',
          criadoEm: base.subtract(const Duration(days: 1, hours: 5)),
          disciplinaId: 3,
          disciplinaNome: 'Biologia',
        ),
        Aviso(
          id: 3,
          titulo: 'Semana de prova: confira o cronograma',
          mensagem:
              'O cronograma completo está no mural da escola. '
              'Recomendamos revisar primeiro os materiais em PDF.',
          criadoEm: base.subtract(const Duration(days: 3)),
        ),
        Aviso(
          id: 4,
          titulo: 'Novo material em Literatura',
          mensagem: 'O Manifesto Antropófago já está disponível na Unidade 1.',
          criadoEm: base.subtract(const Duration(days: 6)),
          disciplinaId: 4,
          disciplinaNome: 'Literatura',
        ),
      ],
      eventos: _eventosDoMes(base),
      conquistas: <Conquista>[
        Conquista(
          id: 1,
          icone: '🔥',
          titulo: 'Foguinho',
          descricao: '7 dias seguidos de estudo',
          conquistada: true,
          conquistadaEm: base.subtract(const Duration(days: 1)),
        ),
        Conquista(
          id: 2,
          icone: '📚',
          titulo: 'Leitor compulsivo',
          descricao: 'Marque 20 materiais como estudados',
          conquistada: true,
          conquistadaEm: base.subtract(const Duration(days: 4)),
        ),
        Conquista(
          id: 3,
          icone: '✅',
          titulo: 'Organizado',
          descricao: 'Conclua 10 tarefas',
          conquistada: true,
          conquistadaEm: base.subtract(const Duration(days: 8)),
        ),
        const Conquista(
          id: 4,
          icone: '🧠',
          titulo: 'Sênior',
          descricao: 'Alcance o nível 10',
          conquistada: false,
        ),
        const Conquista(
          id: 5,
          icone: '🎯',
          titulo: 'Metade do caminho',
          descricao: 'Atinja 50% de progresso geral',
          conquistada: false,
        ),
      ],
      estatisticas: const EstatisticasGamificacao(
        nivel: 4,
        xp: 1240,
        xpParaProximoNivel: 400,
        progressoNivel: 60,
      ),
      progresso: const Progresso(percentualGeral: 68),
      minutosHoje: 7,
      sequenciaDias: 7,
    );
  }

  const Exemplo._({
    required this.usuario,
    required this.disciplinas,
    required this.unidadesPorDisciplina,
    required this.materiaisPorUnidade,
    required this.tarefas,
    required this.avisos,
    required this.eventos,
    required this.conquistas,
    required this.estatisticas,
    required this.progresso,
    this.minutosHoje = 0,
    this.sequenciaDias = 0,
  });

  /// Usuário da sessão simulada.
  final Usuario usuario;

  /// Disciplinas do usuário.
  final List<Disciplina> disciplinas;

  /// Unidades indexadas por [Disciplina.id].
  final Map<int, List<Unidade>> unidadesPorDisciplina;

  /// Materiais indexados por [Unidade.id].
  final Map<int, List<MaterialEstudo>> materiaisPorUnidade;

  /// Tarefas do usuário.
  final List<Tarefa> tarefas;

  /// Avisos do usuário.
  final List<Aviso> avisos;

  /// Eventos do mês corrente, à meia-noite.
  final List<EventoCalendario> eventos;

  /// Insígnias, conquistadas ou não.
  final List<Conquista> conquistas;

  /// Nível e XP.
  final EstatisticasGamificacao estatisticas;

  /// Progresso geral.
  final Progresso progresso;

  /// Minutos de uso já registrados hoje, para o anel do "foguinho".
  ///
  /// [AppGamificacao.metaMinutosDiarios] é 10, então 7 deixa o anel em 70%
  /// e a Home anunciar "Faltam 3 min hoje" — o mesmo estado exibido pelo
  /// protótipo web. Batendo 10, o cenário do anel cheio também fica
  /// alcançável sem mexer em mais nada.
  final int minutosHoje;

  /// Sequência de dias de estudo.
  final int sequenciaDias;

  /// Quantidade de insígnias conquistadas.
  int get totalConquistas =>
      conquistas.where((Conquista c) => c.conquistada).length;

  /// Converte a tarefa em referência, para a Home.
  static TarefaRef paraReferencia(Tarefa t) => TarefaRef(
    id: t.id,
    titulo: t.titulo,
    prazo: t.prazo,
    disciplinaNome: t.disciplinaNome,
    prioridade: t.prioridade.rotulo,
    concluida: t.concluida,
  );
}

/// Devolve o dia [offset] a partir de [base], com a hora indicada.
DateTime _dia(DateTime base, int offset, {int hora = 0}) =>
    DateTime(base.year, base.month, base.day + offset, hora);

/// Espalha eventos pelos dias do mês corrente.
///
/// Ficar no mês corrente é proposital: é o mês que o calendário abre, então
/// os marcadores aparecem sem precisar navegar.
List<EventoCalendario> _eventosDoMes(DateTime base) {
  final ano = base.year;
  final mes = base.month;
  final ultimoDia = DateTime(ano, mes + 1, 0).day;

  DateTime noMes(int dia) => DateTime(ano, mes, dia.clamp(1, ultimoDia));

  return <EventoCalendario>[
    EventoCalendario(
      dia: noMes(3),
      titulo: 'Entrega da lista 1',
      tipo: TipoEvento.tarefa,
    ),
    EventoCalendario(
      dia: noMes(8),
      titulo: 'Seminário de História',
      tipo: TipoEvento.evento,
    ),
    EventoCalendario(
      dia: noMes(14),
      titulo: 'Prova de Biologia',
      tipo: TipoEvento.prova,
    ),
    EventoCalendario(
      dia: noMes(21),
      titulo: 'Feira de projetos da escola',
      tipo: TipoEvento.evento,
    ),
    EventoCalendario(
      dia: noMes(28),
      titulo: 'Prova de Matemática',
      tipo: TipoEvento.prova,
    ),
  ];
}
