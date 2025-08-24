#!/usr/bin/env bash
set -euo pipefail

CONFIG="client/config/remote.yaml"
OUTBOX="client/env_builder/evogym-design-tool/envs/outbox"
INBOX="/home/reiji/dev/EvoGymComp/EvogymCompetition/server/custom_env/inbox"  # サーバ側固定

# --- remote.yaml から user/host/ssh_key を awk で取得（簡易 YAML パーサ） ---
read_yaml_key() {
  local key="$1"
  awk -v key="$key" '
    BEGIN{in_remote=0}
    /^[[:space:]]*remote:[[:space:]]*$/ {in_remote=1; next}
    /^[[:alnum:]_]+:/ {if(in_remote){exit} }
    in_remote && $0 ~ "^[[:space:]]*"key":" {
      line=$0
      sub(/^[^:]+:[[:space:]]*/, "", line)
      gsub(/^["'"'"']|["'"'"']$/, "", line)
      print line
      exit
    }
  ' "$CONFIG"
}
USER="$(read_yaml_key user)"
HOST="$(read_yaml_key host)"
KEY="$(read_yaml_key ssh_key)"

# --- outbox の *.json が ちょうど1件か確認 ---
shopt -s nullglob
jsons=( "$OUTBOX"/*.json )
shopt -u nullglob

if (( ${#jsons[@]} == 0 )); then
  echo "[push] outbox に *.json がありません: $OUTBOX"
  exit 0
fi
if (( ${#jsons[@]} > 1 )); then
  echo "[push] outbox に JSON が複数あります。1件にしてください。"
  for f in "${jsons[@]}"; do echo " - $f"; done
  exit 0
fi

LOCAL_JSON="${jsons[0]}"
BASENAME="$(basename "$LOCAL_JSON")"

echo "-> Pushing to ${USER}@${HOST}:${INBOX}/${BASENAME}"
scp \
  -i "$KEY" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o BatchMode=yes \
  "$LOCAL_JSON" \
  "${USER}@${HOST}:${INBOX}/${BASENAME}"
echo "Done."