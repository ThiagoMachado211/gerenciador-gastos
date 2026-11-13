# Acesso administrativo

O painel fica em /admin e usa o mesmo formulário de login da plataforma. Usuários comuns recebem HTTP 403. Somente contas com admin=true acessam o resumo e a lista paginada de usuários. O painel consulta dados cadastrais; não expõe senhas, tokens ou transações financeiras individuais.

## Credenciais locais

Um identificador aleatório e uma senha aleatória de 52 caracteres foram gerados em .admin/credentials.json na raiz do projeto. Esse diretório é ignorado pelo Git e pelo Docker. A senha nunca foi colocada no código ou neste documento. A aplicação guarda somente o hash do Devise no banco.

O identificador gerado termina em .invalid: serve para login e não recebe e-mails. Para recuperação de senha por e-mail em produção, use um endereço sob seu controle ao provisionar o administrador. Guarde a senha em um gerenciador de senhas. Gitignore impede novas inclusões normais, mas não cifra arquivos nem remove conteúdo já versionado; não use git add -f nesse diretório.

## Ativar no banco desejado

Com Ruby, dependências e PostgreSQL disponíveis, execute na raiz do projeto:

```sh
bin/rails db:migrate
bin/rails admin:create
```

No Windows com Ruby instalado, use ruby bin/rails. A tarefa lê o arquivo local, cria a conta e não imprime as credenciais. Não promove uma conta pública existente e não redefine uma senha já cadastrada. Repetir com o mesmo e-mail encerra sem alterações. A conta não é criada automaticamente no cadastro público ou a cada deploy.

Na produção, forneça ADMIN_EMAIL e ADMIN_PASSWORD na sessão protegida que executar RAILS_ENV=production bin/rails admin:create. A senha deve ter 32–128 caracteres, com maiúsculas, minúsculas, números e símbolos. Não inclua o arquivo local na imagem e não coloque a senha na linha de comando ou no histórico. Remova as variáveis da sessão após o provisionamento.

Faça login com o e-mail e a senha e acesse /admin. Administradores são direcionados para o painel após entrar. O link Administração aparece apenas para administradores. Não há credencial padrão, botão público de promoção, nem parâmetro de cadastro que conceda acesso admin.

## Proteções e validação

Senhas de administradores também precisam manter a exigência mínima de 32 caracteres em alterações e recuperação de senha. Há bloqueio persistido no banco após dez tentativas de senha incorreta, com desbloqueio automático após 30 minutos. HTTPS deve estar ativo em produção. A listagem administrativa recebe Cache-Control: no-store.

Execute os testes de admin e o fluxo completo antes de publicar. A criação da conta só está concluída depois que db:migrate e admin:create executarem com sucesso no banco correto. A geração do arquivo de credenciais, por si só, não cria a conta.

Referências: https://github.com/heartcombo/devise e https://www.chartjs.org/docs/latest/getting-started/integration.html
