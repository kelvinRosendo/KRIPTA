# 🎨 KRIPTA — Frontend

Protótipo web do KRIPTA (HTML + Tailwind CSS + JavaScript, sem framework de
runtime), integrado à API Java/Spring Boot.

---

## 🚀 Começando

```bash
cd frontend
npm install
npm run serve
```

Abra **http://localhost:5173** no navegador.

> Só o `npm install` já é suficiente: o hook `postinstall` compila o CSS automaticamente.

Para a API funcionar, o backend Spring Boot precisa estar rodando em
`http://localhost:8080` (veja `backend/`). Sem backend, o protótipo funciona em
modo demonstração — veja `services/config.js`.

---

## 📂 Estrutura

```text
frontend/
│
├── index.html              # página principal (todas as telas do protótipo)
├── src/
│   └── input.css           # fonte do Tailwind: @tailwind + componentes customizados
├── styles/
│   └── output.css          # CSS compilado (versionado no Git)
├── services/
│   ├── api.js              # camada de comunicação com a API
│   ├── auth.js             # login, sessão e token
│   ├── config.js           # ambiente, URL da API e modo de demonstração
│   ├── dev-data.js         # dados fictícios do modo demonstração
│   ├── state.js            # estado global da aplicação
│   ├── ui.js               # helpers de interface
│   ├── loader.js           # transições de tela e skeletons
│   ├── navigation.js       # troca de telas
│   ├── dashboard.js        # tela inicial
│   ├── subjects.js         # matérias
│   ├── units.js            # unidades
│   ├── content.js          # conteúdos e materiais
│   ├── tasks.js            # tarefas
│   ├── calendar.js         # prazos e calendário
│   ├── streak.js           # sequência de estudos
│   ├── gamification.js     # XP, nível e insígnias
│   ├── kai.js              # assistente de IA
│   ├── materials.js        # materiais
│   ├── announcements.js    # avisos
│   ├── notifications.js    # notificações
│   ├── prefs.js            # preferências do usuário
│   ├── modal.js            # modais
│   └── app.js              # inicialização e orquestração
├── scripts/
│   ├── serve.js            # servidor estático local (sem dependências)
│   └── build-css.js        # compilação segura do CSS (usada no postinstall)
├── assets/                 # imagens (logo)
├── backup/                 # protótipos antigos (não entram no build do Tailwind)
│
├── tailwind.config.js      # tema, cores, fontes e caminhos de varredura
├── postcss.config.js
└── package.json
```

---

## ⚙️ Scripts

| Comando             | O que faz                                                              |
|---------------------|------------------------------------------------------------------------|
| `npm install`       | Instala as dependências **e** compila o CSS (via `postinstall`)        |
| `npm run dev`       | Recompila o CSS automaticamente a cada alteração (modo watch)            |
| `npm run build`     | Gera `styles/output.css` (formatado, diff legível no Git)               |
| `npm run build:min` | Gera `styles/output.css` minificado (para publicação)                   |
| `npm run serve`     | Sobe um servidor local em `http://localhost:5173`                       |

> O `postinstall` usa o `scripts/build-css.js`, que tolera a ausência do
> Tailwind (ex.: `npm ci --omit=dev`): nesse caso ele apenas avisa e não quebra
> a instalação, já que o `styles/output.css` versionado continua válido.

---

## 🎨 Sobre o CSS e o Tailwind

O projeto usa **Tailwind CSS v3** em modo CLI (via PostCSS), sem bundler.

```text
src/input.css  ──(tailwindcss CLI)──►  styles/output.css  ──►  <link> no index.html
```

### Por que `styles/output.css` está no Git?

Ele é um **artefato de build**, e normalmente não seria versionado. Porém, neste
projeto ele **é commitado de propósito**, para que:

- quem clonar o repositório já abra a página **estilizada**, mesmo sem rodar
  `npm install`;
- a página nunca quebre por "CSS perdido" em uma nova clonagem.

O arquivo é gerado em formato **não minificado** justamente para que os diffs
no Git sejam legíveis. Se ele ficar desatualizado, basta rodar:

```bash
npm run build
```

> **Atenção:** se você alterar `src/input.css`, rode `npm run build` e **commite
> o `styles/output.css` junto**. É o passo que mantém a página estilizada para
> quem só clonar o repositório.

### Rede de segurança

O `index.html` detecta a falha de carregamento do CSS e exibe um aviso na tela
explicando como resolver. Se você vê a faixa vermelha no rodapé da página, é
este aviso: rode `npm install` dentro da pasta `frontend`.

### Ao adicionar telas ou componentes

1. Escreva o HTML usando as classes do Tailwind (e/ou os componentes de
   `src/input.css`: `.device`, `.card`, `.btn-primary`, `.btn-ghost`, `.pill`,
   `.bottomnav`, `.navitem`, `.chat-bubble-kai`, `.chat-bubble-user`,
   `.input-kai`, `.section-label`, `.icon-btn`, `.fab`, `.px-app`).
2. Se o arquivo estiver em `pages/`, `components/` ou `services/`, as classes já
   são varridas automaticamente pelo `tailwind.config.js`.
3. Rode `npm run dev` para ver o resultado.

> Classes dinâmicas montadas por JavaScript (ex.: `` `bg-${cor}` ``) **não** são
> detectadas pelo Tailwind. Nesse caso, use a lista completa em
> `safelist` no `tailwind.config.js`.

### Tema

As cores e fontes do projeto ficam em `frontend/tailwind.config.js`:

| Token           | Uso principal              |
|-----------------|----------------------------|
| `indigo`        | ação principal, marca      |
| `teal`          | secundário, concluído      |
| `lilac`         | IA (Kai)                   |
| `orange`        | prazos e attention          |
| `crimson`       | exclusão / perigo          |
| `font-display`  | Nunito (títulos)           |
| `font-body`     | Inter (texto)              |

---

## 🔌 Modo de demonstração

`frontend/services/config.js` centraliza o ambiente:

- `DEV_MODE = true` → as respostas vêm do mock (`dev-data.js`), com latência
  simulada, e falhas de rede/401/404/500 são substituídas por dados locais.
- `DEV_MODE = false` → tudo vai para a API real (`http://localhost:8080/api`).

Você também pode alternar por URL, temporariamente, apenas na aba atual:

```
http://localhost:5173/?mock=on
http://localhost:5173/?mock=off
```

---

## 📝 Notas

- O arquivo `backup/` guarda protótipos antigos em HTML puro e **não** é
  varrido pelo Tailwind, para não inflar o CSS gerado.
- O `scripts/serve.js` substitui o antigo `start index.html`, que só funcionava
  no Windows.
- O `.gitattributes` na raiz do repositório normaliza os finais de linha para
  LF, evitando diffs espúrios no `styles/output.css`.
