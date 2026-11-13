# Fluxo — gerenciador de gastos

Backend em **Python / Django**. Frontend em **HTML, CSS e JavaScript**, sem Ruby, React, Node ou etapa de compilação. As páginas HTML usam templates Django para apresentar os dados e proteger formulários com CSRF.

## Executar no Windows

Instale Python 3.12 ou superior. No PowerShell, na raiz do projeto:

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe manage.py migrate
.\.venv\Scripts\python.exe manage.py runserver
```

Abra http://127.0.0.1:8000. Neste ambiente já foi criado um ambiente virtual `.venv`.

No Linux/macOS, use `python3 -m venv .venv` e `.venv/bin/python` nos comandos seguintes.

## Estrutura

- `backend/`: configuração, modelos, formulários, autenticação, rotas, testes e comandos Python.
- `frontend/templates/`: páginas HTML.
- `frontend/static/css/`: estilos responsivos.
- `frontend/static/js/`: JavaScript e Chart.js local, preservado do projeto original.
- `storage/`: SQLite local, excluído do Git.
- `legacy/rails/`: código anterior completo, inclusive alterações locais existentes, preservado como referência. A aplicação Python não utiliza esses arquivos. A configuração Kamal antiga está nessa pasta e não publica a versão Python.

## Funcionalidades

Cadastro, login, logout, recuperação de senha, edição de nome, troca de senha e exclusão de conta; painel mensal/anual com gráfico; CRUD de transações, categorias e cartões; administração com lista paginada. O plano gratuito permite 4 categorias, 1 cartão e transações ilimitadas. Pagamentos continuam desativados. Valores são informados em **centavos** (12550 = R$ 125,50); parcelas são registradas como metadado, conforme a aplicação anterior.

O layout foi refeito em HTML/CSS preservando a identidade escura e verde do Fluxo. Não é uma conversão visual idêntica dos templates ERB.

Recuperação de senha: em desenvolvimento o e-mail aparece no terminal. Em produção configure SMTP. Novas senhas exigem 12 caracteres. Há bloqueio após 5 erros de login e limitação de requisições persistida no banco. Em produção, configure também limites de conexão no proxy.

## Administrador

```powershell
.\.venv\Scripts\python.exe manage.py create_admin
```

Informe e-mail e senha no prompt. A senha exige 32 caracteres com maiúsculas, minúsculas, números e símbolos. Contas existentes não são promovidas ou sobrescritas. Entre normalmente e acesse `/admin`. Não use `createsuperuser`, que permite ignorar avisos de validação interativamente.

## Importar os dados Rails

A conversão do código **não migra automaticamente o banco existente**. Faça backup antes de importar. Crie um banco PostgreSQL novo para o Python e execute `migrate`. Exporte `DATABASE_URL` para o destino e `RAILS_DATABASE_URL` para a origem, usando nomes de bancos diferentes. Depois execute:

```powershell
.\.venv\Scripts\python.exe manage.py import_rails
```

O comando exige destino sem usuários e lê a origem em transação PostgreSQL somente leitura. Importa contas, senhas bcrypt Devise, perfis administrativos, categorias, cartões e transações; os IDs são remapeados. Uma falha reverte toda a importação no destino. Sessões e links de recuperação antigos são invalidados. Contas sem hash bcrypt válido precisam recuperar a senha. A importação deve ocorrer com a aplicação antiga parada para não perder alterações posteriores à cópia. Não houve acesso nem alteração ao banco anterior durante a conversão.

## Testes

```powershell
.\.venv\Scripts\python.exe manage.py check
.\.venv\Scripts\python.exe manage.py test backend.finance
.\.venv\Scripts\python.exe manage.py makemigrations --check --dry-run
```

O runner cria um banco de teste separado. Os testes não importam nem modificam o banco Rails.

## Produção / Docker

Exporte as variáveis listadas em `.env.example`; Django não carrega esse arquivo automaticamente. Use `DEBUG=false`, `SECRET_KEY` aleatória, `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`, `DATABASE_URL` PostgreSQL e SMTP. Use HTTPS com proxy preservando o Host; o app não confia em cabeçalhos encaminhados arbitrários. Se TLS terminar no proxy, faça uma configuração explícita e confiável de `SECURE_PROXY_SSL_HEADER` antes de publicar, evitando redirecionamentos em ciclo.

```sh
docker build -t fluxo-python .
# Execute migrate uma vez com as mesmas variáveis e banco do serviço:
docker run --rm --env-file .env fluxo-python python manage.py migrate
docker run --rm --env-file .env -p 8000:8000 fluxo-python
```

Use PostgreSQL em produção. O Docker não executa migrações automaticamente. A imagem usa Waitress, arquivos estáticos locais via WhiteNoise e usuário sem privilégios. Faça backups regulares do PostgreSQL. SQLite é o padrão para desenvolvimento. Os relatórios de segurança anteriores em `legacy/rails/docs` referem-se à versão Rails.
