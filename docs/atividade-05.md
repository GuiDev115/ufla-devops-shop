# Atividade 5 — Guilherme Fabricio (@GuiDev115)

## Stack

| Serviço | Imagem                                        | Porta publicada          |
|---------|-----------------------------------------------|--------------------------|
| api     | `ghcr.io/guidev115/ufla-devops-shop:1.0.0`   | —                        |
| banco   | `postgres:16-alpine`                          | —                        |
| cache   | `redis:7-alpine`                              | —                        |
| nginx   | `nginx:alpine`                                | 8080 → 80                |

## 1. Subir a stack

```bash
cp .env.example .env
# edite .env e defina POSTGRES_PASSWORD
docker compose up -d
```

## 2. Status dos serviços

```
$ docker compose ps
NAME                       IMAGE                                       COMMAND                  SERVICE   CREATED          STATUS                    PORTS
ufla-devops-shop-api-1     ghcr.io/guidev115/ufla-devops-shop:1.0.0   "uvicorn app:api --h…"   api       54 seconds ago   Up 47 seconds (healthy)   8000/tcp
ufla-devops-shop-banco-1   postgres:16-alpine                         "docker-entrypoint.s…"   banco     57 seconds ago   Up 53 seconds (healthy)   5432/tcp
ufla-devops-shop-cache-1   redis:7-alpine                             "docker-entrypoint.s…"   cache     57 seconds ago   Up 53 seconds             6379/tcp
ufla-devops-shop-nginx-1   nginx:alpine                               "/docker-entrypoint.…"   nginx     53 seconds ago   Up 47 seconds             0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
```

## 3. Endpoint de readiness (banco + cache)

```
$ curl -s localhost:8080/ready
{"status":"ok","banco":"ok","cache":"ok"}
```

## 4. Persistência de dados após restart

```
# Catálogo inicial carregado pelo banco
$ curl -s localhost:8080/api/produtos | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d),'produtos')"
12 produtos

# Criar produto extra
$ curl -s -X POST localhost:8080/api/produtos \
    -H "Content-Type: application/json" \
    -d '{"nome":"Persistencia Test","descricao":"volume nomeado","preco":9.99,"estoque":5}'
{"id":13,"nome":"Persistencia Test","descricao":"volume nomeado","preco":9.99,"estoque":5,"criado_em":"2026-10-19T22:43:08.376757+00:00"}

# Derrubar a stack
$ docker compose down
[+] down 5/5
 ✔ Container ufla-devops-shop-cache-1 Removed
 ✔ Container ufla-devops-shop-nginx-1 Removed
 ✔ Container ufla-devops-shop-api-1   Removed
 ✔ Container ufla-devops-shop-banco-1 Removed
 ✔ Network ufla-devops-shop_default   Removed

# Subir de novo
$ docker compose up -d
[+] up 5/5
 ✔ Network ufla-devops-shop_default   Created
 ✔ Container ufla-devops-shop-cache-1 Started
 ✔ Container ufla-devops-shop-banco-1 Healthy
 ✔ Container ufla-devops-shop-api-1   Started
 ✔ Container ufla-devops-shop-nginx-1 Started

# 13 produtos: os 12 originais + o criado antes do down
$ curl -s localhost:8080/api/produtos | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d),'produtos')"
13 produtos

# O produto criado antes do down ainda existe (volume nomeado preservou os dados)
$ curl -s localhost:8080/api/produtos/13
{"id":13,"nome":"Persistencia Test","descricao":"volume nomeado","preco":9.99,"estoque":5,"criado_em":"2026-10-19T22:43:08.376757+00:00"}
```

## 5. Nenhuma porta interna exposta além do nginx

```
$ docker compose ps --format 'table {{.Name}}\t{{.Ports}}'
NAME                       PORTS
ufla-devops-shop-api-1     8000/tcp
ufla-devops-shop-banco-1   5432/tcp
ufla-devops-shop-cache-1   6379/tcp
ufla-devops-shop-nginx-1   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
```

api, banco e cache não publicam portas no host — todo o tráfego externo passa pelo nginx.

## 6. Volume nomeado

```
$ docker volume ls | grep dados_banco
local     ufla-devops-shop_dados_banco
```
