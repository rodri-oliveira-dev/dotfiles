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
│       ├── release.yml
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
├── lib/
│   ├── dotnet-common.sh
│   └── dotnet-props-format.py
├── scripts/
│   ├── install-security-tools
│   ├── scan-tracked-secrets
│   ├── security-scan
│   └── validate-shell
├── shell/
│   ├── aliases.sh
│   ├── dotnet.sh
│   └── git.sh
├── tests/
│   ├── ci-policy.bats
│   ├── container-smoke.sh
│   ├── docker-context.sh
│   ├── dotnet-common.bats
│   ├── dotnet-deps.bats
│   ├── dotnet-helpers.bats
│   ├── dotnet-verify.bats
│   ├── lifecycle.bats
│   ├── msbuild-helpers.bats
│   ├── security-scans.sh
│   ├── update.bats
│   └── test_helper.bash
├── .dockerignore
├── .editorconfig
├── .gitattributes
├── .gitleaks.toml
├── .gitignore
├── .hadolint.yaml
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

O `dotfiles-update` trata a origem da atualização como um limite de confiança. Ele executa somente a partir da branch de distribuição `main`, rastreando `origin/main`, e o `origin` precisa resolver sem reescrita de URL para a URL oficial HTTPS ou SSH deste repositório no GitHub. Depois de um fetch com hooks desabilitados, o helper verifica que `FETCH_HEAD` corresponde exatamente a `origin/main`, que a revisão alvo é um fast-forward da revisão atual e que a revisão buscada ainda contém `install.sh` e `bin/dotfiles-doctor` executáveis. Somente então aplica o fast-forward com hooks Git desabilitados, confirma que `HEAD` corresponde à revisão validada, executa o instalador atualizado e termina com `dotfiles-doctor`. O comando nunca executa reset, stash ou descarte automático de trabalho local.

Essa política autentica a rota de distribuição configurada; ela **não** afirma que o transporte Git ou o selo "Verified" da interface do GitHub prove que o código recebido é benigno. A exigência de assinatura de commits/tags não foi ativada porque este repositório ainda não possui uma trust root local de assinatura verificável de forma consistente em Codespaces/clones Linux. As regras do repositório e o CI obrigatório protegem as mudanças que entram na `main`, enquanto o updater restringe independentemente qual remoto/branch pode ser executado.

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

## Limites de confiança dos helpers .NET

Esses helpers são atalhos de conveniência, não uma sandbox de segurança. O fato de um repositório ser um Git worktree não torna confiáveis seus arquivos de projeto, imports, fontes de pacotes, ferramentas, lógica de build ou testes.

| Grupo de helpers | O que faz | Efeitos relevantes / limite de confiança | Nível de confiança recomendado |
| --- | --- | --- | --- |
| `dotnet-context`, `dotnet-repo-doctor`, `dotnet-sdk`, `dotnet-tools`, `dotnet-solutions` | Lê metadados e configuração do repositório; alguns comandos também invocam o host .NET para informações de SDK/ferramentas. | Esses helpers não solicitam explicitamente restore de pacotes, build ou testes. Ainda assim, `global.json` e metadados de ferramentas pertencem ao repositório de destino, e invocar `dotnet` não equivale a uma inspeção puramente textual. | Adequado para repositórios que você aceita inspecionar com o host .NET instalado. Para código desconhecido, prefira primeiro inspeção de arquivos em texto. |
| `dotnet-prop`, `dotnet-props`, `dotnet-items` | Invoca `dotnet msbuild` para avaliar propriedades/itens sem executar intencionalmente um target de build. | A avaliação MSBuild carrega arquivos de projeto, resolução de SDK e imports como `Directory.Build.props`/`Directory.Build.targets` e outros imports. “Sem build” não significa avaliação isolada ou segura de projeto não confiável. | Trate o repositório e suas entradas MSBuild como confiáveis antes de executar. |
| `dotnet-deps`, `dotnet-why` | Consulta informações de pacotes/dependências pela CLI .NET. | Pode avaliar metadados do projeto e usar assets de restore existentes. `dotnet-deps` pode acessar fontes NuGet configuradas e, em SDKs compatíveis, realizar restore automaticamente. Credenciais de package sources e acesso de rede podem entrar no escopo. | Use somente após revisar fontes/configuração de pacotes e decidir que o repositório pode ser consultado com suas credenciais/rede. |
| `dotnet-bootstrap` | Executa restore de ferramentas locais quando existe manifest e depois restaura pacotes NuGet. | Pode acessar feeds, consumir `NuGet.config`, restaurar dependências, avaliar lógica MSBuild de restore e baixar ferramentas locais declaradas pelo repositório. | Somente repositórios confiáveis. Revise manifests e fontes de pacotes antes do uso. |
| `dotnet-verify` | Restaura ferramentas/pacotes, compila, opcionalmente verifica formatação e executa testes. | Build/test podem carregar tasks MSBuild, analyzers, source generators, tooling de formatação e código de testes fornecidos pelo repositório. Isso é execução de código com filesystem, ambiente, rede e credenciais do usuário atual, salvo restrições impostas pelo ambiente externo. | Somente repositórios confiáveis; para código externo, execute apenas após revisão/aprovação explícita em ambiente restrito. |

Entradas controladas pelo projeto incluem pelo menos `global.json`, arquivos de projeto/solution, `Directory.Build.props`, `Directory.Build.targets`, outros imports MSBuild, `Directory.Packages.props`, `.config/dotnet-tools.json` e arquivos `NuGet.config` do repositório/usuário. Revise as entradas relevantes antes de restore, avaliação MSBuild, build, formatação ou execução de testes.

Para repositórios externos ou ainda não confiáveis:

- prefira inspeção textual (`cat`, `grep`, `find`, revisão de código) antes de invocar ferramentas que entendem o projeto;
- use container, VM ou Codespace descartável sem secrets pessoais, do repositório ou de cloud;
- restrinja permissões de filesystem e acesso de rede quando for viável;
- evite expor feeds NuGet autenticados ou outras credenciais de package sources até revisar o repositório e sua configuração;
- exija uma decisão humana explícita antes de uma automação executar avaliação MSBuild, restore de ferramentas/pacotes, build, formatação ou testes.

Os helpers preservam intencionalmente suas interfaces não interativas. Eles não adicionam prompts e não alegam fornecer isolamento de processo, filesystem, credenciais ou rede.

Os sete helpers executáveis que inspecionam repositórios .NET compartilham a biblioteca Bash de uso interno `lib/dotnet-common.sh` para descoberta da raiz Git, verificação do SDK, descoberta de solutions/projetos e resolução de caminhos. Os comandos públicos preservam seus parsers de argumentos e as diferenças intencionais de seleção de alvo. Os helpers resolvem seu próprio caminho antes de carregar a biblioteca, inclusive por links gerenciados em `~/.local/bin`. Mantenha `lib/` junto de `bin/` ao copiar o repositório de dotfiles.

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

`dotnet-props` exibe um snapshot de diagnóstico com target frameworks, configuração, runtime identifiers, configurações de linguagem/nullability, warnings, Central Package Management, lock file, configuração determinística/CI, geração de documentação e diretório de saída. Os dois modos agora avaliam as 19 propriedades com **uma** invocação do MSBuild. O modo legível usa o parser JSON da biblioteca padrão do Python 3 para validar o resultado inteiro antes da formatação; ele exige Python 3 disponível no `PATH`, sem instalá-lo automaticamente ou adicionar dependências ao projeto. Use `--json` para receber a mesma resposta JSON nativa do MSBuild **sem precisar de Python 3**:

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

Um container Ubuntu limpo também valida que a instalação é recusada para `root`, funciona e permanece idempotente para um usuário normal, configura os hooks do repositório, passa no `dotfiles-doctor` e pode ser desinstalada com segurança. O contexto Docker de teste é deny-by-default: somente entradas do lifecycle são permitidas, e um teste com sentinelas confirma que arquivos locais fictícios de `.env`/log não aparecem no filesystem final nem nas camadas salvas da imagem.

Para executar localmente, depois de instalar `bats`, `shellcheck` e `shfmt`:

```bash
bash scripts/validate-shell
bats tests
docker build --file Dockerfile.test --tag dotfiles-lifecycle-test .
bash tests/docker-context.sh
```

Essas ferramentas são dependências somente de desenvolvimento/CI; o `install.sh` não as instala no ambiente pessoal.

### Hardening do CI

O workflow de validação é deliberadamente endurecido:

- todo pull request voltado à `main` executa a validação, inclusive mudanças somente em documentação e `git/config`, garantindo que os checks obrigatórios sempre sejam reportados;
- concurrency cancela execuções antigas da mesma ref quando chega um commit mais novo;
- as validações de shell/segurança e de container limpo possuem timeouts limitados de dez minutos;
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

Pull requests voltados à `main` expõem os nomes estáveis de check `Shell validation` e `Clean container lifecycle`; o ruleset ativo da `main` exige ambos os checks com enforcement estrito de status checks.

### Varreduras de segurança

O check obrigatório `Shell validation` também executa quatro scanners de segurança antes do Bats:

| Scanner | Versão fixada | Escopo no CI | Política de falha |
| --- | ---: | --- | --- |
| Gitleaks | 8.30.1 | Todos os blobs rastreados no commit `HEAD` atual, inclusive arquivos com `export-ignore`; o gate de PR não varre histórico Git anterior, metadados `.git` nem payloads externos do Git LFS. | Qualquer finding falha o check. A saída usa redaction de 100% do segredo e nenhum relatório é enviado como artefato. |
| actionlint | 1.7.12 | Todos os workflows do GitHub Actions encontrados no checkout. | Qualquer finding sintático/semântico falha o check. |
| zizmor | 1.30.1 | Configuração local do repositório, incluindo workflows/Dependabot; execução forçada offline com coleta estrita. | Qualquer finding de auditoria ou falha de parsing bloqueia o check. Nenhum token GitHub é fornecido. |
| Hadolint | 2.15.1 | `Dockerfile.test`. | Findings de severidade warning ou superior falham. `DL3008` é ignorada explicitamente porque fixar versões dos pacotes apt do Ubuntu deixaria a imagem efêmera de smoke test frágil diante de atualizações normais do repositório. |

`scripts/install-security-tools` baixa os binários de release Linux x86_64 ou arm64 e verifica os digests SHA-256 fixados antes da instalação. O CI não usa actions de terceiros para os scanners e, portanto, não concede permissões GitHub específicas nem secrets de produção a eles. Pull requests de forks usam o mesmo workflow somente leitura.

O Gitleaks estende as regras padrão com uma única regra sintética específica do repositório. `tests/security-scans.sh` cria um finding sintético em diretórios temporários, confirma o exit code 1 e o identificador de regra esperado, em vez de aceitar qualquer erro do scanner, e verifica que o valor candidato não aparece na saída. Um fixture Git temporário commitado com `export-ignore` também comprova que o fluxo real de `scripts/scan-tracked-secrets` detecta blobs rastreados omitidos por `git archive`. Nenhuma credencial real é usada; os fixtures e a saída capturada são removidos após o teste.

O tratamento de falso positivo é deliberadamente explícito: não suprima findings de forma ampla apenas para fazer o CI passar. Prefira corrigir a origem, restringir a configuração do scanner ao menor rule/path justificável e documentar a exceção na configuração e no pull request.

Execute os mesmos gates localmente em Linux x86_64/arm64 suportado:

```bash
bash scripts/install-security-tools
bash scripts/security-scan
```

Para uma auditoria ocasional do histórico completo, execute Gitleaks explicitamente sobre o histórico após considerar as implicações de saída/log:

```bash
gitleaks git --config .gitleaks.toml --no-banner --no-color --redact=100 .
```

## Releases manuais e tags imutáveis

O workflow `Publish release` (`.github/workflows/release.yml`) é acionado **somente de forma manual**. Depois do merge do PR, acesse **Actions → Publish release → Run workflow**, selecione `main` e informe a versão SemVer estável **sem** o prefixo `v`, por exemplo `1.0.0`. O workflow cria a nova tag leve `v1.0.0` apontando para o commit atual da `main` e publica uma GitHub Release com notas geradas automaticamente. Não compila nem envia binários.

O workflow recusa execução fora da `main`, versões inválidas (inclusive pré-release e metadados de build), commit selecionado desatualizado e nomes de tags já criados. As publicações são serializadas e não são canceladas automaticamente. Apenas o job de publicação recebe `contents: write`; não são necessários actions de terceiros, PAT ou secret adicional. **Não execute a primeira release antes da ativação do ruleset de tags abaixo.**

A configuração desejada do ruleset está versionada em [`.github/rulesets/immutable-tags.json`](.github/rulesets/immutable-tags.json), mas versionar esse arquivo **não ativa** uma regra administrativa no GitHub. Um administrador precisa primeiro confirmar que `Immutable tags` ainda não existe em **Settings → Rules → Rulesets** e criar um **novo ruleset de tags** com: nome `Immutable tags`, enforcement `Active`, alvo **todas as tags**, **Restrict updates** e **Restrict deletions** habilitados, **Restrict creations** desabilitado e lista de bypass vazia. A operação equivalente via API, executada uma única vez com GitHub CLI autenticado e permissão Administration: write, é:

```bash
gh api --method POST repos/rodri-oliveira-dev/dotfiles/rulesets \
  --input .github/rulesets/immutable-tags.json
```

Confira no GitHub que o ruleset foi criado e está ativo antes de publicar. Ele protege todas as tags contra alterações e exclusões, sem impedir a criação das novas versões pelo workflow. Administradores ainda podem modificar ou desativar o próprio ruleset; a proteção não é absoluta contra mudanças administrativas na política. [Documentação oficial de regras para tags](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

Se a tag for criada, mas a publicação da release falhar, **não exclua nem mova a tag**. Confirme o commit referenciado e conclua a publicação da release para a mesma tag com `gh release create vX.Y.Z --verify-tag --title vX.Y.Z --generate-notes`, usando uma conta autorizada. Reexecutar o workflow com a mesma versão falha intencionalmente, pois a tag já existe. O ruleset protege as tags Git, mas não torna, por si só, as descrições e os artefatos da release imutáveis.

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
