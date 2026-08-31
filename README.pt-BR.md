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
│       ├── codespaces-integration/
│       │   └── SKILL.md
│       ├── dotfiles-change/
│       │   └── SKILL.md
│       └── shell-hardening/
│           └── SKILL.md
├── .github/
│   └── workflows/
│       └── validate.yml
├── bin/
│   ├── dotfiles-doctor
│   ├── dotnet-bootstrap
│   ├── dotnet-context
│   └── git-root
├── git/
│   └── config
├── shell/
│   ├── aliases.sh
│   ├── dotnet.sh
│   └── git.sh
├── tests/
│   ├── dotnet-helpers.bats
│   ├── lifecycle.bats
│   └── test_helper.bash
├── .editorconfig
├── .gitattributes
├── .gitignore
├── AGENTS.md
├── AGENTS.pt-BR.md
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

O instalador foi projetado para ser idempotente. Ele:

- usa `${XDG_CONFIG_HOME:-$HOME/.config}/rodri-dotfiles` como localização estável de configuração;
- cria links para os helpers de shell e para a configuração Git nessa localização;
- adiciona o bloco dos dotfiles ao `~/.bashrc` apenas uma vez e carrega os fragmentos somente quando estão legíveis;
- migra o `include.path` Git original, relativo ao repositório, para a localização estável;
- disponibiliza os scripts de `bin/` por meio de `~/.local/bin`.

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

O doctor valida o bloco Bash gerenciado, PATH, links de configuração, `include.path` do Git, links dos helpers executáveis, disponibilidade de Bash/Git e informa o SDK .NET detectado quando disponível. Ele retorna código diferente de zero quando uma invariável da configuração gerenciada está quebrada.

Remova apenas a configuração pertencente a este repositório:

```bash
./uninstall.sh
```

O desinstalador remove o bloco gerenciado do `~/.bashrc`, as entradas Git exatas e os links simbólicos criados pelo repositório. Arquivos do usuário, configurações Git não relacionadas, outras configurações de shell, `~/.local/bin` e arquivos não gerenciados permanecem intactos.

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

O repositório valida tanto qualidade estática quanto comportamento observável.

Validação estática:

- sintaxe Bash com `bash -n`;
- análise de shell com ShellCheck;
- formatação determinística com `shfmt -d -i 2`.

A validação comportamental usa Bats e cobre idempotência da instalação, links estáveis de configuração, gerenciamento do include do Git, comportamento de doctor/uninstall, descoberta da raiz do repositório, restore de ferramentas .NET locais e tratamento de uma ou várias solutions.

Para executar localmente, depois de instalar `bats` e `shfmt`:

```bash
bash -n install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shellcheck install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shfmt -d -i 2 install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
bats tests
```

Bats e shfmt são dependências somente de desenvolvimento/CI; o `install.sh` não os instala no ambiente pessoal.

Workflow:

```text
.github/workflows/validate.yml
```

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
