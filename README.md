# ufla-devops-shop

Repositório da turma de **DevOps na Prática** — DCC / UFLA.

Prof. Dr. Rafael Serapilha Durelli · [rafael.durelli@ufla.br](mailto:rafael.durelli@ufla.br)

Este repositório é o **projeto fio condutor** da disciplina. Você faz um *fork*
dele na Atividade 0 e trabalha no seu fork durante as 15 semanas: a mesma
aplicação vai sendo containerizada, testada, empacotada, implantada, monitorada
e provisionada, semana após semana.

---

## Comece por aqui

1. Instale as ferramentas: **[docs/instalacao.md](docs/instalacao.md)**
   (Ubuntu/Debian, Fedora, macOS e Windows com WSL2).
2. Faça o *fork* deste repositório (botão **Fork**, canto superior direito).
3. Clone o **seu** fork e verifique a máquina:

   ```bash
   git clone git@github.com:<seu-usuario>/ufla-devops-shop.git
   cd ufla-devops-shop
   ./scripts/check-ambiente.sh
   ```

4. Siga o enunciado da **Atividade 0**, publicado no campus virtual.

---

## Estrutura

```
ufla-devops-shop/
├── app/                       # a API (FastAPI): uvicorn app:api
├── static/                    # o front estático, servido pela API em /
├── tests/                     # pytest — roda sem banco nem cache
├── requirements.txt           # dependências de execução (vão para a imagem)
├── requirements-dev.txt       # + testes, cobertura e lint (CI e desenvolvimento)
├── pyproject.toml             # configuração de ruff, pytest e cobertura
├── docs/
│   ├── instalacao.md          # roteiro de instalação por sistema operacional
│   └── aplicacao.md           # como a aplicação funciona, rotas e variáveis
├── scripts/
│   ├── check-ambiente.sh      # verificador de ambiente (Atividade 0)
│   └── baixar-dados.sh        # traz o access.log da Atividade 2
├── alunos/                    # apresentação de cada aluno (Atividade 0)
├── analises/                  # análises da Atividade 1 e (em logs/) da Atividade 2
└── .github/
    ├── pull_request_template.md
    └── workflows/             # verificação automática de cada atividade
```

## A aplicação

`ufla-devops-shop` é uma loja mínima: API em Python (FastAPI), PostgreSQL,
Redis e um front estático. Ela é o **fio condutor** das 15 semanas — cada
atividade acrescenta uma camada sobre a mesma base, e nenhuma começa do zero.

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
uvicorn app:api --reload        # http://localhost:8000  (API + front + /docs)
pytest --cov=app                # os testes não precisam de banco nem de cache
```

Sem variáveis de ambiente ela sobe **sozinha** (SQLite + cache em memória).
Com `DATABASE_URL` e `REDIS_URL` ela usa PostgreSQL e Redis. Rotas, variáveis,
modos e os tamanhos reais de imagem estão em
**[docs/aplicacao.md](docs/aplicacao.md)** — leia antes da Atividade 4.

### Seu fork está desatualizado?

Quem fez o *fork* antes de a aplicação entrar aqui precisa **trazê-la**:
`git pull` puxa do seu fork, não deste repositório.

```bash
git remote add upstream https://github.com/rdurelli/ufla-devops-shop.git   # uma vez só
git fetch upstream && git switch main && git merge upstream/main && git push origin main
```

Ou **Sync fork → Update branch** na página do seu fork. Faça isso no início de
**toda** atividade.

## `scripts/check-ambiente.sh`

Verifica ferramentas, versões mínimas, o daemon do Docker, a configuração do Git
e os recursos da máquina. Quando algo falta, imprime o comando de instalação
para o sistema detectado.

```bash
./scripts/check-ambiente.sh                      # relatório colorido
./scripts/check-ambiente.sh | tee ambiente.txt   # salva para anexar ao PR
```

Sai com código `0` se o ambiente estiver pronto e `1` se faltar algo
obrigatório. Versões mínimas: `git` 2.30, `docker` 24.0, `kubectl` 1.28,
`kind` 0.20, `helm` 3.12, `terraform` 1.5, Docker Compose v2.

O script também é material didático: na Semana 4 (shell script) abrimos este
arquivo em aula e discutimos as construções usadas nele.

---

## Como entregar

Toda atividade tem **duas etapas obrigatórias**. Faltando qualquer uma delas, a
atividade é considerada não entregue.

1. **Pull Request neste repositório**, com o trabalho feito na *branch*
   `atividade-NN` do seu fork.
2. **Link do Pull Request postado no campus virtual**, na tarefa correspondente.
   O horário desta postagem é o registro oficial da entrega.

O fluxo é sempre o mesmo:

```bash
git switch -c atividade-00                       # branch da atividade
git add alunos/<seu-usuario>.md ambiente.txt     # seus arquivos
git commit -m "feat: apresentacao e ambiente de <seu-usuario>"
git push -u origin atividade-00
```

Depois abra o Pull Request pelo GitHub, com o título no padrão
`Atividade 0 -- Seu Nome`.

### Verificação automática

Assim que o PR é aberto, o GitHub Actions roda sozinho e comenta o resultado em
cerca de um minuto. Se aparecer ✗ vermelho, leia o comentário, corrija, faça um
novo commit e dê `push` na mesma branch — o PR se atualiza sozinho. Você pode
repetir isso quantas vezes quiser antes do prazo.

A verificação automática **não é a nota**. Ela cobre o que a máquina consegue
julgar; a avaliação do professor complementa nos aspectos que ela não julga —
clareza, justificativa das decisões e qualidade da documentação.

### Atrasos e descarte

Atraso: desconto de 1,0 ponto por dia corrido, contado pelo horário da postagem
no campus virtual. Descarte: a menor nota entre as atividades do semestre é
descartada no cálculo final, sem necessidade de justificativa.

---

## Onde pedir ajuda

No **fórum da atividade**, no campus virtual. Pergunta pública gera resposta que
serve para a turma toda — e quase sempre alguém já passou pelo mesmo problema.

Ao relatar um erro, inclua:

1. o que você estava tentando fazer;
2. o comando exato que executou;
3. a mensagem de erro **completa**, copiada como texto (não como foto da tela);
4. o que você já tentou.

Esta é a mesma estrutura de um bom *issue* e de um bom *postmortem*.

---

## DevSecOps — Pipeline de segurança

O workflow `.github/workflows/devsecops.yml` implementa *shift-left security*:
todas as verificações rodam automaticamente na abertura e atualização de Pull Requests.
**A publicação da imagem Docker só ocorre após a aprovação de todos os checks.**

### Ferramentas integradas

| Ferramenta | Tipo | Bloqueante? |
|---|---|---|
| **Gitleaks** | Detecção de segredos no histórico git | Sim — qualquer segredo detectado |
| **SonarCloud** | Análise estática (SAST) + Quality Gate | Sim — código novo que falha no Quality Gate |
| **Trivy** (deps) | Varredura das dependências Python (`requirements.txt`) | Sim — CRITICAL/HIGH com correção disponível |
| **Trivy** (imagem) | Varredura da imagem Docker construída | Sim — CRITICAL/HIGH com correção disponível |
| **Syft** | Geração de SBOM da imagem Docker | Não (gera e publica como artifact) |

### Regras de bloqueio

- **Gitleaks**: falha ao detectar qualquer token, senha, chave API ou outro segredo no histórico do repositório.
- **SonarCloud**: falha quando o Quality Gate configurado no SonarCloud não é aprovado (padrão: cobertura mínima, zero Security Hotspots, zero Bugs críticos em código novo).
- **Trivy**: falha quando encontra vulnerabilidade `CRITICAL` ou `HIGH` **com correção disponível** (`--ignore-unfixed`). Vulnerabilidades `LOW` e `MEDIUM` são registradas em relatório JSON e publicadas como artifact, sem bloquear o pipeline.
- **Publicação da imagem**: o job `publish` só executa em push à `main` e depende do sucesso de todos os jobs acima.

### Artifacts gerados por execução

| Artifact | Conteúdo |
|---|---|
| `sbom.spdx.json` | Software Bill of Materials da imagem (formato SPDX-JSON) |
| `trivy-deps-report` | Relatório JSON de vulnerabilidades LOW/MEDIUM nas dependências |
| `trivy-image-report` | Relatório JSON de vulnerabilidades LOW/MEDIUM na imagem Docker |

### Configuração necessária (uma vez)

1. **SonarCloud**: acesse [sonarcloud.io](https://sonarcloud.io), importe o repositório e crie o projeto. Adicione o secret `SONAR_TOKEN` nas configurações do repositório GitHub.
2. **Gitleaks** (repositório privado): adicione o secret `GITLEAKS_LICENSE` se o repositório for privado. Em repositórios públicos não é necessário.
3. **Branch protection**: em *Settings → Branches → main*, exija os checks `Gitleaks`, `SonarCloud`, `Trivy (deps)` e `Trivy (imagem)` como obrigatórios para merge.

---

## Uso de IA generativa

Permitido e incentivado. Em contrapartida, você deve ser capaz de explicar
qualquer linha entregue: a arguição final pergunta o *porquê* das decisões, não
a sintaxe.
