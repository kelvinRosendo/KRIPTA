# 🎓 KRIPTA

<p align="center">
  <strong>Organize. Estude. Evolua.</strong>
</p>

<p align="center">
  Uma plataforma educacional desenvolvida para auxiliar estudantes na organização da rotina acadêmica, acompanhamento dos estudos e gerenciamento de atividades.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-em%20desenvolvimento-yellow" alt="Status">
  <img src="https://img.shields.io/badge/java-21-orange" alt="Java">
  <img src="https://img.shields.io/badge/spring%20boot-3.x-brightgreen" alt="Spring Boot">
  <img src="https://img.shields.io/badge/postgresql-16-blue" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/maven-build-C71A36" alt="Maven">
  <img src="https://img.shields.io/badge/license-acadêmico-lightgrey" alt="License">
</p>

---

## 📖 Sobre o KRIPTA

O **KRIPTA** é uma plataforma educacional desenvolvida como **Trabalho de Conclusão de Curso (TCC)**, com o propósito de auxiliar estudantes na organização de sua rotina acadêmica.

A proposta surgiu a partir da percepção de que estudantes precisam lidar diariamente com diferentes conteúdos, atividades, prazos e responsabilidades, muitas vezes utilizando ferramentas separadas para cada necessidade.

Nesse contexto, o KRIPTA busca reunir diferentes recursos em um único ambiente, permitindo que o estudante organize suas atividades, acompanhe seu progresso e tenha uma visão mais clara da sua rotina de estudos.

Além disso, o projeto explora a utilização de **gamificação** e **Inteligência Artificial** como recursos complementares ao processo de aprendizagem.

---

## 🎯 Objetivo

O principal objetivo do KRIPTA é desenvolver uma plataforma capaz de **auxiliar estudantes na organização e acompanhamento de suas atividades acadêmicas**, centralizando informações e recursos relacionados aos estudos.

### Objetivos específicos

- 📚 Organizar conteúdos e disciplinas;
- ✅ Gerenciar tarefas e atividades acadêmicas;
- 📅 Auxiliar no acompanhamento de prazos;
- 📊 Permitir o acompanhamento do progresso dos estudos;
- 🎮 Utilizar elementos de gamificação;
- 🤖 Explorar recursos de Inteligência Artificial como apoio aos estudos;
- 🧠 Centralizar informações acadêmicas em um único ambiente;
- 📈 Fornecer uma visão mais clara da rotina acadêmica.

---

# ✨ Funcionalidades

> 🚧 Algumas funcionalidades ainda estão em desenvolvimento.

### 👤 Autenticação e usuários

- Cadastro de usuários;
- Login;
- Autenticação segura;
- Gerenciamento de perfil;
- Controle de acesso.

### 📚 Organização acadêmica

- Cadastro de disciplinas;
- Organização de conteúdos;
- Gerenciamento de atividades;
- Organização da rotina acadêmica.

### ✅ Tarefas

- Criação de tarefas;
- Edição de tarefas;
- Exclusão de tarefas;
- Definição de prazos;
- Controle de conclusão;
- Acompanhamento das atividades pendentes.

### 📊 Progresso

- Acompanhamento das atividades realizadas;
- Progresso acadêmico;
- Histórico de estudos;
- Indicadores de desempenho.

### 🎮 Gamificação

O KRIPTA utiliza conceitos de gamificação para tornar o acompanhamento dos estudos mais interativo.

Entre os elementos planejados estão:

- ⭐ Pontuação;
- 🏆 Conquistas;
- 📈 Evolução do usuário;
- 🎯 Metas;
- 🔥 Sequência de estudos.

> A gamificação possui caráter complementar e busca incentivar a continuidade dos estudos.

### 🤖 Inteligência Artificial

O projeto também explora a utilização de Inteligência Artificial como recurso de apoio ao estudante.

Entre as possibilidades estão:

- Resumo de conteúdos;
- Geração de questões;
- Apoio na revisão;
- Sugestões de estudo;
- Auxílio na organização da rotina.

> A IA é tratada como uma ferramenta de apoio, não como substituta do processo de aprendizagem.

---

# 🏗️ Arquitetura

O backend do KRIPTA utiliza uma arquitetura baseada em **Spring Boot**, organizada em camadas para facilitar a manutenção, evolução e colaboração entre os integrantes da equipe.

```text
                    ┌──────────────────┐
                    │    FRONTEND      │
                    │   KRIPTA WEB     │
                    └────────┬─────────┘
                             │
                             │ HTTP / REST
                             ▼
                    ┌──────────────────┐
                    │   CONTROLLER     │
                    │                  │
                    │ Recebe requests  │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │     SERVICE      │
                    │                  │
                    │ Regras de negócio│
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │   REPOSITORY     │
                    │                  │
                    │ Acesso aos dados │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │    POSTGRESQL    │
                    │                  │
                    │ Banco de dados   │
                    └──────────────────┘

```

# 📂 Estrutura do Backend

```text

backend/
│
├── src/
│   │
│   ├── main/
│   │   │
│   │   ├── java/
│   │   │   └── br/
│   │   │       └── com/
│   │   │           └── kripta/
│   │   │               │
│   │   │               ├── config/
│   │   │               │
│   │   │               ├── controller/
│   │   │               │
│   │   │               ├── service/
│   │   │               │
│   │   │               ├── repository/
│   │   │               │
│   │   │               ├── model/
│   │   │               │
│   │   │               ├── dto/
│   │   │               │
│   │   │               ├── exception/
│   │   │               │
│   │   │               ├── security/
│   │   │               │
│   │   │               └── ai/
│   │   │
│   │   └── resources/
│   │
│   └── test/
│
├── pom.xml
├── .gitignore
└── README.md
```

# 🛠️ Tecnologias

## Backend

| Tecnologia | Utilização |
|---|---|
| ☕ Java | Linguagem principal |
| 🌱 Spring Boot | Framework backend |
| 📦 Maven | Gerenciamento do projeto |
| 🗄️ PostgreSQL | Banco de dados |
| 🔗 Spring Data JPA | Persistência de dados |
| 💤 Hibernate | ORM |
| 🔐 Spring Security | Segurança e autenticação |
| 🎟️ JWT | Autenticação baseada em tokens |

## Desenvolvimento

| Ferramenta | Utilização |
|---|---|
| 🔀 Git | Controle de versão |
| 🐙 GitHub | Colaboração e hospedagem |
| 🤖 OpenCode | Auxílio no desenvolvimento |
| 🧪 JUnit | Testes |

---

# 🔄 Fluxo de desenvolvimento

O desenvolvimento do KRIPTA utiliza Git e GitHub para permitir que os integrantes trabalhem simultaneamente.

```text
                 ┌───────────────┐
                 │     MAIN      │
                 └───────┬───────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
       feature/tasks          feature/auth
              │                     │
              ▼                     ▼
       Desenvolvimento       Desenvolvimento
              │                     │
              ▼                     ▼
       Pull Request          Pull Request
              │                     │
              └──────────┬──────────┘
                         ▼
                    Code Review
                         │
                         ▼
                       MERGE
                         │
                         ▼
                       MAIN

```

Cada funcionalidade deve ser desenvolvida em uma branch própria.

### Exemplos

feature/auth
feature/tasks
feature/dashboard
feature/gamification
feature/ai
fix/login
fix/task-validation

---

# 🤖 Uso de Inteligência Artificial no desenvolvimento

O projeto utiliza ferramentas de Inteligência Artificial, especialmente o OpenCode, como apoio ao processo de desenvolvimento.

A IA pode auxiliar em atividades como:

- Geração de código;
- Análise de erros;
- Refatoração;
- Criação de testes;
- Documentação;
- Sugestões de arquitetura;
- Identificação de possíveis problemas.

Entretanto, todo código gerado por IA deve ser analisado, testado e validado pelos integrantes da equipe antes de ser incorporado ao projeto.

Fluxo de utilização da IA:

Desenvolvedor
      ↓
   OpenCode
      ↓
Código gerado
      ↓
Revisão humana
      ↓
Testes
      ↓
Pull Request
      ↓
Code Review
      ↓
     Merge

A utilização da IA tem como objetivo auxiliar o desenvolvimento, não substituir a compreensão técnica dos integrantes.

---

# 👥 Equipe

Projeto desenvolvido por estudantes como parte de um Trabalho de Conclusão de Curso.

| Integrante | Responsabilidade |
|---|---|
| 👨‍💻 Kelvin Rosendo | Desenvolvimento e liderança técnica |
| 👨‍💻 Pedro Manoel Gimenes | Desenvolvimento |
| 👨‍💻 Murylo | Design e desenvolvimento |
| 👩‍💻 Julia Cerqueira | Pesquisa, documentação e desenvolvimento |
| 👨‍💻 Integrante | Desenvolvimento |

> As responsabilidades podem ser atualizadas conforme a evolução do projeto.

---

# 🚧 Status do projeto

████████░░░░░░░░░░░░  Em desenvolvimento

O KRIPTA encontra-se atualmente em fase de desenvolvimento.

### Roadmap

- [ ] Definição inicial do projeto
- [ ] Definição da arquitetura
- [ ] Estrutura inicial do backend
- [ ] Configuração do Spring Boot
- [ ] Configuração do PostgreSQL
- [ ] Sistema de autenticação
- [ ] Gerenciamento de usuários
- [ ] Sistema de disciplinas
- [ ] Sistema de tarefas
- [ ] Sistema de conteúdos
- [ ] Acompanhamento de progresso
- [ ] Gamificação
- [ ] Integração com IA
- [ ] Testes
- [ ] Integração frontend + backend
- [ ] Versão MVP
- [ ] Testes finais
- [ ] Apresentação do TCC

---

# 🔐 Segurança

O KRIPTA considera aspectos de segurança durante o desenvolvimento da aplicação.

Entre os mecanismos planejados estão:

- Autenticação de usuários;
- Autorização;
- Senhas armazenadas de forma segura;
- Tokens JWT;
- Validação de dados;
- Proteção de endpoints;
- Variáveis sensíveis mantidas fora do código-fonte.

Informações sensíveis, como senhas, tokens e chaves de API, não devem ser enviadas para o repositório.

---

# 📌 Escopo

O KRIPTA está sendo desenvolvido como um projeto acadêmico e possui um escopo definido para sua versão MVP.

O objetivo não é substituir plataformas educacionais existentes, mas desenvolver e avaliar uma solução que centralize recursos de organização e acompanhamento dos estudos em um único ambiente.

As funcionalidades podem ser modificadas, adicionadas ou removidas conforme os resultados do desenvolvimento e as necessidades identificadas durante o projeto.

---

# 📚 Projeto acadêmico

Este projeto está sendo desenvolvido como parte de um:

**Trabalho de Conclusão de Curso — TCC**

O desenvolvimento envolve conceitos de:

- Engenharia de Software;
- Engenharia de Requisitos;
- Desenvolvimento Web;
- Banco de Dados;
- Arquitetura de Software;
- Segurança da Informação;
- Gamificação;
- Inteligência Artificial;
- Controle de versão;
- Desenvolvimento colaborativo.

---

<p align="center">

### 🎓 KRIPTA

**Organize. Estude. Evolua.**

Desenvolvido com ☕ Java, 💡 ideias e muita persistência.

</p>
