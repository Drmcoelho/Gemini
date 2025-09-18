#!/usr/bin/env bash
# .ssh.sh — Helper para conectar via SSH do Codespace ao seu Mac
# Uso rápido:
#   ./\.ssh.sh --host mac.local --user meu_usuario
#   MAC_HOST=meu.mac.tailnet MAC_USER=meu_usuario ./\.ssh.sh
#
# Opções:
#   --host HOST               Hostname/IP do Mac (ex.: mac.local, 192.168.0.10, <tailscale-host>)
#   --user USER               Usuário no Mac (ex.: joao)
#   --port PORT               Porta SSH (default: 22)
#   --id PATH                 Caminho para a chave privada (ex.: ~/.ssh/id_ed25519)
#   --jump USER@HOST[:PORT]   ProxyJump bastion (se precisar passar por um intermediário)
#   --local LPORT:RHOST:RPORT Encaminhamento local (pode repetir)
#   --remote RPORT:LHOST:LPORT Encaminhamento remoto (pode repetir)
#   --dynamic PORT            Encaminhamento SOCKS5 dinâmico (pode repetir)
#   --cmd "comando"           Executa um comando remoto ao invés de abrir shell
#   --accept-new-host-key     Usa StrictHostKeyChecking=accept-new
#   --no-strict-host-key      Usa StrictHostKeyChecking=no (menos seguro)
#   --keepalive N             ServerAliveInterval em segundos (default: 30)
#   --alive-count N           ServerAliveCountMax (default: 3)
#   --verbose                 Ativa -v
#   --help                    Mostra ajuda
#
# Variáveis de ambiente (aceitas se flags não forem passadas):
#   MAC_HOST, MAC_USER, MAC_PORT, MAC_IDENTITY, MAC_JUMP
#   MAC_LOCAL (lista separada por vírgula LPORT:RHOST:RPORT)
#   MAC_REMOTE (lista separada por vírgula RPORT:LHOST:LPORT)
#   MAC_DYNAMIC (lista separada por vírgula de portas)
#   MAC_CMD, MAC_ACCEPT_NEW (1), MAC_NO_STRICT (1)
#   MAC_KEEPALIVE (segundos), MAC_ALIVE_COUNT, MAC_VERBOSE (1)

# Não usamos set -euo para evitar abortar em ambientes restritos.

print_help(){
  cat <<'HLP'
Uso:
  ./\.ssh.sh --host HOST --user USER [opções]

Exemplos:
  ./\.ssh.sh --host mac.local --user joao
  MAC_HOST=meu.mac.tailnet MAC_USER=joao MAC_IDENTITY=~/.ssh/id_ed25519 ./\.ssh.sh

Opções:
  --host HOST               Hostname/IP do Mac (ex.: mac.local, 192.168.0.10, <tailscale-host>)
  --user USER               Usuário no Mac (ex.: joao)
  --port PORT               Porta SSH (default: 22)
  --id PATH                 Caminho para a chave privada
  --jump USER@HOST[:PORT]   ProxyJump bastion
  --local LPORT:RHOST:RPORT Encaminhamento local (pode repetir)
  --remote RPORT:LHOST:LPORT Encaminhamento remoto (pode repetir)
  --dynamic PORT            Encaminhamento SOCKS5 dinâmico (pode repetir)
  --cmd "comando"           Executa um comando remoto ao invés de abrir shell
  --accept-new-host-key     Usa StrictHostKeyChecking=accept-new
  --no-strict-host-key      Usa StrictHostKeyChecking=no (menos seguro)
  --keepalive N             ServerAliveInterval em segundos (default: 30)
  --alive-count N           ServerAliveCountMax (default: 3)
  --verbose                 Ativa -v
  --help                    Mostra ajuda
HLP
}

need(){ command -v "$1" >/dev/null 2>&1; }

HOST="${MAC_HOST:-}"
USER_="${MAC_USER:-}"
PORT="${MAC_PORT:-22}"
ID_FILE="${MAC_IDENTITY:-}"
JUMP="${MAC_JUMP:-}"
KEEPALIVE="${MAC_KEEPALIVE:-30}"
ALIVE_COUNT="${MAC_ALIVE_COUNT:-3}"
VERBOSE_FLAG="${MAC_VERBOSE:-}"
ACCEPT_NEW="${MAC_ACCEPT_NEW:-}"
NO_STRICT="${MAC_NO_STRICT:-}"
CMD="${MAC_CMD:-}"

LOCAL_FWDS=()
REMOTE_FWDS=()
DYNAMIC_FWDS=()

# Consome variáveis de ambiente de listas (se existirem)
if [ -n "${MAC_LOCAL:-}" ]; then IFS=',' read -r -a _L <<< "$MAC_LOCAL"; for i in "${_L[@]}"; do LOCAL_FWDS+=("-L" "$i"); done; fi
if [ -n "${MAC_REMOTE:-}" ]; then IFS=',' read -r -a _R <<< "$MAC_REMOTE"; for i in "${_R[@]}"; do REMOTE_FWDS+=("-R" "$i"); done; fi
if [ -n "${MAC_DYNAMIC:-}" ]; then IFS=',' read -r -a _D <<< "$MAC_DYNAMIC"; for i in "${_D[@]}"; do DYNAMIC_FWDS+=("-D" "$i"); done; fi

# Parse flags simples
while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --user) USER_="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --id) ID_FILE="$2"; shift 2;;
    --jump) JUMP="$2"; shift 2;;
    --local) LOCAL_FWDS+=("-L" "$2"); shift 2;;
    --remote) REMOTE_FWDS+=("-R" "$2"); shift 2;;
    --dynamic) DYNAMIC_FWDS+=("-D" "$2"); shift 2;;
    --cmd) CMD="$2"; shift 2;;
    --keepalive) KEEPALIVE="$2"; shift 2;;
    --alive-count) ALIVE_COUNT="$2"; shift 2;;
    --accept-new-host-key) ACCEPT_NEW=1; shift;;
    --no-strict-host-key) NO_STRICT=1; shift;;
    --verbose) VERBOSE_FLAG=1; shift;;
    --help|-h) print_help; exit 0;;
    *) echo "[ERR] Flag desconhecida: $1" >&2; print_help; exit 1;;
  esac
done

if ! need ssh; then echo "[ERR] 'ssh' não encontrado no PATH" >&2; exit 127; fi

if [ -z "$HOST" ] || [ -z "$USER_" ]; then
  echo "[ERR] Informe --host e --user (ou MAC_HOST/MAC_USER)." >&2
  echo "Ex.: ./\.ssh.sh --host mac.local --user joao" >&2
  exit 2
fi

# Monta opções
OPTS=(
  -p "$PORT"
  -o ServerAliveInterval="$KEEPALIVE"
  -o ServerAliveCountMax="$ALIVE_COUNT"
  -o TCPKeepAlive=yes
  -o ExitOnForwardFailure=yes
)

if [ -n "$ID_FILE" ]; then OPTS+=( -i "$ID_FILE" ); fi
if [ -n "$JUMP" ]; then OPTS+=( -J "$JUMP" ); fi
if [ -n "$VERBOSE_FLAG" ]; then OPTS+=( -v ); fi

# Host key policy
if [ -n "$ACCEPT_NEW" ]; then
  OPTS+=( -o StrictHostKeyChecking=accept-new )
elif [ -n "$NO_STRICT" ]; then
  OPTS+=( -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null )
fi

# Acrescenta forwards
OPTS+=( "${LOCAL_FWDS[@]}" )
OPTS+=( "${REMOTE_FWDS[@]}" )
OPTS+=( "${DYNAMIC_FWDS[@]}" )

TARGET="${USER_}@${HOST}"

# Mostra resumo
echo "[INFO] SSH → $TARGET (port $PORT)"
if [ -n "$JUMP" ]; then echo "[INFO] ProxyJump: $JUMP"; fi
if [ -n "$ID_FILE" ]; then echo "[INFO] IdentityFile: $ID_FILE"; fi

# Execução
if [ -n "$CMD" ]; then
  exec ssh "${OPTS[@]}" "$TARGET" "$CMD"
else
  exec ssh "${OPTS[@]}" "$TARGET"
fi
