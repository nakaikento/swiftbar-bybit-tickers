#!/usr/bin/env bash
# SwiftBar: Bybit ETHUSDT Perp (linear) - 5s
# Label: ETHUSD / shows lastPrice (fallback: markPrice)
# Fix: use `python -c` + here-string for JSON (no stdin conflict)

export LC_ALL=C
set -euo pipefail

CATEGORY="linear"
SYMBOL="ETHUSDT"
LABEL="ETHUSD"

# 必要なら有効化（プロキシ/VPNで詰まるケース向け）
# unset http_proxy https_proxy all_proxy

# ---- python3 検出 ----
PYTHON=""
for p in "$(command -v python3 || true)" /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3 \
  "/Applications/Xcode.app/Contents/Developer/Library/Frameworks/Python3.framework/Versions/3.9/bin/python3"
do [[ -n "$p" && -x "$p" ]] && { PYTHON="$p"; break; }; done
if [[ -z "$PYTHON" ]]; then
  echo "$LABEL —"; echo "---"; echo "python3 not found"; exit 0
fi

# ---- 取得（本文のみ。HTTPコードは見ない）----
BYBIT_URL="https://api.bybit.com/v5/market/tickers?category=${CATEGORY}&symbol=${SYMBOL}"
BODY="$(curl -sS -m 5 --connect-timeout 3 -H 'Accept: application/json' -H 'User-Agent: SwiftBar' \
        "$BYBIT_URL" 2>/dev/null || true)"

# ---- 解析（retCode/list検証 → 値抽出）----
parsed="$("$PYTHON" -c '
import sys, json
body = sys.stdin.read().strip()
if not body:
    print("ERR|empty"); sys.exit(0)
try:
    j = json.loads(body)
except Exception:
    print("ERR|json"); sys.exit(0)
if j.get("retCode") != 0:
    print("ERR|ret"); sys.exit(0)
lst = (j.get("result") or {}).get("list") or []
if not lst:
    print("ERR|list"); sys.exit(0)
d = lst[0]
def s(k): v=d.get(k); return "" if v is None else str(v)
print("OK|%s|%s|%s|%s" % (s("lastPrice"), s("markPrice"), s("indexPrice"), s("fundingRate")))
' <<< "$BODY")"

status="${parsed%%|*}"
if [[ "$status" != "OK" ]]; then
  echo "$LABEL —"
  echo "---"
  echo "Fetch/parse failed: $status"
  head_body="$(printf '%s' "$BODY" | head -c 200 | tr '\n' ' ')"
  [[ -n "$head_body" ]] && echo "Body(head): $head_body"
  echo "Open API | href=$BYBIT_URL"
  exit 0
fi

# フィールド分解
rest="${parsed#OK|}"
LAST="${rest%%|*}"; rest="${rest#*|}"
MARK="${rest%%|*}"; rest="${rest#*|}"
INDEXP="${rest%%|*}"; FUND="${rest#*|}"

PRICE="$LAST"; [[ -z "$PRICE" || "$PRICE" == "None" ]] && PRICE="$MARK"
if [[ -z "${PRICE:-}" ]]; then
  echo "$LABEL —"; echo "---"; echo "Empty price (last/mark missing)"; echo "Open API | href=$BYBIT_URL"; exit 0
fi

# ---- 前回値と比較（↑/↓ & 色）----
sym_lc=$(printf '%s' "$SYMBOL" | tr '[:upper:]' '[:lower:]')
STATE="/tmp/swiftbar_${sym_lc}_${CATEGORY}_last"
PREV="$PRICE"; [[ -f "$STATE" ]] && PREV="$(cat "$STATE" 2>/dev/null || echo "$PRICE")"
printf '%s' "$PRICE" > "$STATE"

"$PYTHON" - "$PRICE" "$PREV" "$LABEL" "$INDEXP" "$FUND" <<'PY'
import sys
cur=float(sys.argv[1]); prev=float(sys.argv[2])
label=sys.argv[3]; indexp=sys.argv[4]; fund=sys.argv[5]
arrow="↑" if (cur-prev) >= 0 else "↓"
color="#2ecc71" if (cur-prev) >= 0 else "#e74c3c"
fund_str=""
try:
    fund_str=f"{float(fund)*100:.4f}%"
except Exception:
    pass
print(f"{label} ${cur:,.2f} {arrow} | color={color}")
print("---")
print(f"Index:  ${float(indexp):,.2f}" if indexp else "Index:  —")
print(f"Funding: {fund_str}" if fund_str else "Funding: —")
PY
