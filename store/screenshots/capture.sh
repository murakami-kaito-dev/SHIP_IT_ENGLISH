#!/usr/bin/env bash
#
# App Store 用スクリーンショット撮影スクリプト（ShipIt English）
#
# 使い方（Mac 上で実行）:
#   cd <repo>/store/screenshots
#   ./capture.sh                 # iPhone 15 Pro Max（6.7" / 1290x2796）で起動
#   ./capture.sh "iPhone 16 Pro Max"   # 6.9" / 1320x2868 を使いたい場合
#
# 起動後、シミュレータでアプリを操作し、撮りたい画面で
# このターミナルに戻って Enter を押すと 01.png, 02.png ... と保存される。
# q + Enter で終了。
#
# ※ 初回起動時に「通知を許可しますか？」ダイアログが出たら一度 "許可" を押す
#   （以後は出ない）。オンボーディングはスクリプトが自動でスキップ設定を入れる。
set -e

DEVICE_NAME="${1:-iPhone 15 Pro Max}"
BUNDLE_ID="jp.co.shipitenglish.app"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="$(cd "$(dirname "$0")" && pwd)/out"
mkdir -p "$OUT_DIR"

echo "▶ デバイス: $DEVICE_NAME"
UDID=$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | grep -oE "[0-9A-F-]{36}")
if [ -z "$UDID" ]; then echo "✗ '$DEVICE_NAME' が見つかりません。'xcrun simctl list devices available' で名前を確認してください。"; exit 1; fi
echo "▶ UDID: $UDID"

echo "▶ シミュレータ起動..."
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$UDID"

echo "▶ シミュレータ向けにビルド（数分かかります）..."
cd "$REPO_ROOT"
flutter build ios --simulator --debug

echo "▶ インストール..."
xcrun simctl install "$UDID" "$REPO_ROOT/build/ios/iphonesimulator/Runner.app"

echo "▶ オンボーディングをスキップ設定（言語=日本語・完了フラグON）..."
xcrun simctl spawn "$UDID" defaults write "$BUNDLE_ID" flutter.onboarding_done -bool YES 2>/dev/null || true
xcrun simctl spawn "$UDID" defaults write "$BUNDLE_ID" flutter.language_mode -string ja 2>/dev/null || true
# 英語版スクショを撮るときは上の ja を en にして再実行

echo "▶ アプリ起動..."
xcrun simctl launch "$UDID" "$BUNDLE_ID"

echo ""
echo "════════════════════════════════════════════════════"
echo " シミュレータで画面を出し、ここで Enter → 撮影"
echo " q + Enter で終了"
echo " おすすめ順: ①ホーム ②学習カード(表) ③学習カード(裏/評価) "
echo "            ④カテゴリ一覧 ⑤学習カレンダー ⑥検索 or 設定"
echo "════════════════════════════════════════════════════"
i=1
while true; do
  printf "[%02d] Enter=撮影 / q=終了 > " "$i"
  read -r key
  if [ "$key" = "q" ]; then break; fi
  FN=$(printf "%s/%02d.png" "$OUT_DIR" "$i")
  xcrun simctl io "$UDID" screenshot "$FN"
  DIM=$(sips -g pixelWidth -g pixelHeight "$FN" | grep -oE "[0-9]+" | tr '\n' 'x' | sed 's/x$//')
  echo "  ✓ 保存: $FN  ($DIM)"
  i=$((i+1))
done

echo "▶ 完了。撮影ファイル: $OUT_DIR"
ls -la "$OUT_DIR"
