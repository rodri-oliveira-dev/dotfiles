# dotfiles

Configuração pessoal de ambiente de desenvolvimento com foco em .NET e GitHub Codespaces.

O repositório mantém deliberadamente separadas as preferências pessoais dos requisitos dos projetos:

- **dotfiles**: aliases de shell, padrões de Git e helpers pessoais de CLI.
- **repositório**: versão do SDK .NET, ferramentas locais, gerenciamento de pacotes, serviços, portas e build.
- **VS Code Settings Sync / `.vscode`**: preferências do editor e extensões recomendadas por projeto.

## Princípios

- Não instalar SDK .NET globalmente por este repositório.
- Não instalar globalmente ferramentas .NET que pertencem ao projeto.
- Respeitar o `global.json` de cada repositório.
- Respeitar `.config/dotnet-tools.json` e usar `dotnet tool restore`.
- Não armazenar secrets, tokens, API keys, chaves SSH privadas ou connection strings.
- Manter a instalação idempotente e segura para GitHub Codespaces.

## Instalação

O GitHub Codespaces pode clonar automaticamente este repositório e executar `install.sh`.

Para instalação manual:

```bash
./install.sh
source ~/.bashrc
```

## Comandos

### Aliases .NET

| Alias | Comando |
| --- | --- |
| `dr` | `dotnet restore` |
| `db` | `dotnet build` |
| `dt` | `dotnet test` |
| `df` | `dotnet format` |
| `dp` | `dotnet pack` |
| `dc` | `dotnet clean` |
| `dtr` | `dotnet tool restore` |
| `dtl` | `dotnet tool list` |
| `dinfo` | `dotnet --info` |

### Helpers

`dotnet-bootstrap`

Restaura ferramentas .NET locais quando existe um manifest e depois restaura os pacotes NuGet.

```bash
dotnet-bootstrap
```

`dotnet-context`

Exibe o SDK ativo e detecta convenções comuns do repositório, como `global.json`,
`Directory.Build.props`, `Directory.Packages.props`, manifests locais, `.sln` e `.slnx`.

```bash
dotnet-context
```

`dotnet-sdk`

Exibe a configuração de SDK do repositório e o SDK resolvido pela CLI do .NET.

```bash
dotnet-sdk
```

`dotnet-solutions`

Lista as soluções existentes na raiz sem escolher uma automaticamente.

```bash
dotnet-solutions
```

`git-root`

Exibe a raiz do repositório Git atual.

```bash
git-root
```

## Por que as ferramentas dos projetos não são instaladas globalmente

Os repositórios .NET que este ambiente atende usam com frequência `global.json`,
`Directory.Build.props`, `Directory.Packages.props` e `.config/dotnet-tools.json`.

Esses arquivos devem continuar sendo a fonte de verdade. Por exemplo, o SonarScanner deve ser
restaurado pelo manifest do projeto em vez de ser instalado globalmente por estes dotfiles.

## Segurança

Nunca versione secrets neste repositório. Use GitHub Codespaces secrets ou secrets de
repositório/ambiente para credenciais.

## Licença

MIT
