#!/usr/bin/env bash
# plugins.d/notion_export.sh — cria página em database do Notion com status/tags/anexos (URLs)
# Requer: curl, jq; env NOTION_TOKEN e NOTION_DATABASE_ID
# Args: Title | Content | [Status] | [TagsCSV] | [AttachmentURLs space-separated]
set -euo pipefail
need(){ command -v "$1" >/dev/null 2>&1; }
for b in curl jq; do need "$b" || { echo "[NOTION] faltando $b"; exit 1; }; done

TITLE="${1:-Gemx Note}"
CONTENT="${2:-}"
STATUS="${3:-}"
TAGS_CSV="${4:-}"
ATTACH_LIST="${5:-}"  # "https://...img1 https://...pdf2"

TOKEN="${NOTION_TOKEN:-}"
DB="${NOTION_DATABASE_ID:-}"
STATUS_PROP="${NOTION_STATUS_PROP:-Status}"
TAGS_PROP="${NOTION_TAGS_PROP:-Tags}"

if [ -z "$TOKEN" ] || [ -z "$DB" ]; then
  echo "[NOTION] Configure NOTION_TOKEN e NOTION_DATABASE_ID (ou others.json → integrations)."
  exit 2
fi

# Build children blocks (content + attachments)
children='[]'
body_block=$(jq -n --arg txt "$CONTENT" '{paragraph:{rich_text:[{text:{content:$txt}}]}}')
children=$(jq -n --argjson a "$children" --argjson b "$body_block" '$a + [ $b ]')

# Attachments (URLs only; Notion API de upload direto não é usado aqui)
if [ -n "$ATTACH_LIST" ]; then
  for url in $ATTACH_LIST; do
    # tenta inferir tipo imagem vs arquivo
    if echo "$url" | grep -Eiq '\.(png|jpg|jpeg|gif|webp)$'; then
      blk=$(jq -n --arg u "$url" '{image:{external:{url:$u}}}')
    else
      blk=$(jq -n --arg u "$url" '{file:{external:{url:$u}}}')
    fi
    children=$(jq -n --argjson a "$children" --argjson b "$blk" '$a + [ $b ]')
  done
fi

# Properties
props=$(jq -n --arg title "$TITLE" '{
  Name: { title: [ { text: { content: $title } } ] }
}')

if [ -n "$STATUS" ]; then
  props=$(jq -n --argjson p "$props" --arg prop "'"$STATUS_PROP"'" --arg s "$STATUS" \
    '$p + { ($prop): { status: { name: $s } } }')
fi

if [ -n "$TAGS_CSV" ]; then
  # split CSV to array of multi_select names
  tags_json=$(printf "%s" "$TAGS_CSV" | awk -F',' '{for(i=1;i<=NF;i++) printf "%s\n",$i}' | jq -R . | jq -s 'map({name:.})')
  props=$(jq -n --argjson p "$props" --arg prop "'"$TAGS_PROP"'" --argjson tags "$tags_json" '$p + { ($prop): { multi_select: $tags } }')
fi

json=$(jq -n --arg db "$DB" --argjson props "$props" --argjson children "$children" '{
  parent: { database_id: $db },
  properties: $props,
  children: $children
}')

resp=$(curl -sS -X POST https://api.notion.com/v1/pages \
  -H "Authorization: Bearer '"$TOKEN"'" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "$json")

id=$(echo "$resp" | jq -r '.id // empty')
if [ -n "$id" ]; then
  echo "[NOTION] Página criada: $id"
else
  echo "[NOTION] Falhou: $resp"
  exit 3
fi
