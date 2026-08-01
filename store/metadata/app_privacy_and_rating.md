# App Privacy & 年齢制限（App Store Connect 回答集）

App Store Connect の「App のプライバシー」「年齢制限」で選ぶ回答。
このアプリは**ネットワーク通信なし・データ収集なし・トラッキングなし**なので、
`ios/Runner/PrivacyInfo.xcprivacy` の申告と下記が一致する。

## App のプライバシー（Data Collection）

- **Data Collection**: 「**No, we do not collect data from this app**（このAppからデータを収集していません）」を選択。
  - アカウント登録なし／解析SDKなし／広告なし／サーバー送信なし。学習データは端末内SQLiteのみ。
- したがって追加のデータ種別入力は不要。

## トラッキング

- ATT（App Tracking Transparency）: 使用しない（IDFA未使用・トラッキングなし）。
  - `PrivacyInfo.xcprivacy` の `NSPrivacyTracking = false` と一致。

## 年齢制限（Age Rating）アンケートの回答（すべて「なし／None」）

| 質問 | 回答 |
|------|------|
| 暴力（漫画・現実的） | なし |
| 性的・ヌード表現 | なし |
| 冒涜的・下品なユーモア | なし |
| アルコール・タバコ・薬物 | なし |
| ギャンブル（シミュレート含む） | なし |
| 恐怖・ホラー | なし |
| 医療・治療情報 | なし |
| 制限なしWebアクセス | なし（アプリ内ブラウザなし） |
| ユーザー生成コンテンツ | なし |
| → 結果 | **4+** |

## 輸出コンプライアンス（毎回聞かれる暗号化の質問）

- `Info.plist` に `ITSAppUsesNonExemptEncryption = false` を設定済みのため、
  アップロード時に**この質問は自動でスキップ**される（追加操作不要）。

## サインイン要件

- レビュー時のデモアカウント: **不要**（ログイン機能なし）。
- 「App 内課金」: **なし**（無料MVP。課金は休眠中）。
