# Atividade 4 — Guilherme Fabricio (@GuiDev115)

## 1. Tamanho da imagem — antes e depois

| Versão | Base | Tamanho (`docker image inspect --format '{{.Size}}'`) |
|---|---|---|
| v0 (primeira que funcionou) | `python:3.12-slim` + multi-stage | ~168 MB |
| **v1 (final)** | `python:3.12-alpine` + multi-stage | **33 MB** |

```
$ docker image inspect --format '{{.Size}}' ufla-shop:1.0 | numfmt --to=si
33M

$ docker images ufla-shop:1.0
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ufla-shop:1.0   51e2b8012757        140MB         32.8MB
```

---

## 2. O que mudou e quanto cada mudança economizou

### Mudança 1 — Trocar `python:3.12-slim` por `python:3.12-alpine` no estágio final

`python:3.12-slim` (Debian) tem ~125 MB. O `python:3.12-alpine` (musl libc) tem ~25 MB.
Todas as dependências da aplicação (`fastapi`, `uvicorn`, `psycopg[binary]`, `redis`) possuem
wheels pré-compilados para `musllinux`, então não é necessário compilar nada no estágio final.

**Economia estimada: ~100 MB**

### Mudança 2 — Build multi-stage

O estágio `builder` instala `gcc`, `musl-dev`, `libpq-dev` e compila os pacotes. Nada disso
vai para a imagem final — apenas o conteúdo de `/install` (os pacotes instalados) é copiado
com `COPY --from=builder /install /usr/local`. O `pip` e todo o toolchain de compilação
ficam só no builder.

**Economia estimada: ~80 MB (compiladores e headers descartados)**

### Mudança 3 — `.dockerignore` enxuto

Excluindo `.venv`, `__pycache__`, `tests/`, `dados/`, `*.db`, `.env` e outros diretórios
não necessários em runtime, o contexto de build é mínimo e nenhum artefato desnecessário
entra na imagem.

### Mudança 4 — `PYTHONDONTWRITEBYTECODE=1`

Impede que o Python gere arquivos `.pyc` dentro do container, evitando lixo no sistema de
arquivos da imagem.

---

## 3. Saída dos comandos de verificação

### Usuário não-root

```
$ docker run --rm ufla-shop:1.0 id
uid=100(loja) gid=101(loja) groups=101(loja),101(loja)
```

### Health status (após 12 s de start-period)

```
$ docker inspect --format '{{.State.Health.Status}}' loja
healthy
```

### `/health` e `/api/produtos`

```
$ curl -s localhost:8080/health
{"status":"ok","versao":"1.0.0"}

$ curl -s localhost:8080/api/produtos | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{len(d)} produtos')"
12 produtos
```

### `docker stop` em menos de 2 s

```
$ time docker stop loja
loja
docker stop loja  0.02s user 0.01s system 5% cpu 0.521 total
```

O `CMD` está na forma **exec** (`["uvicorn", "app:api", ...]`), então o uvicorn é o PID 1
e recebe o SIGTERM diretamente, encerrando em ~0,5 s.

---

## 4. Por que o HEALTHCHECK consulta `/health` e não `/ready`?

`/health` é o *liveness probe*: verifica apenas se o processo está vivo, sem tocar em banco
ou cache. `/ready` é o *readiness probe*: testa se PostgreSQL e Redis respondem, e num
container standalone (sem esses serviços) ele sempre retornaria 503, deixando o container
permanentemente `unhealthy`. O HEALTHCHECK deve usar `/health` para não punir a aplicação
por ausência de dependências externas que são opcionais neste modo de execução.
