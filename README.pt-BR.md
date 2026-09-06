# dotfiles

Configuração pessoal de ambiente de desenvolvimento para **.NET**, **Git** e **GitHub Codespaces**.

[English](README.md) | [Português (Brasil)](README.pt-BR.md)

Este repositório contém apenas preferências e helpers no nível do desenvolvedor. Requisitos específicos continuam pertencendo ao repositório de cada projeto.

## Objetivos

- Manter preferências de Git e shell consistentes entre ambientes de desenvolvimento.
- Disponibilizar pequenos helpers para fluxos recorrentes em repositórios .NET.
- Funcionar de forma segura com GitHub Codespaces.
- Respeitar configurações de projeto como `global.json`, `Directory.Build.props`, `Directory.Packages.props` e manifests locais de ferramentas .NET.
- Evitar a instalação global de dependências que pertencem aos projetos.

## Limites de responsabilidade

| Responsabilidade | Fonte de verdade |
| --- | --- |
| Aliases de shell e helpers pessoais de CLI | Este repositório |
| Padrões pessoais de Git | Este repositório |
| Versão do SDK .NET | `global.json` do projeto |
| Versões de pacotes NuGet | Arquivos do projeto / `Directory.Packages.props` |
| Configuração MSBuild | Arquivos do projeto / `Directory.Build.props` |
| Ferramentas .NET locais | `.config/dotnet-tools.json` do projeto |
| Extensões VS Code do projeto | `.vscode/extensions.json` do projeto |
| Preferências pessoais do VS Code | VS Code Settings Sync |
| Secrets e credenciais | Secrets do Codespaces / repositório / ambiente |

## Estrutura do repositório

```text
dotfiles/
├── .agents/
│   └── skills/
├── .githooks/
│   └── pre-commit
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       └── validate.yml
├── bin/
│   ├── dotfiles-doctor
│   ├── dotfiles-update
│   ├── dotnet-bootstrap
│   ├── dotnet-context
│   └── git-root
├── git/
│   └── config
├── scripts/
│   └── validate-shell
├── shell/
│   ├── aliases.sh
│   ├── dotnet.sh
│   └── git.sh
├── tests/
│   ├── container-smoke.sh
│   ├── dotnet-helpers.bats
│   ├── lifecycle.bats
│   ├── update.bats
│   └── test_helper.bash
├── .dockerignore
├── .editorconfig
├── .gitattributes
├── .gitignore
├── AGENTS.md
├── AGENTS.pt-BR.md
├── Dockerfile.test
├── install.sh
├── uninstall.sh
├── LICENSE
├── README.md
└── README.pt-BR.md
```

## Governança do repositório

Este repositório segue a mesma filosofia de governança utilizada no template de projetos .NET, aplicando apenas as convenções que fazem sentido para um repositório de Bash, Git e Codespaces.

- `AGENTS.md` define as regras gerais para contribuidores automatizados.
- `.agents/skills/dotfiles-change/` cobre mudanças gerais nos dotfiles.
- `.agents/skills/shell-hardening/` foca em segurança Bash e ShellCheck.
- `.agents/skills/codespaces-integration/` foca no ciclo de vida do GitHub Codespaces e nos limites de configuração.
- `Directory.Build.props` e `Directory.Packages.props` são deliberadamente ausentes porque este repositório não contém um projeto MSBuild.

Os arquivos de governança complementam a configuração real do repositório; eles não a substituem como fonte de verdade.

## GitHub Codespaces

No GitHub:

1. Abra **Settings**.
2. Acesse **Codespaces**.
3. Localize **Dotfiles**.
4. Ative a instalação automática de dotfiles.
5. Selecione este repositório.

Ao criar um novo Codespace, o GitHub pode clonar este repositório e executar o `install.sh`.

O instalador foi projetado para ser idempotente e deve ser executado pelo usuário normal de desenvolvimento, nunca como `root`. Ele:

- usa `${XDG_CONFIG_HOME:-$HOME/.config}/rodri-dotfiles` como localização estável de configuração;
- cria links para os helpers de shell e para a configuração Git nessa localização;
- adiciona o bloco dos dotfiles ao `~/.bashrc` apenas uma vez e carrega os fragmentos somente quando estão legíveis;
- migra o `include.path` Git original, relativo ao repositório, para a localização estável;
- disponibiliza os scripts de `bin/` por meio de `~/.local/bin`;
- configura o `core.hooksPath` local deste repositório para `.githooks`, sem alterar o caminho global de hooks utilizado pelos outros repositórios.

Ele deliberadamente **não** substitui o `~/.bashrc` ou o `~/.gitconfig` completos, evitando sobrescrever configurações criadas pelo Codespaces ou por outras ferramentas.

## Ambientes suportados

| Ambiente | Status | Observações |
| --- | --- | --- |
| GitHub Codespaces + Bash | Principal | Alvo principal para instalação automática dos dotfiles |
| Linux + Bash | Suportado | Mesmo modelo de instalação utilizado no Codespaces |
| WSL + Bash | Esperado | Projetado para funcionar, mas ainda sem CI dedicado |
| Zsh / PowerShell | Não configurado | Atualmente o repositório gerencia apenas inicialização Bash |

## Ciclo de vida e diagnóstico

Instale ou atualize a configuração gerenciada:

```bash
./install.sh
source ~/.bashrc
```

Verifique o ambiente atual:

```bash
dotfiles-doctor
```

O doctor valida o bloco Bash gerenciado, PATH, links de configuração, `include.path` do Git, configuração local dos hooks deste repositório, links dos helpers executáveis, disponibilidade de Bash/Git e informa o SDK .NET detectado quando disponível. Ele retorna código diferente de zero quando uma invariável da configuração gerenciada está quebrada.

Atualize com segurança um clone existente:

```bash
dotfiles-update
```

O `dotfiles-update` se recusa a executar quando o worktree possui alterações não commitadas, quando o repositório está em detached HEAD ou quando a branch atual não possui upstream. Ele busca alterações remotas, aplica somente um pull fast-forward, executa novamente o `install.sh` e termina com `dotfiles-doctor`. O comando nunca executa reset, stash ou descarte automático de trabalho local.

Remova apenas a configuração pertencente a este repositório:

```bash
./uninstall.sh
```

O desinstalador remove o bloco gerenciado do `~/.bashrc`, as entradas Git exatas, o caminho local de hooks gerenciado deste repositório e os links simbólicos criados pelo repositório. Arquivos do usuário, configurações Git não relacionadas, outras configurações de shell, `~/.local/bin` e arquivos não gerenciados permanecem intactos.

## Git hooks do repositório

Ao executar `install.sh`, `.githooks` é configurado somente para este repositório de dotfiles. O instalador não define um `core.hooksPath` global, portanto hooks específicos dos seus outros repositórios .NET permanecem intactos.

O hook `pre-commit` sempre executa a validação de sintaxe Bash. Quando ShellCheck e shfmt estão instalados localmente, também executa essas verificações. A ausência dessas ferramentas locais gera um aviso em vez de bloquear o commit; o CI continua sendo o gate autoritativo e sempre instala e exige ambas.

Hook e CI compartilham o mesmo ponto de entrada de validação:

```bash
bash scripts/validate-shell
```

## Comandos .NET

### Aliases

| Alias | Comando |
| --- | --- |
| `dr` | `dotnet restore` |
| `db` | `dotnet build` |
| `dt` | `dotnet test` |
| `dnfmt` | `dotnet format` |
| `dp` | `dotnet pack` |
| `dc` | `dotnet clean` |
| `dtr` | `dotnet tool restore` |
| `dtl` | `dotnet tool list` |
| `dsdks` | `dotnet --list-sdks` |
| `druntimes` | `dotnet --list-runtimes` |
| `dinfo` | `dotnet --info` |

### `dotnet-bootstrap`

Prepara um repositório .NET para desenvolvimento a partir de qualquer diretório dentro do worktree Git.

Se existir `.config/dotnet-tools.json` na raiz, restaura primeiro as ferramentas locais. Quando existe exatamente um `.sln` ou `.slnx` na raiz, essa solução é restaurada automaticamente. Se houver várias soluções, o helper interrompe a execução e exige um alvo explícito em vez de escolher uma arbitrariamente.

```bash
dotnet-bootstrap
dotnet-bootstrap Ocelot.slnx
```

Opções adicionais de restore podem ser informadas depois do alvo. Quando existe apenas uma solução, as opções podem ser passadas diretamente.

### `dotnet-context`

Exibe o SDK efetivo e detecta convenções comuns a partir da raiz do repositório Git, mesmo quando executado em um subdiretório:

- `global.json`;
- `Directory.Build.props`;
- `Directory.Packages.props`;
- manifests locais de ferramentas .NET;
- arquivos `.sln` e `.slnx`.

```bash
dotnet-context
```

### `dotnet-sdk`

Exibe a configuração de SDK do repositório e o SDK resolvido pela CLI do .NET.

```bash
dotnet-sdk
```

### `dotnet-tools`

Lista as ferramentas .NET locais quando o repositório possui um tool manifest.

```bash
dotnet-tools
```

### `dotnet-solutions`

Lista arquivos `.sln` e `.slnx` existentes na raiz do repositório Git sem selecionar um deles automaticamente.

```bash
dotnet-solutions
```

## Comandos Git

### Aliases

| Alias | Comando |
| --- | --- |
| `gs` | `git status --short --branch` |
| `gb` | `git branch` |
| `gba` | `git branch --all` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git log --graph --decorate --oneline --all` |

### Helpers

`git-root` exibe a raiz do repositório Git atual.

```bash
git-root
```

`git-default-branch` identifica a branch padrão do remoto e usa `main` ou `master` como fallback.

```bash
git-default-branch
```

`git-recent-branches` lista as branches locais atualizadas mais recentemente.

```bash
git-recent-branches
git-recent-branches 20
```

## Decisões de design

### O SDK permanece no escopo do projeto

Este repositório não instala nem fixa globalmente uma versão do SDK .NET.

Um projeto que dependa de uma versão específica deve declará-la no `global.json`. Isso permite que projetos diferentes utilizem feature bands distintas do .NET 10 sem ficarem acoplados ao ambiente pessoal.

### Ferramentas .NET permanecem no escopo do projeto

Ferramentas como SonarScanner devem permanecer no `.config/dotnet-tools.json` quando fizerem parte da toolchain do projeto.

Use:

```bash
dotnet tool restore
```

ou:

```bash
dotnet-bootstrap
```

em vez de instalar essas ferramentas globalmente.

### Extensões do VS Code permanecem no escopo do projeto

Recomendações de extensões específicas pertencem ao `.vscode/extensions.json` de cada projeto.

Preferências pessoais do editor devem ser sincronizadas pelo VS Code Settings Sync em vez de instaladas pelo `install.sh`.

## Validação e testes automatizados

O repositório valida qualidade estática, comportamento observável e o ciclo de vida completo da instalação.

Validação estática:

- sintaxe Bash com `bash -n`;
- análise de shell com ShellCheck;
- formatação determinística com `shfmt -d -i 2`.

A validação comportamental usa Bats e cobre idempotência da instalação, links estáveis de configuração, gerenciamento do include do Git e dos hooks do repositório, comportamento de doctor/uninstall, comportamento seguro do `dotfiles-update`, descoberta da raiz do repositório, restore de ferramentas .NET locais e tratamento de uma ou várias solutions.

Um container Ubuntu limpo também valida que a instalação é recusada para `root`, funciona e permanece idempotente para um usuário normal, configura os hooks do repositório, passa no `dotfiles-doctor` e pode ser desinstalada com segurança.

Para executar localmente, depois de instalar `bats`, `shellcheck` e `shfmt`:

```bash
bash scripts/validate-shell
bats tests
docker build --file Dockerfile.test --tag dotfiles-lifecycle-test .
```

Essas ferramentas são dependências somente de desenvolvimento/CI; o `install.sh` não as instala no ambiente pessoal.

### Hardening do CI

O workflow de validação é deliberadamente restrito e endurecido:

- executa somente quando entradas que afetam shell/runtime são alteradas, evitando uso de runner em mudanças apenas documentais;
- concurrency cancela execuções antigas da mesma ref quando chega um commit mais novo;
- a validação de shell possui timeout de cinco minutos e a validação em container limpo possui timeout de dez minutos;
- as permissões do repositório são somente leitura;
- `actions/checkout` fica fixado em um commit SHA completo e não persiste credenciais;
- o job de container limpo executa somente depois que validação estática e Bats passam;
- o Dependabot verifica semanalmente dependências do GitHub Actions e agrupa atualizações disponíveis em um único pull request.

Arquivos:

```text
.github/workflows/validate.yml
.github/dependabot.yml
Dockerfile.test
```

Se esse workflow passar a ser um status check obrigatório no futuro, revise os filtros de paths antes de depender dele em pull requests somente de documentação.

## Segurança

Nunca versione:

- Personal Access Tokens;
- chaves de API do NuGet;
- senhas;
- connection strings;
- credenciais de cloud;
- chaves SSH privadas;
- outros secrets.

Use GitHub Codespaces secrets, repository secrets ou environment secrets.

## Licença

MIT. Consulte [LICENSE](LICENSE).
