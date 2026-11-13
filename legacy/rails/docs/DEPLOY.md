# Publicação do Fluxo

## Escopo desta versão

Somente o plano gratuito está disponível. Não há checkout, assinatura persistida, cobrança ou webhook Stripe. As operações de upgrade/cancelamento foram retiradas das rotas para impedir confirmações de ações inexistentes. A integração paga permanece um projeto separado e precisa de checkout, assinatura, eventos verificados e idempotentes, cancelamento, liberação de limites e testes antes de ser ativada.

## Preparação externa

- Servidor Linux acessível via SSH, com Docker e portas 80/443 abertas; DNS do domínio apontando para o servidor.
- PostgreSQL persistente, acessível pelo contêiner, com banco exclusivo e credenciais de produção. Configure TLS conforme o provedor; localhost dentro do contêiner não é o computador hospedeiro.
- Registro de imagens com credencial de publicação, por exemplo GHCR.
- Serviço SMTP com STARTTLS na porta 587, remetente autorizado e configuração DNS de envio conforme o provedor.
- Guarde a chave Rails que corresponde a config/credentials.yml.enc em um gerenciador de segredos. Não gere outra chave para tentar abrir o arquivo existente.

## Variáveis

Exporte na sessão que executa Kamal: DEPLOY_HOST (IP/host SSH), APP_HOST (domínio sem protocolo ou caminho), KAMAL_IMAGE (namespace/imagem), KAMAL_REGISTRY_SERVER (padrão ghcr.io), KAMAL_REGISTRY_USERNAME, KAMAL_REGISTRY_PASSWORD, RAILS_MASTER_KEY, DATABASE_URL, MAIL_FROM, SMTP_ADDRESS, SMTP_USERNAME e SMTP_PASSWORD. SMTP_PORT tem padrão 587 e SMTP_AUTHENTICATION tem padrão plain.

Use .env.example como referência. Dotenv não carrega arquivos .env em produção e Kamal precisa dessas variáveis no ambiente do processo. .kamal/secrets apenas referencia segredos exportados; não contém valores reais. A aplicação falha ao iniciar se faltarem as variáveis essenciais e mostra apenas os nomes ausentes.

Kamal habilita HTTPS automático e ASSUME_SSL=true porque termina TLS no proxy. Em outra plataforma, preserve HTTPS e use ASSUME_SSL=true apenas atrás de um proxy confiável que termine TLS. O endpoint /up aceita a verificação HTTP interna sem redirecionamento e verifica inicialização da aplicação, não disponibilidade do banco.

## Publicar e validar

1. Execute os testes e verificações do README; não prossiga enquanto houver falhas.
2. Faça backup do banco existente antes de qualquer atualização.
3. Com as variáveis exportadas e acesso SSH configurado, execute bundle exec kamal setup na primeira publicação. Nas seguintes use bundle exec kamal deploy.
4. O contêiner executa db:prepare antes de iniciar o servidor; confirme nos logs a conclusão das migrações.
5. Confira https://SEU_DOMINIO/up e a página inicial. Valide cadastro, login, logout e recuperação de senha com um e-mail real.
6. Crie categoria, cartão e transação. Confira os limites gratuitos e que outra conta não vê nem altera esses dados. Exclua uma categoria utilizada e confirme que a transação permanece.
7. Confirme que nenhuma interface ou rota permite compra/cancelamento de plano pago.

Os jobs usam o adaptador inline: executam no processo da solicitação. Não é necessário Solid Queue nem processo worker nesta versão. Antes de adicionar trabalhos longos ou que precisem de repetição, configure uma fila persistente e um worker.

## Backup, recuperação e observabilidade

Ative backups automáticos diários do PostgreSQL em armazenamento separado do servidor. Defina retenção, responsável e alertas de falha. Para backup manual em uma máquina de operação com PostgreSQL client e DATABASE_URL exportada:

```sh
pg_dump --format=custom --file=fluxo-backup.dump "$DATABASE_URL"
```

Proteja o arquivo e copie-o para armazenamento externo. Se passar a usar uploads, inclua também o volume gerenciador_gastos_storage. Não salve backups nem segredos no Git.

Teste a restauração em um banco vazio, separado de produção, usando uma RESTORE_DATABASE_URL exportada que aponte para esse banco:

```sh
pg_restore --no-owner --no-acl --dbname="$RESTORE_DATABASE_URL" fluxo-backup.dump
```

Aponte uma instância isolada da aplicação para o banco restaurado e valide contas, saldos e transações. Registre a data e o resultado do ensaio. A rotina de backup só está pronta após esse teste.

Configure monitor externo para HTTPS /up e alertas de erros, falhas de e-mail, disco e banco. Rails envia logs para stdout; Kamal oferece bundle exec kamal app logs.

Se a nova versão falhar, use bundle exec kamal rollback VERSAO_ANTERIOR. Rollback de imagem não desfaz migrações nem restaura dados: confirme compatibilidade do schema antes. Para mudanças incompatíveis, restaure o backup em uma instância separada e planeje a troca considerando os dados gravados após o backup.

## Pendências que dependem do operador

Servidor/domínio, credenciais reais, banco provisionado, SMTP/DNS, execução dos testes, construção da imagem, ensaio de restauração e validação em homologação precisam estar concluídos antes de abrir ao público. Este documento não confirma que esses serviços já existem ou funcionam.
