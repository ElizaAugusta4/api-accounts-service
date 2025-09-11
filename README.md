# api-accounts-service

Este serviço é responsável pelo gerenciamento de contas bancárias. Ele faz parte de um sistema distribuído, utilizando FastAPI, SQLAlchemy e MySQL.

## Funcionalidades

- Criar contas bancárias
- Listar todas as contas
- Buscar conta por ID

## Como rodar localmente

1. **Pré-requisitos:**
	- Python 3.11+
	- MySQL rodando (local ou em container)
	- Docker (opcional)
	- Kubernetes (opcional para deploy)

2. **Instalação das dependências:**
	```bash
	pip install -r requirements.txt
	```

3. **Variáveis de ambiente necessárias:**
	- `MYSQL_HOST`: Endereço do banco MySQL (ex: `localhost` ou `mysql` no K8s)
	- `MYSQL_PORT`: Porta do MySQL (padrão: `3306`)
	- `MYSQL_USER`: Usuário do banco
	- `MYSQL_PASSWORD`: Senha do banco
	- `MYSQL_DATABASE`: Nome do banco (ex: `accounts_db`)

4. **Rodando a API:**
	```bash
	uvicorn app:app --host 0.0.0.0 --port 8000
	```

## Deploy com Docker

```bash
docker build -t accounts-service .
docker run -e MYSQL_HOST=... -e MYSQL_USER=... -e MYSQL_PASSWORD=... -e MYSQL_DATABASE=... -p 8000:8000 accounts-service
```

## Deploy no Kubernetes

- Certifique-se de criar o secret `mysql-secret` com as chaves `MYSQL_USER` e `MYSQL_PASSWORD`.
- Aplique os manifestos do diretório `K8s-manifests/`:
  ```bash
  kubectl apply -f K8s-manifests/
  ```

## Testes

```bash
pytest test_app.py
```

## Health Check

Após o deploy, acesse `/health` para verificar se o serviço está rodando.