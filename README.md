# swiftbar-bybit-tickers
Bybit v5 API から ETHUSDT / BTCUSDT（USDT無期限＝linear） の価格を取得し、 macOS の SwiftBar に 5 秒ごとに表示するプラグインです。APIキー不要。

![swiftbar](https://dummyimage.com/600x90/eeeeee/333333&text=ETHUSD+$1234.56+%E2%86%91+++BTCUSD+$56789.00+%E2%86%93)

<img width="1920" height="1080" alt="スクリーンショット 2025-09-22 17 05 09" src="https://github.com/user-attachments/assets/43c69b2a-cdbc-4e66-8e67-a1f2c1a6388d" />

## 収録ファイル
- `ETH-BYBIT-PERP.5s.sh` … ETHUSDT（ラベル: `ETHUSD`）
- `BTC-BYBIT-PERP.5s.sh` … BTCUSDT（ラベル: `BTCUSD`）

> **更新間隔はファイル名で制御**します。例：`...10s.sh` にリネームすれば 10 秒更新。

## 必要条件
- macOS + [SwiftBar](https://swiftbar.app/)
- `curl` と `python3`（Homebrew 推奨）
  ```bash
  brew install --cask swiftbar
  brew install python

## 使い方
- このリポジトリをダウンロード（または git clone）＆解凍
- SwiftBar の Preferences → Plugins Folder を開く
- .sh を Plugins フォルダへコピー
- ターミナルで実行権限を付与
```bash
chmod +x "/path/to/Plugins/ETH-BYBIT-PERP.5s.sh" \
         "/path/to/Plugins/BTC-BYBIT-PERP.5s.sh"
```
- 数秒でメニューバーに ETHUSD と BTCUSD が表示されます
（上昇=緑、下落=赤。ドロップダウンに Index/Funding を表示）

## カスタマイズ
- 間隔変更：ファイル名の末尾を 7s, 10s などに変更。
- レート制限の衝突回避：ETH を 5s、BTC を 7s にする等で更新タイミングを分散。
さらに安定させたい場合は、スクリプト先頭にジッターを追加：

```bash
# set -euo pipefail の直後などに
sleep $((RANDOM % 3))  # 0〜2秒の遅延
```
- 表示ラベル変更：スクリプト内の LABEL を編集（例："ETH (Bybit)"）。
- 他シンボル：SYMBOL="BTCUSDT" などに変更（カテゴリーは linear / inverse / spot）。
- JPY 表示：USDT→JPY の換算を掛けたい場合は補助スクリプトで対応可能。

## トラブルシューティング
- メニューが — の表示：ネットワーク/VPN/プロキシの影響や一時エラーの可能性。
  - ドロップダウンの Body(head) に本文先頭が出ます。JSON が見えていれば通信は成功。
  - 必要ならスクリプト先頭の unset http_proxy https_proxy all_proxy を有効化。
- `python3 not found`：Homebrew で `brew install python`、または Xcode に同梱の python3 を使用します。
- 権限不足：`chmod +x` を実行してください。

## 仕組み
- Bybit v5 GET /v5/market/tickers をポーリング。lastPrice を優先し、未定義時は markPrice を使用。
- 直前値と比較して、上昇/下落で色と矢印を切替。
- HTTP ステータスに依存せず 本文 JSON の retCode と result.list を厳密チェック。

## ライセンス
MIT License
