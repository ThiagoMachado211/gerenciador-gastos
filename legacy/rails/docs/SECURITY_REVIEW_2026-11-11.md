# Revisão técnica e de segurança — 11/11/2026

> Registro da auditoria inicial. As correções e a validação posterior estão em [SECURITY_FIXES_2026-11-11.md](SECURITY_FIXES_2026-11-11.md).

## Resultado e limites

Há pendências de segurança que devem ser tratadas antes de exposição pública. A revisão abrangeu controllers, models, serviços, views, JavaScript próprio, rotas, schema, autenticação, configuração de produção, Docker, CI e testes existentes. Foram preservadas as alterações locais anteriores. Não foram alteradas regras de negócio nem versões de dependências.

Foi executada uma consulta de versões à API pública OSV: **127 pacotes únicos consultados (125 RubyGems e 2 npm), 19 dependências Ruby sinalizadas e 61 advisories distintos**. Não houve alerta para as duas versões npm consultadas. Isso não cobre todos os componentes JavaScript embutidos nas gems e não comprova ausência de vulnerabilidades. As versões das gems nativas foram normalizadas para a versão upstream, portanto alguns alertas exigem distinguir plataforma e biblioteca nativa utilizada.

Evidências: [resultado da consulta](security-dependencies-osv.json), [metadados dos advisories, faixas afetadas e referências](security-advisories-osv.json). Foram enviados somente nomes e versões das dependências. Alertas de versão não são 61 explorações confirmadas na aplicação.

**Não foi possível executar Rails, Brakeman, bundler-audit, importmap audit, RuboCop, testes HTTP ou build Docker.** Ruby e Bundler não estão no PATH do Windows e não foram encontrados no Ubuntu WSL; o daemon Docker está indisponível. Nenhum banco foi preparado ou modificado. Não houve pentest de ambiente publicado, teste de carga, confirmação de TLS/cookies em execução ou ensaio de backup. O resultado não constitui aprovação de segurança para produção.

## Achados por prioridade

### 1. Alta — dependências com avisos de segurança conhecidos

Evidência: `Gemfile.lock`, em especial actionpack 8.1.3, rack 3.2.6, nokogiri 1.19.2 e demais pacotes listados nos JSONs.

- **Rack / GHSA-5v64-555j-wjxm:** consumo não limitado de memória no parser multipart. Uma solicitação multipart pode alcançar o parser mesmo que a interface não ofereça upload. O advisory indica correção em 3.2.8 para a série 3.2. A exposição efetiva depende também dos limites de corpo e tempo do proxy e servidor; não foi reproduzida.
- **Action Pack / GHSA-2gff-2mmg-m73p:** falsificação de `request.remote_ip` quando o proxy deixa passar `Forwarded` do cliente e acrescenta `X-Forwarded-For`. O projeto usa Rails 8.1 e Rack 3; é necessário verificar o proxy real. Correção indicada em 8.1.4.1. Remover/sobrescrever cabeçalhos encaminhados não confiáveis também é necessário.
- **Rack / GHSA-2j8w-xcrc-x985:** tratamento de Host inválido; correção indicada em 3.2.8. Reforça a necessidade de validar hosts no aplicativo e no proxy.
- **Action Pack / GHSA-r9jg-fmfx-2gv6:** possível envenenamento de cache em negociação de conteúdo, corrigido na série 8.1 em 8.1.4.1; avaliar presença de cache compartilhado.

Referências primárias: [Rack multipart](https://github.com/rack/rack/security/advisories/GHSA-5v64-555j-wjxm), [Rails RemoteIp](https://github.com/rails/rails/security/advisories/GHSA-2gff-2mmg-m73p). As demais referências e versões corrigidas estão no arquivo de metadados.

**Triagem importante:** o alerta Devise GHSA-jp94-3292-c3xv exige `:timeoutable`, que não está habilitado em `app/models/user.rb`; não foi identificado caminho ativo para esse problema. Os alertas Puma sobre PROXY protocol dependem de configuração que não aparece em `config/puma.rb`. Os de Active Storage com GCS não correspondem ao storage local configurado; não foram encontrados modelos com anexos. Alertas Nokogiri específicos de JRuby não correspondem ao runtime MRI previsto. Action Mailbox/Mailgun e sessões CacheStore também exigem recursos/configurações não encontrados. Não ignorar os avisos automaticamente: documentar cada exceção com base no deployment efetivo.

Recomendação: atualizar as dependências com Bundler em ambiente compatível, mantendo os componentes Rails alinhados, e repetir a auditoria e a suíte completa. As versões acima são correções dos avisos destacados, não garantia de resolver todos os 61 alertas. Não editar o lockfile manualmente nem adicionar uma lista ampla de exceções.

### 2. Média — recuperação de senha permite distinguir contas existentes

Evidência: `config/initializers/devise.rb:93` deixa `config.paranoid` comentado; o controller de recuperação herda o fluxo padrão. A resposta para um e-mail inexistente pode diferir daquela de uma conta cadastrada. Login também pode revelar estados de bloqueio.

Impacto: enumeração de clientes para phishing e tentativas dirigidas de acesso. Ativar `config.paranoid = true`, revisar mensagens e comparar status/redirecionamento/conteúdo para contas existentes e inexistentes. Cadastro tem tratamento próprio e não é coberto integralmente por essa opção. A diferença de respostas foi inferida da configuração e do comportamento documentado do Devise, sem execução HTTP local.

### 3. Média — ausência de limitação de requisições na aplicação

Não foram encontrados `rate_limit`, Rack::Attack ou controle equivalente para cadastro, login e recuperação. `:lockable` restringe dez falhas por conta por trinta minutos, mas não limita IPs, cadastros, tentativas distribuídas entre contas ou envio repetido de e-mail. O envio SMTP é síncrono.

Impacto: abuso de e-mail, custo de bcrypt/SMTP, criação de contas em massa e bloqueio deliberado de contas conhecidas. Aplicar limites por endpoint e identificador/IP, com armazenamento compartilhado entre processos, verificar os cabeçalhos do proxy e limitar tamanho/tempo de solicitações. Limites no proxy podem existir externamente; não foram verificados.

### 4. Média — senhas comuns podem ter somente seis caracteres

Evidência: `config/initializers/devise.rb:184`, `config.password_length = 6..128`. As regras fortes do model valem apenas para administradores. Não há MFA implementado no projeto.

Impacto: credenciais fracas para contas que contêm dados financeiros. Aumentar o mínimo e considerar bloqueio de senhas comuns/comprometidas; validar a política no cadastro, alteração e recuperação. Revisar também o tratamento em bytes de senhas longas no bcrypt e na versão instalada do Devise. Aumentar o mínimo não fortalece retroativamente senhas já gravadas.

### 5. Média — limites do plano podem ser ultrapassados por concorrência

Evidência: `app/services/plans/usage_checker.rb` faz `count`; `Users::CategoriesController#create` e `Users::CreditCardsController#create` salvam em uma operação posterior, sem lock/transação envolvendo a decisão.

Reprodução prevista: com três categorias, disparar duas criações simultâneas; ambas podem observar três e produzir cinco. O mesmo ocorre com dois primeiros cartões simultâneos. Os testes existentes verificam somente chamadas sequenciais.

Recomendação: serializar a verificação e criação usando lock da conta em uma transação, em todos os caminhos de criação. Confirmar com teste usando conexões independentes. Falha identificada por análise do fluxo; concorrência não reproduzida neste ambiente.

### 6. Média — entradas extremas e referências inexistentes podem gerar erro 500

Evidência: `Transaction#category_belongs_to_user` e `#credit_card_belongs_to_user` retornam quando a associação é vazia; ambas são opcionais. Um ID preenchido mas inexistente pode passar pela validação e atingir a foreign key no banco. `amount_cents` e `limit_cents` são integer de 32 bits no schema, com validação de mínimo mas sem máximo correspondente.

Casos a executar: enviar `category_id`/`credit_card_id` inexistentes e valores em centavos maiores que 2147483647. Esperado após correção: erro de formulário 422, sem escrita; risco atual: `InvalidForeignKey`/`RangeError`. A classificação é uma hipótese fundamentada no código, pendente de execução com Active Record e PostgreSQL.

Recomendação: validar a existência de associações quando o ID estiver preenchido e limitar os números ao domínio do negócio/banco, ou migrar para bigint se necessário. Não ocultar erros de banco com rescue genérico.

### 7. Baixa — faltam camadas adicionais de proteção no navegador e no host

- `config/initializers/content_security_policy.rb` está totalmente comentado. `csp_meta_tag` nos layouts não ativa uma política sozinho. Definir uma CSP compatível com importmap/nonces e testar os gráficos, Turbo e estilos existentes.
- `config/environments/production.rb` não define hosts permitidos. Usar APP_HOST como host autorizado, com exceção restrita ao healthcheck quando necessário. Isso reduz a superfície de ataques com Host, embora o roteamento externo possa já restringi-lo. Referência: [configuração oficial do Rails](https://guides.rubyonrails.org/configuring.html#actiondispatch-hostauthorization).
- `Admin::BaseController` envia `Cache-Control: no-store`, mas `Users::BaseController` não aplica a mesma política às páginas financeiras. Conferir cache, navegação e histórico após logout no navegador real.

Esses itens são reforços de defesa; não comprovam XSS, vazamento de cache ou exploração por Host no ambiente publicado.

## Outras falhas e desempenho

- `config/routes.rb` declara `resources` completos para categorias, cartões e transações, incluindo `show`, mas os três controllers não implementam essa ação. Restringir às ações existentes ou implementar a página. Acesso GET ao item individual pode resultar em ActionNotFound/404; não é acesso autorizado a dados de terceiros.
- `Users::TransactionsController#index` carrega todo o histórico, sem paginação. Crescimento da conta aumenta memória, tamanho do HTML e tempo de resposta. Paginar a lista mantendo os totais calculados na relação completa.
- `Users::DashboardController#load_year_summary` faz 24 consultas de soma na iteração dos meses, além das consultas de totais. Agrupar por mês e tipo reduz trabalho por requisição.
- `User#name` e os campos de categoria não têm limites de comprimento no model. Limitar esses campos reduz armazenamento e processamento de conteúdo exagerado.
- O job `system-test` existe no CI, mas não há diretório `test/system`; portanto ele não demonstra cobertura de navegação em navegador. Os testes de integração existentes são úteis, mas não verificam a execução real de JavaScript, cookies e CSP.
- O helper de testes usa `ENV["RAILS_ENV"] ||= "test"`; ele não força teste se outro ambiente já estiver definido. Manter execução explicitamente em teste e acrescentar guarda de ambiente/banco antes de qualquer carga de fixtures. Nenhuma carga foi realizada nesta revisão.

## Controles positivos encontrados no código

- Controllers privados exigem autenticação; administração verifica `current_user.admin?`.
- Busca e alteração de recursos usam as associações de `current_user`; parâmetros permitidos não incluem `admin` nem `user_id`.
- Transações verificam que categoria e cartão existentes pertencem ao proprietário.
- Views inspecionadas usam escaping ERB; JSON de gráficos é colocado em atributos escapados. Não foram encontrados `html_safe`, `raw`, SQL interpolado com entradas ou execução de comandos com dados do usuário nos caminhos revisados.
- Não há rota ativa de webhook/cobrança Stripe. Não foi encontrado bypass de CSRF no código próprio.
- Produção força HTTPS; imagem usa usuário sem privilégios; `.env`, chaves locais e credenciais administrativas são excluídos do contexto Docker. A checagem de arquivos rastreados não encontrou `.env` ou master key; isso não é varredura completa de segredos no histórico Git.
- Existem testes para bloqueio de login, escalada administrativa, isolamento entre contas e recuperação de senha. A presença desses testes foi revisada; sua aprovação não foi confirmada nesta execução.

## Testes acrescentados e próxima execução

Adicionados sete cenários em `test/integration/security_regression_test.rb`: leitura e criação anônimas, leitura de formulário de outra conta, falsificação de proprietário, troca por associações de terceiros sem persistir alterações, XSS armazenado e escrita sem token CSRF. O cenário CSRF habilita explicitamente a proteção, normalmente desativada em teste, e restaura a configuração ao terminar.

**Os novos testes ainda não foram executados.** Não representam confirmação dos controles. Rodar em um ambiente com Ruby 3.4.9, dependências instaladas e PostgreSQL exclusivo de teste. Garantir que DATABASE_URL não aponte para produção. No Windows, usar `ruby` antes dos binários:

```powershell
$env:RAILS_ENV = 'test'
ruby bin/rails db:test:prepare
ruby bin/rails test test/integration/security_regression_test.rb
ruby bin/rails test
ruby bin/rails zeitwerk:check
ruby bin/brakeman --no-pager
ruby bin/bundler-audit check --update
ruby bin/importmap audit
ruby bin/rubocop
```

Depois de corrigir os achados, repetir a consulta de dependências, executar testes de concorrência/entradas inválidas e validar HTTPS, cabeçalhos, sessão, logout e recuperação de senha em homologação. Priorizar atualização de dependências, proteção contra abuso e enumeração; depois concorrência, validações de entrada e reforços de configuração.
