# AGENTS.md

[English](AGENTS.md) | [Português (Brasil)](AGENTS.pt-BR.md)

## Objetivo

Este repositório contém configurações pessoais de ambiente de desenvolvimento para Git, Bash, fluxos .NET e GitHub Codespaces.

As mudanças devem permanecer pequenas, reproduzíveis, seguras para reexecução e alinhadas ao comportamento real do repositório. Não trate convenções do template de bibliotecas .NET como requisitos quando elas não forem pertinentes a este repositório.

## Fontes de verdade

Leia somente o que for relevante para a tarefa, priorizando:

1. `README.md` e `README.pt-BR.md`;
2. `install.sh` e `uninstall.sh`;
3. arquivos em `shell/`;
4. arquivos em `bin/`;
5. hooks locais em `.githooks/` e validação compartilhada em `scripts/`;
6. `git/config`;
7. `.editorconfig`, `.gitattributes`, `.gitignore`, `.dockerignore` e `Dockerfile.test`;
8. testes em `tests/`;
9. workflows que realmente existem em `.github/workflows/`;
10. `.github/dependabot.yml` para manutenção automatizada das dependências do GitHub Actions;
11. `.agents/skills/` para tarefas especializadas.

Não assuma que uma ferramenta, workflow, serviço, secret ou dependência existe sem que esteja presente no repositório ou seja fornecida explicitamente pelo ambiente.

## Limites do repositório

- Preferências pessoais de shell e aliases pertencem a `shell/`.
- Pequenos helpers executáveis pertencem a `bin/`.
- Hooks Git locais deste repositório pertencem a `.githooks/`; eles não devem sobrescrever hooks de repositórios não relacionados.
- Pontos de entrada compartilhados para validação do repositório pertencem a `scripts/`.
- Padrões pessoais de Git pertencem a `git/config`.
- Comportamento de instalação e links pertence a `install.sh`; remoção segura pertence a `uninstall.sh`; diagnóstico do ambiente pertence a `bin/dotfiles-doctor`.
- Versões de SDK .NET específicas de projetos pertencem ao `global.json` de cada projeto.
- Ferramentas .NET específicas de projetos pertencem ao `.config/dotnet-tools.json` de cada projeto.
- Extensões de editor específicas de projetos pertencem ao `.vscode/extensions.json` de cada projeto.
- Secrets nunca pertencem a este repositório.

Não adicione `Directory.Build.props`, `Directory.Packages.props`, arquivos de projeto ou dependências NuGet a menos que este repositório passe a possuir explicitamente um componente baseado em MSBuild.

## Regras de mudança

- Prefira a menor alteração capaz de resolver o problema.
- Preserve a idempotência: executar `install.sh` repetidamente não pode duplicar configuração nem corromper o ambiente.
- Preserve a reversibilidade: `uninstall.sh` deve remover somente estado gerenciado pelo repositório e manter intactas configurações não relacionadas do usuário.
- Não substitua o `~/.bashrc` ou o `~/.gitconfig` completos do usuário.
- Preserve configurações injetadas pelo GitHub Codespaces e por outras ferramentas.
- Nunca execute o instalador ou desinstalador como `root`; execução privilegiada está fora do lifecycle suportado.
- Configure hooks Git localmente para este repositório; não defina um `core.hooksPath` global durante a instalação dos dotfiles.
- Helpers de atualização devem recusar reconciliação destrutiva: não faça reset, stash ou descarte automático de alterações locais.
- Coloque variáveis de shell entre aspas, exceto quando a expansão sem aspas for deliberada e segura.
- Evite comandos destrutivos sem validação rigorosa do alvo.
- Não instale globalmente SDKs, ferramentas, bancos ou serviços específicos de projetos.
- Não introduza secrets, tokens, URLs privadas, credenciais ou chaves privadas.
- Mantenha `bin/` versionado; neste repositório ele é código-fonte, não saída de build.
- Mantenha a documentação alinhada ao comportamento quando comandos, helpers, instalação ou convenções suportadas mudarem.
- Não reduza validações apenas para fazer uma mudança passar.
- Mantenha permissões do GitHub Actions mínimas e somente leitura, salvo quando uma capacidade de escrita for explicitamente necessária.
- Fixe GitHub Actions de terceiros por commit SHA completo; use Dependabot para manter esses pins.
- Preserve filtros de paths, cancelamento por concurrency e timeouts limitados, salvo quando existir requisito concreto para alterá-los.

## Validação obrigatória

Para mudanças relacionadas a shell, execute a partir da raiz quando o ambiente permitir:

```bash
bash scripts/validate-shell
bats tests
docker build --file Dockerfile.test --tag dotfiles-lifecycle-test .
```

`bash scripts/validate-shell` é o ponto de entrada compartilhado de validação estática utilizado pelos hooks locais do repositório e pelo CI. O hook de pre-commit pode usar `--allow-missing-tools` para que a sintaxe Bash continue sendo validada quando ShellCheck ou shfmt não estiverem instalados localmente; o CI deve exigir todas as ferramentas sem essa opção.

Os testes Bats são a baseline executável para comportamento de lifecycle, atualização e helpers .NET. Para mudanças em `install.sh`, mantenha a cobertura de idempotência provando que:

- o bloco gerenciado não é duplicado em `~/.bashrc`;
- o `include.path` do Git não é duplicado;
- o `core.hooksPath` local deste repositório aponta para `.githooks`;
- os links simbólicos continuam válidos;
- `~/.local/bin` não é duplicado no `PATH`.

O teste em container limpo deve continuar provando que instalação como root é recusada e que install, doctor, instalação repetida e uninstall funcionam para um usuário Linux normal.

Se uma validação não puder ser executada por limitação real do ambiente, relate a limitação em vez de reduzir a baseline.

## Skills

Use uma skill somente quando a descrição corresponder à tarefa:

- `.agents/skills/dotfiles-change/SKILL.md`: mudanças gerais envolvendo aliases, helpers, padrões Git ou comportamento de instalação;
- `.agents/skills/shell-hardening/SKILL.md`: segurança Bash, quoting, tratamento de erros, symlinks, paths e ShellCheck;
- `.agents/skills/codespaces-integration/SKILL.md`: ciclo de vida do GitHub Codespaces, instalação de dotfiles, configuração do usuário, PATH, limites da identidade Git e secrets.

As skills complementam este arquivo. Em caso de conflito, `AGENTS.md` e os arquivos reais do repositório prevalecem.

## Git e entrega

- Revise o diff antes de concluir.
- Evite formatação ou refatoração fora do escopo.
- Não adicione artefatos gerados ou arquivos temporários.
- Não faça push, crie releases ou altere administração do repositório sem solicitação explícita.
- Ao finalizar uma mudança, informe as validações executadas e qualquer risco ou bloqueio restante.
