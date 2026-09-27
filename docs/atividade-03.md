# Atividade 3 — Guilherme Fabricio (@GuiDev115)

## Como rodar o deploy.sh numa máquina limpa

```bash
# 1. Pre-requisitos
sudo apt install -y python3-venv postgresql redis-server nginx rsync openssl

# 2. Criar usuario e banco do PostgreSQL
sudo -u postgres psql -c "CREATE USER loja WITH PASSWORD 'sua-senha';"
sudo -u postgres psql -c "CREATE DATABASE loja OWNER loja;"

# 3. Criar o arquivo de segredos
sudo tee /etc/ufla-shop.env <<'EOF'
DATABASE_URL=postgresql://loja:sua-senha@localhost:5432/loja
REDIS_URL=redis://localhost:6379/0
EOF
sudo chmod 640 /etc/ufla-shop.env

# 4. Rodar o deploy (como root)
sudo bash scripts/deploy.sh

# Segunda execucao (prova de idempotencia):
sudo bash scripts/deploy.sh
```

---

## Saída de `systemctl status ufla-shop` após `kill -9` no uvicorn

```
# Comando executado:
sudo kill -9 $(systemctl show ufla-shop --property=MainPID --value)
# Aguardado ~7 segundos...
systemctl status ufla-shop
```

```
● ufla-shop.service - ufla-devops-shop API (FastAPI/uvicorn)
     Loaded: loaded (/etc/systemd/system/ufla-shop.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-09-27 20:17:35 -03; 9s ago
 Invocation: 4fe5b7ef8c494e6abe7f0cd7796c05b5
   Main PID: 47932 (uvicorn)
      Tasks: 1 (limit: 14203)
     Memory: 48.6M (peak: 48.8M)
        CPU: 733ms
     CGroup: /system.slice/ufla-shop.service
             └─47932 /opt/ufla-shop/.venv/bin/python3 /opt/ufla-shop/.venv/bin/uvicorn app:api --host 127.0.0.1 --port 8000

Sep 27 20:17:30 dell-g15 systemd[1]: ufla-shop.service: Consumed 1.965s CPU time over 8min 20.137s wall clock time, 52.7M memory peak.
Sep 27 20:17:35 dell-g15 systemd[1]: ufla-shop.service: Scheduled restart job, restart counter is at 1.
Sep 27 20:17:35 dell-g15 systemd[1]: Started ufla-shop.service - ufla-devops-shop API (FastAPI/uvicorn).
Sep 27 20:17:35 dell-g15 ufla-shop[47932]: INFO:     Started server process [47932]
Sep 27 20:17:35 dell-g15 ufla-shop[47932]: INFO:     Waiting for application startup.
Sep 27 20:17:35 dell-g15 ufla-shop[47932]: 2026-09-27 20:17:35,666 INFO loja: ufla-devops-shop 1.0.0 subindo (banco=postgresql, cache=redis, instancia=dell-g15)
Sep 27 20:17:35 dell-g15 ufla-shop[47932]: 2026-09-27 20:17:35,794 INFO loja.banco: banco pronto (modo postgresql)
Sep 27 20:17:35 dell-g15 ufla-shop[47932]: INFO:     Application startup complete.
Sep 27 20:17:35 dell-g15 ufla-shop[47932]: INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

O serviço foi derrubado com `KILL` e o systemd o reiniciou automaticamente em ~5 segundos, com novo PID (47932), sem intervenção manual.

---

## Saída de `curl -kI https://localhost` e `curl -I http://localhost`

```
$ curl -sk https://localhost/health
{"status":"ok","versao":"1.0.0"}

$ curl -sk https://localhost/ready
{"status":"ok","banco":"ok","cache":"ok"}

$ curl -I http://localhost
HTTP/1.1 301 Moved Permanently
Server: nginx/1.28.3 (Ubuntu)
Content-Type: text/html
Location: https://localhost/
```

O HTTPS passa pelo Nginx (proxy_pass para 127.0.0.1:8000) com TLS autoassinado. O HTTP responde 301 redirecionando para HTTPS. A rota `/` da API aceita apenas GET — o `curl -I` (HEAD) retorna 405, que é o comportamento correto da FastAPI.

---

## Saída de `ls -la /var/backups/ufla-shop` após três execuções do backup

```
total 20
drwxr-xr-x 2 postgres postgres 4096 Sep 27 20:19 .
drwxr-xr-x 3 root     root     4096 Sep 27 20:08 ..
-rw-r--r-- 1 postgres postgres   20 Sep 27 20:09 loja-2026-09-27-2009.sql.gz
-rw-r--r-- 1 postgres postgres   20 Sep 27 20:18 loja-2026-09-27-2018.sql.gz
-rw-r--r-- 1 postgres postgres 1625 Sep 27 20:19 loja-2026-09-27-2019.sql.gz
```

Três dumps datados com timestamp `AAAA-MM-DD-HHMM`, rotação mantendo os 7 mais recentes. O terceiro dump é maior porque o banco já tinha dados de transações anteriores.

---

## Prova de idempotência — duas execuções seguidas do deploy.sh

**Primeira execução:**

```
==> [1/7] Criando usuario de sistema 'ufla-shop'...
==> [2/7] Sincronizando codigo para /opt/ufla-shop...
==> [3/7] Criando venv e instalando dependencias...
==> [4/7] Configurando arquivo de variaveis de ambiente...
==> [5/7] Instalando units do systemd...
==> [6/7] Gerando certificado TLS autoassinado...
    Instalando configuracao do Nginx...
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
==> [7/7] Healthcheck (ate 10 tentativas com intervalo de 1s)...
    Aguardando... (1/10)
    OK: aplicacao respondendo em /ready (tentativa 2)

Deploy concluido com sucesso.
  Servico: systemctl status ufla-shop
  Logs:    journalctl -u ufla-shop -f
  HTTPS:   curl -kI https://localhost
```

**Segunda execução (idempotente — sem erro, nada duplicado):**

```
==> [1/7] Criando usuario de sistema 'ufla-shop'...
==> [2/7] Sincronizando codigo para /opt/ufla-shop...
==> [3/7] Criando venv e instalando dependencias...
==> [4/7] Configurando arquivo de variaveis de ambiente...
==> [5/7] Instalando units do systemd...
==> [6/7] Gerando certificado TLS autoassinado...
    Instalando configuracao do Nginx...
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
==> [7/7] Healthcheck (ate 10 tentativas com intervalo de 1s)...
    Aguardando... (1/10)
    OK: aplicacao respondendo em /ready (tentativa 2)

Deploy concluido com sucesso.
  Servico: systemctl status ufla-shop
  Logs:    journalctl -u ufla-shop -f
  HTTPS:   curl -kI https://localhost
```

Na segunda execução: o usuário `ufla-shop` já existia (sem erro graças ao `id ufla-shop &>/dev/null || useradd ...`), o `/etc/ufla-shop.env` não foi sobrescrito, o certificado não foi regenerado, e o serviço foi apenas reiniciado — sem duplicação.

---

## Timer ativo

```
NEXT                        LEFT LAST PASSED UNIT                   ACTIVATES
Mon 2026-09-28 03:00:00 -03   6h -         - ufla-shop-backup.timer ufla-shop-backup.service

1 timers listed.
```

Timer agendado para as 03h diariamente, com `Persistent=true` para recuperar execuções perdidas.
