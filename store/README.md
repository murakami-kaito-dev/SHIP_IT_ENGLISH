# store/ — App Store 申請アセット一式

課金なし（無料MVP）でApp Storeに出すために必要な素材をまとめた場所。
手順の全体像は `docs/app_store_free_release_checklist.md`、
Claude 実行用は `.claude/skills/app-store-release`。

## 格納物と App Store Connect での使い道

| パス | 中身 | App Store Connect のどこで使う |
|------|------|------------------------------|
| `metadata/app_store_listing_ja.md` | 日本語のApp名・サブタイトル・説明・キーワード・URL | 「バージョン情報」「App情報」（日本語ローカライズ） |
| `metadata/app_store_listing_en.md` | 英語版の同上 | 同上（英語ローカライズ。プライマリ言語で最低1つ必要） |
| `metadata/app_privacy_and_rating.md` | プライバシー回答・年齢制限アンケート回答・輸出コンプラ | 「Appのプライバシー」「年齢制限」ページの選択肢 |
| `privacy_policy/index.html` | プライバシーポリシー（日英・単一HTML） | **どこかにホストしてURLを「プライバシーポリシーURL」に入力** |
| `icon/app_store_icon_1024.png` | 1024×1024 マーケティング用アイコン（alpha無し） | 「App情報」のApp Store用アイコン（通常はビルドに含まれるので自動。手動要求時に使用） |
| `screenshots/capture.sh` + `README.md` | スクショ撮影スクリプトとサイズ仕様・手順 | 撮影後 `screenshots/out/*.png` を「プレビュー/スクリーンショット」にアップロード |

## やる順番（最短）
1. **プライバシーポリシーをホスト**：`privacy_policy/index.html` を GitHub Pages 等に置き、URLを控える。
2. **スクショを撮る**：`cd store/screenshots && ./capture.sh` → `out/` のPNGを使う（日本語版。英語も出すなら language_mode=en で再実行）。
3. **ビルド＆アップロード**：`flutter build ipa` → Xcode Organizer からアップロード（`docs/app_store_free_release_checklist.md` 参照）。
4. **App Store Connect 入力**：上表のメタデータ・プライバシー回答・スクショ・ポリシーURLを入れて Submit。

## 補足
- 連絡先メールは `mri.benkyochannel@gmail.com` を各所に仮置きしている。変えたい場合は
  `privacy_policy/index.html` と各 metadata を編集。
- サポートURL（必須）とプライバシーポリシーURL（必須）は自分でホストが必要。
  最悪、両方を同じ簡易ページ（連絡先メール＋ポリシー本文）にしてもよい。
- スクショ内の文言・実画面は今後UIを変えたら撮り直すこと。
