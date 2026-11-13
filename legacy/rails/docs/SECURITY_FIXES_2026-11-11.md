# Correções e validação — 11/11/2026

## Alterações implementadas

- Dependências atualizadas pelo Bundler, preservando as plataformas Windows e Linux no lockfile. Incluem Rails 8.1.4.1, Rack 3.2.8, Devise 5.0.4, Nokogiri 1.19.7, Puma 8.0.2 e atualizações transitivas. O Gemfile também exige os patches mínimos de Rails e Devise.
- Recuperação de senha com `Devise.paranoid`, respostas públicas uniformes e mínimo de 12 caracteres para novas senhas e redefinições. Senhas existentes não são alteradas automaticamente.
- Limites de autenticação gravados no PostgreSQL, com incremento atômico, expiração e limpeza de contadores antigos. Cadastro: 5 solicitações/IP/hora; login: 30/IP e 10/e-mail a cada 15 minutos; recuperação e redefinição: 10/IP e, quando informado, 3/e-mail a cada 15 minutos. O excesso retorna 429 e Retry-After. E-mails e IPs são usados em chaves SHA-256, sem persistir seus valores em texto na tabela.
- Limites gratuitos de categorias e cartões verificados e gravados dentro da mesma transação com lock da conta. Dois pedidos simultâneos não excedem o limite. Todos os caminhos HTTP atuais de criação usam esse controle.
- Referências inexistentes de categorias/cartões rejeitadas pelo model, assim como vínculos de terceiros. Valores em centavos limitados à capacidade dos campos integer atuais. Nome do usuário e campos de categoria limitados; cores opcionais aceitam hexadecimal de seis dígitos.
- CSP ativa, scripts com nonce aleatório por resposta, objetos bloqueados, restrições de base/formulário e frame-ancestors. Estilos inline permanecem permitidos para compatibilidade com Chart.js e barras existentes; não há liberação de scripts inline sem nonce.
- Hosts de produção restritos a APP_HOST, com exceção do healthcheck. Cabeçalhos RFC 7239 Forwarded ignorados; o proxy confiável deve fornecer X-Forwarded-For corretamente. Páginas financeiras e de autenticação recebem Cache-Control: no-store.
- Rotas show inexistentes removidas. Histórico de transações paginado em 25 itens, preservando os totais sobre todo o histórico e limitando o número da página. Resumo anual agrupado por mês/tipo em uma consulta, substituindo as 24 somas mensais.
- Guarda de testes exige RAILS_ENV=test e nome do banco terminado em _test antes de carregar fixtures. Serviços incluídos no carregamento completo. Binstubs portáveis, finais de linha LF e execução/permissões de scripts ajustadas no CI.
- Acrescentados testes para abuso de autenticação, expiração dos limites, concorrência em conexões independentes, referências inválidas, valores extremos, CSRF, XSS, isolamento entre contas, paginação, nonces e navegação real em Chrome. Testes de isolamento usam sessões reais de login para verificar acesso após respostas 404.

## Validação executada

Ambiente local: Ubuntu WSL, Ruby 3.3.8 e PostgreSQL 18. Banco exclusivo `gerenciador_gastos_security_test`, criado para esta tarefa; bancos de desenvolvimento e produção não foram utilizados. O projeto e o Docker continuam configurados para Ruby 3.4.9; essa versão específica e a imagem Docker ainda precisam da execução do CI/build no ambiente correspondente.

- Suíte Rails: 72 testes, 308 assertions, sem falhas ou erros.
- Navegador Chrome headless: 1 teste, 5 assertions, sem falhas ou erros. Login, gráficos com JavaScript/CSP e logout verificados.
- Brakeman 8.1.0: zero alertas de segurança e nenhum erro de análise.
- bundler-audit com base atualizada: nenhuma vulnerabilidade encontrada.
- importmap audit: nenhum pacote vulnerável encontrado. A ferramenta não audita separadamente o alias local chartjs-helpers, que é um trecho do Chart.js 4.5.1; a versão do Chart.js foi consultada também na OSV.
- OSV após atualização: 125 pacotes consultados, zero pacotes sinalizados. [Consulta com as versões verificadas](security-dependencies-osv-after.json). O total mudou em relação à auditoria inicial porque a resolução atual removeu dependências transitivas.
- RuboCop: sem infrações.
- Zeitwerk: carregamento completo verificado.
- Assets de produção: compilação concluída sem serviços de produção ou chave real.
- Verificação local em configuração de produção: Host não autorizado retornou 403; APP_HOST válido e /up retornaram 200; CSP presente.

Os arquivos `security-dependencies-osv.json`, `security-advisories-osv.json` e `SECURITY_REVIEW_2026-11-11.md` preservam o diagnóstico anterior às correções. Seus alertas não representam o estado atual do lockfile.

## Aplicar a atualização

Instale as dependências do novo lockfile e execute `ruby bin/rails db:migrate` no ambiente de destino antes de iniciar o servidor. A migração cria `request_rate_limits`; não requer Redis nem outro serviço. Mantenha backup antes de atualizar o banco existente.

Configure APP_HOST com o domínio público e faça o proxy remover/sobrescrever cabeçalhos enviados pelo cliente, acrescentando o IP real a X-Forwarded-For. Limites de tamanho de corpo, tempo de requisição, HTTPS externo, backups e entrega real de SMTP continuam dependendo da infraestrutura. Não houve publicação ou pentest externo.

Os testes da aplicação podem ser repetidos com `RAILS_ENV=test bundle exec rails test` e `RAILS_ENV=test bundle exec rails test:system`, usando somente banco dedicado terminado em _test. Execute `bundle exec rubocop`, `bundle exec brakeman --no-pager`, `ruby bin/bundler-audit check --update` e `ruby bin/importmap audit` para repetir as verificações estáticas e de dependências.
