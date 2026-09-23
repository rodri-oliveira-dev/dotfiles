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
│   ├── dotnet-deps
│   ├── dotnet-items
│   ├── dotnet-prop
│   ├── dotnet-props
│   ├── dotnet-repo-doctor
│   ├── dotnet-verify
│   ├── dotnet-why
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
│   ├── dotnet-deps.bats
│   ├── dotnet-helpers.bats
│   ├── dotnet-verify.bats
│   ├── lifecycle.bats
│   ├── msbuild-helpers.bats
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

Ao criar um novo Codespace, o GitHub pode clonar este repositório e executar `install.sh`.

O instalador foi projetado para ser idempotente e deve ser executado pelo usuário normal de desenvolvimento, nunca como `root`. Ele:

- usa `${XDG_CONFIG_HOME:-$HOME/.config}/rodri-dotfiles` como localização estável de configuração;
- cria links para os helpers de shell e para a configuração Git nessa localização;
- adiciona o bloco dos dotfiles ao `~/.bashrc` apenas uma vez e carrega os fragmentos somente quando estão legíveis;
- migra o `include.path` Git original, relativo ao repositório, para a localização estável;
- disponibiliza os scripts de `bin/` por meio de `~/.local/bin`;
- recusa substituir caminhos pré-existentes de configuração ou de `~/.local/bin`, exceto quando já forem exatamente os links simbólicos gerenciados esperados por este repositório;
- aceita apenas um `~/.bashrc` regular e que não seja link simbólico; os marcadores gerenciados devem ser linhas exatas, únicas e ordenadas, e as mudanças são preparadas em arquivo temporário no mesmo diretório antes da substituição atômica, preservando as permissões existentes;
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

### `dotnet-deps`

Inspeciona a saúde das dependências NuGet sem atualizar pacotes ou alterar arquivos de projeto. Os diagnósticos suportados são `vulnerable`, `outdated` e `deprecated`; `--include-transitive` inclui referências transitivas e `--json` solicita o relatório JSON estável quando o SDK resolvido oferece suporte.

```bash
dotnet-deps vulnerable
dotnet-deps vulnerable --include-transitive --json
dotnet-deps outdated
dotnet-deps deprecated MinhaApp.slnx
```

O helper resolve o SDK do repositório antes de executar o diagnóstico. Com .NET 10 ou posterior usa `dotnet package list`; com .NET 9 ou anterior usa `dotnet list package`. A saída JSON exige .NET SDK 7.0.200 ou posterior. Quando existe exatamente uma solution na raiz, ela é selecionada automaticamente; múltiplas solutions na raiz exigem alvo explícito.

O comando de listagem de pacotes pode consultar as fontes NuGet configuradas, e o .NET 10 pode executar restore automaticamente quando necessário. O helper nunca atualiza versões de pacotes. Chamada inválida, SDK não resolvido, saída JSON sem suporte, alvo inexistente ou seleção ambígua de solution retornam código `2`; nos demais casos, o exit code da CLI do .NET é preservado.

### Helpers de avaliação MSBuild

Os helpers de MSBuild inspecionam a configuração efetiva do projeto após a evaluation do MSBuild. Eles exigem .NET SDK 8 ou posterior e não executam targets de build. Quando chamados sem alvo, procuram recursivamente arquivos `.csproj`, `.fsproj` e `.vbproj`, ignorando diretórios comuns de build e conteúdo gerado. Um único projeto é selecionado automaticamente; múltiplos projetos exigem alvo explícito.

`dotnet-prop` retorna uma única propriedade avaliada como texto simples:

```bash
dotnet-prop TargetFramework
dotnet-prop ManagePackageVersionsCentrally src/MinhaApp/MinhaApp.csproj
```

`dotnet-props` exibe um snapshot de diagnóstico com target frameworks, configuração, runtime identifiers, configurações de linguagem/nullability, warnings, Central Package Management, lock file, configuração determinística/CI, geração de documentação e diretório de saída. Use `--json` para solicitar o mesmo snapshot em uma única evaluation JSON nativa do MSBuild:

```bash
dotnet-props
dotnet-props --json src/MinhaApp/MinhaApp.csproj
```

`dotnet-items` retorna itens avaliados pelo MSBuild e seus metadados usando a saída JSON nativa do MSBuild:

```bash
dotnet-items PackageReference
dotnet-items ProjectReference src/MinhaApp/MinhaApp.csproj
```

Esses helpers não restauram pacotes, não alteram arquivos de projeto e não executam targets. Chamada inválida, SDK não resolvido, SDK sem suporte, ausência de projetos, alvo inválido ou descoberta ambígua retornam código `2`; nos demais casos, o status do MSBuild é preservado. No modo legível para humanos do `dotnet-props`, uma falha na avaliação de uma propriedade retorna `1`.

### `dotnet-repo-doctor`

Executa um diagnóstico somente leitura do repositório .NET atual a partir de qualquer diretório dentro do worktree Git. Ele informa estado do repositório/branch, SDK solicitado e resolvido, solutions na raiz, quantidade de projetos e projetos de teste, target frameworks declarados, Central Package Management, tool manifest local e arquivos comuns de configuração.

```bash
dotnet-repo-doctor
```

Use `--json` quando o resultado for consumido por scripts ou agentes de codificação:

```bash
dotnet-repo-doctor --json
```

O helper não restaura pacotes, instala ferramentas, altera arquivos de projeto nem executa auditorias de pacotes pela rede. O exit code `0` indica que o diagnóstico terminou sem problema bloqueante, `1` indica que nenhum artefato de projeto ou solution .NET foi detectado e `2` indica que a CLI do .NET não está disponível, a resolução do SDK falhou ou a chamada do comando é inválida.

### `dotnet-verify`

Executa um preflight local determinístico antes de um pull request ou push. Por padrão, restaura ferramentas locais do projeto quando existe um manifest, restaura pacotes, compila sem restaurar novamente, verifica a formatação sem alterar arquivos e executa os testes sem recompilar nem restaurar outra vez.

```bash
dotnet-verify
dotnet-verify --quick
dotnet-verify --no-test
dotnet-verify MinhaApp.slnx
```

`--quick` executa somente restore e build. `--full` seleciona explicitamente a verificação completa, que também é o comportamento padrão. `--no-format` e `--no-test` ignoram individualmente esses gates. Quando existe exatamente um `.sln` ou `.slnx` na raiz, essa solution é selecionada automaticamente; múltiplas solutions exigem um alvo explícito.

O helper não instala ferramentas globais nem altera configurações do projeto. O exit code `0` indica que todas as etapas selecionadas passaram, `1` indica falha em restore/build/format/test e `2` indica que a chamada ou o ambiente não puderam ser resolvidos com segurança, como CLI do .NET ausente, SDK incompatível, alvo inexistente ou seleção ambígua de solution.

### `dotnet-why`

Exibe o grafo de dependências que explica por que um pacote NuGet está presente, encapsulando `dotnet nuget why`.

```bash
dotnet-why Microsoft.CodeAnalysis.Common
dotnet-why Microsoft.CodeAnalysis.Common MinhaApp.slnx
dotnet-why --framework net8.0 Microsoft.CodeAnalysis.Common
```

O `dotnet-why` exige .NET SDK 8.0.400 ou posterior. Ele seleciona automaticamente uma única solution na raiz, exige alvo explícito quando existem múltiplas solutions na raiz e aceita `--framework`/`-f` para restringir o grafo a um target framework. O comando não altera o repositório. Chamada inválida, SDK sem suporte, alvo inexistente ou seleção ambígua retornam código `2`; nos demais casos, o exit code do `dotnet nuget why` é preservado.

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

A validação comportamental usa Bats e cobre idempotência da instalação, links estáveis de configuração, gerenciamento do include do Git e dos hooks do repositório, comportamento de doctor/uninstall, comportamento seguro do `dotfiles-update`, descoberta da raiz do repositório, restore de ferramentas .NET locais, tratamento de uma ou várias solutions, diagnóstico somente leitura de repositórios .NET, os modos e o comportamento de falha do preflight `dotnet-verify`, os diagnósticos de saúde/origem de dependências NuGet nas formas de comando compatíveis com os SDKs suportados e a evaluation de propriedades/itens MSBuild com descoberta segura de projeto.

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
