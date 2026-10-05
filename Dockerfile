# Estagio 1: builder — instala dependencias e compila wheels
FROM python:3.12-alpine AS builder

WORKDIR /build

RUN apk add --no-cache gcc musl-dev libpq-dev

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Estagio 2: imagem final — apenas o necessario para rodar
FROM python:3.12-alpine AS final

# Dependencias de runtime do psycopg (libpq)
RUN apk add --no-cache libpq

# Usuario nao-root
RUN addgroup -S loja && adduser -S -G loja loja

WORKDIR /app

# Copia pacotes instalados do builder
COPY --from=builder /install /usr/local

# Copia apenas o codigo de execucao
COPY app/ ./app/
COPY static/ ./static/

# Diretorio de dados com permissao para o usuario da aplicacao
RUN mkdir -p /data && chown loja:loja /data

USER loja

ENV SQLITE_PATH=/data/loja.db \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1

CMD ["uvicorn", "app:api", "--host", "0.0.0.0", "--port", "8000"]
