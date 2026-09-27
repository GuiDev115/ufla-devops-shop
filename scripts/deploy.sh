#!/usr/bin/env bash
set -euo pipefail

APP_USER="ufla-shop"
APP_DIR="/opt/ufla-shop"
ENV_FILE="/etc/ufla-shop.env"
ENV_EXAMPLE="$(dirname "$(readlink -f "$0")")/../etc/ufla-shop.env.example"
SYSTEMD_DIR="/etc/systemd/system"
REPO_DIR="$(dirname "$(readlink -f "$0")")/.."
CERT_DIR="/etc/nginx/ssl/ufla-shop"

echo "==> [1/7] Criando usuario de sistema '$APP_USER'..."
id "$APP_USER" &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin "$APP_USER"

echo "==> [2/7] Sincronizando codigo para $APP_DIR..."
mkdir -p "$APP_DIR"
rsync -a --delete \
    --exclude='.git' \
    --exclude='.venv' \
    --exclude='dados' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    "$REPO_DIR/" "$APP_DIR/"
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

echo "==> [3/7] Criando venv e instalando dependencias..."
python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/pip" install --quiet --upgrade pip
"$APP_DIR/.venv/bin/pip" install --quiet -r "$APP_DIR/requirements.txt"
chown -R "$APP_USER:$APP_USER" "$APP_DIR/.venv"

echo "==> [4/7] Configurando arquivo de variaveis de ambiente..."
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo "    ATENCAO: $ENV_FILE criado a partir do exemplo."
        echo "    Edite-o com a senha real do banco antes de continuar."
    else
        cat > "$ENV_FILE" <<'EOF'
DATABASE_URL=postgresql://loja:troque-esta-senha@localhost:5432/loja
REDIS_URL=redis://localhost:6379/0
EOF
        echo "    ATENCAO: $ENV_FILE criado com valores de exemplo."
        echo "    Edite-o com a senha real antes de continuar."
    fi
    chmod 640 "$ENV_FILE"
    chown root:"$APP_USER" "$ENV_FILE"
fi

echo "==> [5/7] Instalando units do systemd..."
cp "$REPO_DIR/systemd/ufla-shop.service"        "$SYSTEMD_DIR/ufla-shop.service"
cp "$REPO_DIR/systemd/ufla-shop-backup.service" "$SYSTEMD_DIR/ufla-shop-backup.service"
cp "$REPO_DIR/systemd/ufla-shop-backup.timer"   "$SYSTEMD_DIR/ufla-shop-backup.timer"
systemctl daemon-reload
systemctl enable ufla-shop ufla-shop-backup.timer
systemctl restart ufla-shop
systemctl enable --now ufla-shop-backup.timer

echo "==> [6/7] Gerando certificado TLS autoassinado..."
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/loja.pem" ] || [ ! -f "$CERT_DIR/loja.key" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/loja.key" \
        -out    "$CERT_DIR/loja.pem" \
        -subj "/CN=localhost/O=ufla-devops-shop"
    chmod 600 "$CERT_DIR/loja.key"
    echo "    Certificado gerado em $CERT_DIR"
fi

echo "    Instalando configuracao do Nginx..."
cp "$REPO_DIR/nginx/loja.conf" /etc/nginx/sites-available/ufla-shop
ln -sf /etc/nginx/sites-available/ufla-shop /etc/nginx/sites-enabled/ufla-shop
nginx -t
systemctl reload nginx || systemctl restart nginx

echo "==> [7/7] Healthcheck (ate 10 tentativas com intervalo de 1s)..."
for i in $(seq 1 10); do
    if curl -sf http://localhost:8000/ready | grep -q '"banco":"ok"'; then
        echo "    OK: aplicacao respondendo em /ready (tentativa $i)"
        break
    fi
    if [ "$i" -eq 10 ]; then
        echo "    ERRO: aplicacao nao respondeu apos 10 tentativas." >&2
        exit 1
    fi
    echo "    Aguardando... ($i/10)"
    sleep 1
done

echo ""
echo "Deploy concluido com sucesso."
echo "  Servico: systemctl status ufla-shop"
echo "  Logs:    journalctl -u ufla-shop -f"
echo "  HTTPS:   curl -kI https://localhost"
