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
5. `git/config`;
6. `.editorconfig`, `.gitattributes` e `.gitignore`;
7. testes em `tests/`;
8. workflows que realmente existem em `.github/workflows/`;
9. `.github/dependabot.yml` para manutenção automatizada das dependências do GitHub Actions;
10. `.agents/skills/` para tarefas especializadas.

Não assuma que uma ferramenta, workflow, serviço, secret ou dependência existe sem que esteja presente no repositório ou seja fornecida explicitamente pelo ambiente.

## Limites do repositório

- Preferências pessoais de shell e aliases pertencem a `shell/`.
- Pequenos helpers executáveis pertencem a `bin/`.
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

Para mudanças em scripts de shell, execute a partir da raiz quando o ambiente permitir:

```bash
bash -n install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shellcheck install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shfmt -d -i 2 install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
bats tests
```

Os testes Bats são a baseline executável para comportamento de lifecycle e helpers .NET. Para mudanças em `install.sh`, mantenha a cobertura de idempotência provando que:

- o bloco gerenciado não é duplicado em `~/.bashrc`;
- o `include.path` do Git não é duplicado;
- os links simbólicos continuam válidos;
- `~/.local/bin` não é duplicado no `PATH`.

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
