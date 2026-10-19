# Atividade 5 — Guilherme Fabricio (@GuiDev115)

## Stack

| Serviço | Imagem                                        | Porta publicada |
|---------|-----------------------------------------------|-----------------|
| api     | `ghcr.io/guidev115/ufla-devops-shop:1.0.0`   | —               |
| banco   | `postgres:16-alpine`                          | —               |
| cache   | `redis:7-alpine`                              | —               |
| nginx   | `nginx:alpine`                                | 8080 → 80       |

## 1. Subir a stack

```bash
cp .env.example .env
# edite .env e defina uma senha real para POSTGRES_PASSWORD
docker compose up -d
```

## 2. Verificar saúde dos serviços

```
$ docker compose ps
NAME                        IMAGE                                        COMMAND                  SERVICE   CREATED          STATUS                    PORTS
ufla-devops-shop-api-1      ghcr.io/guidev115/ufla-devops-shop:1.0.0    "uvicorn app:api --h…"   api       ...              Up ... (healthy)
ufla-devops-shop-banco-1    postgres:16-alpine                           "docker-entrypoint.s…"   banco     ...              Up ... (healthy)
ufla-devops-shop-cache-1    redis:7-alpine                               "docker-entrypoint.s…"   cache     ...              Up ...
ufla-devops-shop-nginx-1    nginx:alpine                                 "/docker-entrypoint.…"   nginx     ...              Up ...        0.0.0.0:8080->80/tcp
```

## 3. Endpoint de readiness (banco + cache)

```
$ curl -s localhost:8080/ready
{"status":"ok","banco":"postgresql","cache":"redis"}
```

## 4. Criação de um produto e persistência após restart

```
# Criar produto
$ curl -s -X POST localhost:8080/api/produtos \
  -H "Content-Type: application/json" \
  -d '{"nome":"Persistência Test","descricao":"Produto criado para testar volume","preco":9.99,"estoque":5}'
{"id":13,"nome":"Persistência Test","descricao":"Produto criado para testar volume","preco":9.99,"estoque":5}

# Derrubar e subir de novo
$ docker compose down
$ docker compose up -d

# Confirmar que o produto ainda existe (volume nomeado preservou os dados)
$ curl -s localhost:8080/api/produtos/13
{"id":13,"nome":"Persistência Test","descricao":"Produto criado para testar volume","preco":9.99,"estoque":5}
```

## 5. Volume nomeado

```
$ docker volume ls | grep dados_banco
local     ufla-devops-shop_dados_banco
```

## 6. Nenhuma porta interna exposta além do nginx

```
$ docker compose ps --format 'table {{.Name}}\t{{.Ports}}'
NAME                          PORTS
ufla-devops-shop-api-1
ufla-devops-shop-banco-1
ufla-devops-shop-cache-1
ufla-devops-shop-nginx-1      0.0.0.0:8080->80/tcp
```
