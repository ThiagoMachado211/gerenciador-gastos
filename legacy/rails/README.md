# Fluxo — gerenciador de gastos

Aplicação Rails 8.1.4.1, Ruby 3.4.9 e PostgreSQL. Esta versão oferece o plano gratuito. Pagamentos e assinaturas ainda não estão implementados; as rotas de cobrança estão desativadas.

## Desenvolvimento e testes

1. Instale a versão de Ruby de `.ruby-version`, Bundler e PostgreSQL.
2. Copie `.env.example` para `.env` e preencha `DB_PASSWORD` para o PostgreSQL local (usuário postgres, porta 5432).
3. Execute `bundle install` e `bin/rails db:prepare`.
4. Inicie com `bin/rails server`.

No Windows, execute os binários Ruby com `ruby bin/rails` ou use Linux/WSL.

Verificações antes de publicar:

```sh
RAILS_ENV=test bin/rails db:test:prepare test
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
docker build -t gerenciador-gastos .
```

Os testes usam exclusivamente o banco de teste. Nunca use uma DATABASE_URL de produção para testes, db:reset ou db:seed:replant. O CI também roda em pushes para main.

## Produção

Veja [docs/DEPLOY.md](docs/DEPLOY.md) para ambiente, publicação, validação, backups e recuperação.

## Administração

O painel fica em `/admin`. Siga [docs/ADMIN.md](docs/ADMIN.md) para criar a conta com credenciais locais excluídas do Git e do Docker. Execute a migração antes de iniciar esta versão.

## Correções de segurança de 11/11/2026

Veja [docs/SECURITY_FIXES_2026-11-11.md](docs/SECURITY_FIXES_2026-11-11.md) para as correções e os resultados dos testes.
Depois de atualizar as dependências, execute `ruby bin/rails db:migrate` antes de iniciar a aplicação. A nova tabela `request_rate_limits` mantém os limites de autenticação compartilhados entre processos; ela usa o PostgreSQL existente.
Novas senhas e redefinições exigem pelo menos 12 caracteres. Em produção, `APP_HOST` deve corresponder ao domínio público, e o proxy deve sobrescrever cabeçalhos encaminhados pelo cliente e acrescentar o endereço real a `X-Forwarded-For`.
Os testes recusam ambientes diferentes de `test` e bancos cujo nome não termine em `_test`. Os testes de navegador exigem Chrome/Chromium e suas bibliotecas locais.
