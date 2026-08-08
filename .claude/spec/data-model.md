# Data Model — カード・DB・モデル・設定キー

## カード本体 `assets/data/cards.json`（唯一の正）
トップ構造：`{ "version", "categories": [...], "cards": [...] }`。1913枚 / 14カテゴリ / v2.0.0。
1カード：
```json
{ "id":"cr_001", "phrase":"LGTM with a nit", "translation":"おおむね問題ないが…",
  "example":"LGTM with a nit — can you rename…", "example_translation":"おおむねOKだけど…",
  "context":"…使用場面(日本語)", "context_en":"…usage(English・省略可)",
  "category":"code_review", "difficulty":1 }
```
- `context_en` 省略時は空→ `context`(日本語)にフォールバック。
- **cards.json を変えたら `version` を必ず上げる**（seed_data がversion比較で差分投入。上げ忘れるとDB未反映）。
- 削除したカードはDBからも自動削除（cards.json が正）。
- カテゴリを追加したら `categories_providers.dart` の `categoryDefs` にも追加。

### 14カテゴリID
`code_review, meetings, slack, git_cicd, architecture, incident, interview, planning, career, remote_work, documentation, tech_debt, qa_testing, security`
無料/Pro境界は `MonetizationConfig.freeCategoryIds`（無料=code_review/meetings/slack。休眠中は全開放）。

## SQLite スキーマ（[core/database/database_helper.dart](../../lib/core/database/database_helper.dart)）
- **cards**：`id PK, phrase, translation, example, example_translation, context, context_en, category, difficulty, card_number, created_at`
  - `card_number`：カテゴリごとの通し番号。seed時に cards.json の並び順で1から採番（順序入替で番号が変わる／追加は末尾）。
- **learning_progress**：`card_id PK, ease_factor(2.5), interval_days(0), repetitions(0), next_review, last_reviewed, status('new'), last_rating`
  - `status`：new/learning/review/mastered（SRS内部状態。画面には出さない）。
  - `last_rating`：forgot/uncertain/remembered（画面表示はこれベース。未評価=null=未学習）。
- **daily_stats**：`date PK, cards_studied, cards_correct, new_cards, review_cards, study_time_seconds`（当日分は加算保存）。
- **新フィールド追加時**：cards.json + `card_model.dart` + `seed_data.dart` + `database_helper.dart`（DBバージョン++＆マイグレーション）の4点セット。

## ドメインモデル（[features/study/domain/models/](../../lib/features/study/domain/models/)）
- **TechCard**（card_model.dart）：id, phrase, translation, example, exampleTranslation, context, contextEn, category, difficulty, cardNumber, createdAt。
- **LearningProgress**：SRS状態（上記 learning_progress に対応）。`initial(cardId)` で新規。
- **StudySession**（study_session.dart）：`startedAt`, `results:List<CardResult>`, `duration`。
  - **Rating** enum：forgot / uncertain / remembered。**CardStatus** enum：new/learning/review/mastered。
- **DailyStats**：daily_stats に対応。

## SharedPreferences キー（[app_constants.dart](../../lib/core/constants/app_constants.dart)）
`streak_count, last_study_date, seed_version, new_cards_per_day, reminder_enabled,
reminder_hour, reminder_minute, language_mode, onboarding_done, review_requested,
pro_entitlement, entitlement_verified_at, gamification_total_xp`
（shared_preferences はiOS上で実キーに `flutter.` を前置する点に注意＝シミュレータ等で直接書く場合）。

## 集計プロバイダー（キャッシュに注意）
Home/カテゴリの集計は FutureProvider（autoDispose無し）でキャッシュ。学習進捗を変えたら
必ず `invalidateProgressProviders(ref)`（[progress_refresh.dart](../../lib/core/providers/progress_refresh.dart)）を呼ぶ。
対象：dailySessionInfo / overallProgress / weeklyStats / categories / studyDays /
categoryCards / filteredCards / searchResults。
