# ShipIt English — 実装仕様書（MVP）

> **ドキュメント種別**: Claude Code 向け実装仕様書
> **ステータス**: ドラフト v4
> **対象フェーズ**: Phase 1（MVP）

---

## 1. プロダクト概要

### 1.1 アプリ名（仮）
**ShipIt English**

- パッケージ名: `shipit_english`
- Bundle ID: `com.example.shipitEnglish`（リリース時に変更）

### 1.2 目的
海外テック企業で働くために必要な技術英語を、毎日5〜10分の学習で網羅的に身につけるアプリ。

### 1.3 ターゲットユーザー（MVP）
- 自分自身（個人開発者・エンジニア）
- テック英語の基礎ボキャブラリーが不足している
- 海外テック企業での就業を目指している

### 1.4 MVPのスコープ
SRS（間隔反復）ベースのテック英語カード学習アプリ。
語彙＋例文＋使用場面の文脈をセットで学習し、毎日の習慣化を促す。

### 1.5 MVPに含めないもの（Phase 2以降）
- AI対話・AI解説機能
- シーン別ロールプレイ（Slack、面接など）
- クラウド同期
- テック記事ディスカッション機能
- フレーズブック自動生成

---

## 2. 技術スタック

| 項目 | 選定 |
|------|------|
| フレームワーク | Flutter（iOS / Android） |
| 言語 | Dart |
| 状態管理 | Riverpod（flutter_riverpod + riverpod_annotation） |
| ローカルDB | SQLite（sqflite パッケージ） |
| 設定値保存 | shared_preferences |
| ローカル通知 | flutter_local_notifications |
| ルーティング | go_router |
| テスト | flutter_test + mocktail |

### 2.1 Dart / Flutter バージョン
- Flutter: 3.x stable (latest)
- Dart: 3.x

### 2.2 pubspec.yaml 依存パッケージ

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  sqflite: ^2.3.3+1
  shared_preferences: ^2.2.3
  flutter_local_notifications: ^17.2.1+2
  go_router: ^14.2.0
  path: ^1.9.0
  uuid: ^4.4.0
  intl: ^0.19.0
  timezone: ^0.9.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.3
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^4.0.0
```

**バージョン方針:** `^` でメジャーバージョンを固定。`pub upgrade` は手動で行い、動作確認後に反映する。

---

## 3. ディレクトリ構成

```
shipit_english/
├── lib/
│   ├── main.dart                     # エントリポイント
│   ├── app.dart                      # MaterialApp + GoRouter 設定
│   │
│   ├── core/                         # 横断的な共通機能
│   │   ├── constants/
│   │   │   └── app_constants.dart    # 定数（デフォルト新規カード数 等）
│   │   ├── database/
│   │   │   ├── database_helper.dart  # SQLite 初期化・マイグレーション
│   │   │   └── seed_data.dart        # 初期コンテンツ投入
│   │   ├── services/
│   │   │   ├── notification_service.dart  # 通知管理
│   │   │   └── streak_manager.dart        # ストリーク管理
│   │   ├── theme/
│   │   │   └── app_theme.dart        # テーマ・カラー・タイポグラフィ
│   │   └── utils/
│   │       └── date_utils.dart       # 日付関連ユーティリティ
│   │
│   ├── features/                     # 機能別モジュール
│   │   ├── home/
│   │   │   ├── presentation/
│   │   │   │   └── home_screen.dart
│   │   │   └── providers/
│   │   │       └── home_providers.dart
│   │   │
│   │   ├── study/
│   │   │   ├── data/
│   │   │   │   ├── card_repository.dart       # 抽象クラス
│   │   │   │   └── local_card_repository.dart  # SQLite実装
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── card_model.dart
│   │   │   │   │   ├── learning_progress.dart
│   │   │   │   │   └── study_session.dart
│   │   │   │   └── srs_engine.dart       # SRSアルゴリズム
│   │   │   ├── presentation/
│   │   │   │   ├── study_screen.dart     # カード学習画面
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── flip_card.dart    # フリップカードWidget
│   │   │   │   │   ├── rating_buttons.dart
│   │   │   │   │   └── swipe_card_wrapper.dart  # スワイプ操作Widget
│   │   │   │   └── session_complete_screen.dart
│   │   │   └── providers/
│   │   │       └── study_providers.dart
│   │   │
│   │   ├── categories/
│   │   │   ├── presentation/
│   │   │   │   └── categories_screen.dart
│   │   │   └── providers/
│   │   │       └── categories_providers.dart
│   │   │
│   │   └── settings/
│   │       ├── presentation/
│   │       │   └── settings_screen.dart
│   │       └── providers/
│   │           └── settings_providers.dart
│   │
│   └── shared/                       # 共有Widget
│       └── widgets/
│           ├── streak_badge.dart
│           └── progress_bar.dart
│
├── assets/
│   └── data/
│       └── cards.json                # 初期カードコンテンツ
│
├── test/
│   ├── unit/
│   │   ├── srs_engine_test.dart
│   │   ├── card_repository_test.dart
│   │   ├── streak_test.dart
│   │   └── daily_set_test.dart
│   └── widget/
│       ├── flip_card_test.dart
│       ├── rating_buttons_test.dart
│       └── study_screen_test.dart
│
└── pubspec.yaml
```

---

## 4. デザイントークン・テーマ仕様

### 4.1 カラーパレット

```dart
// lib/core/theme/app_theme.dart

// === Primary ===
static const Color primary = Color(0xFF2563EB);        // Blue-600: メインCTA、進捗バー
static const Color primaryLight = Color(0xFFDBEAFE);   // Blue-100: カテゴリバッジ背景
static const Color primaryDark = Color(0xFF1E40AF);    // Blue-800: アクティブタブ

// === Background ===
static const Color background = Color(0xFFF8FAFC);     // Slate-50: 全画面の背景
static const Color surface = Color(0xFFFFFFFF);         // White: カード・セクション背景
static const Color surfaceBorder = Color(0xFFE2E8F0);  // Slate-200: カードのボーダー

// === Text ===
static const Color textPrimary = Color(0xFF0F172A);    // Slate-900: 見出し・フレーズ
static const Color textSecondary = Color(0xFF475569);   // Slate-600: 本文・説明
static const Color textTertiary = Color(0xFF94A3B8);    // Slate-400: プレースホルダー

// === Rating Buttons ===
static const Color ratingForgot = Color(0xFFEF4444);    // Red-500
static const Color ratingUncertain = Color(0xFFF59E0B);  // Amber-500
static const Color ratingRemembered = Color(0xFF22C55E); // Green-500

// === Streak ===
static const Color streakFire = Color(0xFFF97316);      // Orange-500
static const Color streakInactive = Color(0xFFCBD5E1);  // Slate-300
```

### 4.2 タイポグラフィ

```dart
// フォント: デバイスデフォルト（日英混在のため指定なし）
// fontFamily は設定しない → CupertinoはSF Pro、AndroidはRoboto自動選択

static const TextStyle headingLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary);
static const TextStyle headingMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary);
static const TextStyle phraseText = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary);
static const TextStyle translationText = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary);
static const TextStyle bodyText = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textSecondary);
static const TextStyle captionText = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textTertiary);
static const TextStyle buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
```

### 4.3 コンポーネントスタイル

```dart
// カード
static const double cardBorderRadius = 16.0;
static const double cardElevation = 0;
static const EdgeInsets cardPadding = EdgeInsets.all(24.0);
static final Border cardBorder = Border.all(color: surfaceBorder, width: 1.0);

// ボタン（メインCTA）
static const double buttonBorderRadius = 12.0;
static const double buttonHeight = 56.0;
static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);

// 評価ボタン
static const double ratingButtonHeight = 52.0;
static const double ratingButtonBorderRadius = 12.0;
static const double ratingButtonSpacing = 12.0;

// 画面余白
static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);

// 進捗バー
static const double progressBarHeight = 8.0;
static const double progressBarBorderRadius = 4.0;
```

### 4.4 ダークモード
MVPではライトモードのみ。ダークモード対応は Phase 2 以降。

### 4.5 アプリアイコン・スプラッシュ画面
- **アプリアイコン**: MVPではFlutterデフォルトアイコンを使用。リリース前に差し替え予定
- **スプラッシュ画面**: OSデフォルトの白背景スプラッシュを使用（`flutter_native_splash` は使用しない）

---

## 5. データモデル

### 5.1 SQLite スキーマ

```sql
-- マイグレーションバージョン: 1
-- database_helper.dart で onCreate 時に実行

-- カードマスタデータ
CREATE TABLE cards (
  id            TEXT PRIMARY KEY,
  phrase        TEXT NOT NULL,
  translation   TEXT NOT NULL,
  example       TEXT NOT NULL,
  example_translation TEXT NOT NULL,
  context       TEXT NOT NULL,
  category      TEXT NOT NULL,
  difficulty    INTEGER NOT NULL DEFAULT 1,
  created_at    TEXT NOT NULL
);

-- 学習進捗（SRS状態）
CREATE TABLE learning_progress (
  card_id       TEXT PRIMARY KEY REFERENCES cards(id),
  ease_factor   REAL NOT NULL DEFAULT 2.5,
  interval_days INTEGER NOT NULL DEFAULT 0,
  repetitions   INTEGER NOT NULL DEFAULT 0,
  next_review   TEXT NOT NULL,
  last_reviewed TEXT,
  status        TEXT NOT NULL DEFAULT 'new'
);

-- 日別統計
CREATE TABLE daily_stats (
  date          TEXT PRIMARY KEY,
  cards_studied INTEGER NOT NULL DEFAULT 0,
  cards_correct INTEGER NOT NULL DEFAULT 0,
  new_cards     INTEGER NOT NULL DEFAULT 0,
  review_cards  INTEGER NOT NULL DEFAULT 0,
  study_time_seconds INTEGER NOT NULL DEFAULT 0
);

-- インデックス
CREATE INDEX idx_learning_next_review ON learning_progress(next_review);
CREATE INDEX idx_learning_status ON learning_progress(status);
CREATE INDEX idx_cards_category ON cards(category);
```

### 5.2 データマイグレーション戦略

```dart
// lib/core/database/database_helper.dart

class DatabaseHelper {
  static const int _databaseVersion = 1;
  static const String _databaseName = 'shipit_english.db';

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Phase 2以降でカラム追加時にここにマイグレーションを記述
    // 例: if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE cards ADD COLUMN ai_explanation TEXT');
    // }
  }
}
```

**マイグレーションルール:**
- `_databaseVersion` をインクリメントし、`_onUpgrade` に差分SQLを追加
- カラム追加は `ALTER TABLE ... ADD COLUMN`（SQLiteはカラム削除不可）
- テーブル追加は `CREATE TABLE IF NOT EXISTS`
- 破壊的変更: 新テーブル作成 → データ移行 → 旧テーブル削除

### 5.3 Dart モデルクラス

```dart
// lib/features/study/domain/models/card_model.dart

class TechCard {
  final String id;
  final String phrase;
  final String translation;
  final String example;
  final String exampleTranslation;
  final String context;
  final String category;
  final int difficulty;
  final DateTime createdAt;

  factory TechCard.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }
}
```

```dart
// lib/features/study/domain/models/learning_progress.dart

enum CardStatus { newCard, learning, review, mastered }

class LearningProgress {
  final String cardId;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReview;
  final DateTime? lastReviewed;
  final CardStatus status;

  factory LearningProgress.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }

  factory LearningProgress.initial(String cardId) {
    return LearningProgress(
      cardId: cardId,
      easeFactor: AppConstants.initialEaseFactor,
      intervalDays: 0,
      repetitions: 0,
      nextReview: DateTime.now(),
      lastReviewed: null,
      status: CardStatus.newCard,
    );
  }
}
```

```dart
// lib/features/study/domain/models/study_session.dart

enum Rating { forgot, uncertain, remembered }

class StudySession {
  final DateTime startedAt;
  final List<CardResult> results;

  int get totalCards => results.length;
  int get correctCards => results.where((r) => r.rating == Rating.remembered).length;
  int get uncertainCards => results.where((r) => r.rating == Rating.uncertain).length;
  int get forgotCards => results.where((r) => r.rating == Rating.forgot).length;
  Duration get duration => DateTime.now().difference(startedAt);

  double get accuracy => totalCards > 0
    ? (correctCards + uncertainCards) / totalCards
    : 0.0;
}

class CardResult {
  final String cardId;
  final Rating rating;
  final DateTime answeredAt;
  final bool isRetry;
}
```

---

## 6. SRS アルゴリズム（SM-2 ベース）

### 6.1 評価スケール

| UI表示 | Rating enum | SM-2 quality | 説明 |
|--------|-------------|-------------|------|
| わからなかった | forgot | 1 | 完全に忘れていた |
| あいまい | uncertain | 3 | 見覚えはあるが自信がない |
| わかった | remembered | 5 | すぐに思い出せた |

### 6.2 アルゴリズム擬似コード

```dart
// lib/features/study/domain/srs_engine.dart

class SrsEngine {
  LearningProgress processReview({
    required LearningProgress current,
    required Rating rating,
  }) {
    final int quality = switch (rating) {
      Rating.forgot => 1,
      Rating.uncertain => 3,
      Rating.remembered => 5,
    };

    double newEaseFactor = current.easeFactor;
    int newInterval;
    int newRepetitions;
    CardStatus newStatus;

    if (quality < 3) {
      newRepetitions = 0;
      newInterval = 0;
      newStatus = CardStatus.learning;
    } else {
      newRepetitions = current.repetitions + 1;

      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 3;
      } else {
        newInterval = (current.intervalDays * newEaseFactor).round();
      }

      newEaseFactor = current.easeFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

      if (newEaseFactor < AppConstants.minimumEaseFactor) {
        newEaseFactor = AppConstants.minimumEaseFactor;
      }

      if (newInterval >= AppConstants.masteredThresholdDays) {
        newStatus = CardStatus.mastered;
      } else {
        newStatus = CardStatus.review;
      }
    }

    final DateTime nextReview = quality < 3
        ? DateTime.now()
        : DateTime.now().add(Duration(days: newInterval));

    return LearningProgress(
      cardId: current.cardId,
      easeFactor: newEaseFactor,
      intervalDays: newInterval,
      repetitions: newRepetitions,
      nextReview: nextReview,
      lastReviewed: DateTime.now(),
      status: newStatus,
    );
  }
}
```

### 6.3 デイリーセット取得ロジック

```dart
/// デイリーセットの構成ルール:
/// 1. 復習カード: next_review <= 今日 のもの全て（上限なし）
/// 2. 新規カード: status == 'new' のものから maxNewCards 枚
/// 3. 順序: 復習と新規をシャッフルして混在させる
/// 4. 復習0枚 & 新規0枚の場合: 空リストを返す
Future<List<TechCard>> getDailySet({
  required int maxNewCards,
  required CardRepository repository,
}) async {
  final today = DateTime.now();
  final reviewCards = await repository.getCardsForReview(today);
  final newCards = await repository.getNewCards(limit: maxNewCards);
  return [...reviewCards, ...newCards]..shuffle();
}
```

### 6.4 SRS ユニットテスト仕様

以下のケースを必ずテストする:

1. 新規カードに「わかった」→ interval = 1日, repetitions = 1
2. 1回正答済みカードに「わかった」→ interval = 3日, repetitions = 2
3. 2回正答済みカードに「わかった」→ interval = (前回interval × ease_factor) を round
4. 任意の状態で「わからなかった」→ repetitions = 0, interval = 0
5. 「あいまい」→ 正解扱いだがease_factorの上昇が小さい
6. ease_factorが1.3を下回らないこと
7. interval >= 21日 で mastered ステータスになること
8. mastered状態のカードに「わからなかった」→ learning に戻ること

---

## 7. 画面仕様

### 7.1 ホーム画面 (`home_screen.dart`)

```
┌─────────────────────────────┐
│         ShipIt English       │
│                              │
│   🔥 12 day streak           │
│                              │
│  ┌────────────────────────┐  │
│  │ Today's Session        │  │
│  │                        │  │
│  │  New:    5 cards       │  │
│  │  Review: 8 cards       │  │
│  │  Total:  13 cards      │  │
│  │  Est:    ~6 min        │  │
│  └────────────────────────┘  │
│                              │
│   [ ▶ Start Learning ]       │
│                              │
│  ┌────────────────────────┐  │
│  │ Progress               │  │
│  │  Mastered: 34 / 200    │  │
│  │  ████████░░░░░  17%    │  │
│  └────────────────────────┘  │
│                              │
│  ─── ─── ─── ─── ─── ───    │
│  🏠    📚    ⚙️              │
│  Home  Cats  Settings        │
└─────────────────────────────┘
```

**表示要素:**
- ストリーク表示（連続学習日数、炎アイコン）
- 今日のセッション概要（新規/復習/合計カード数、推定所要時間）
- 推定所要時間の計算: カード枚数 × 30秒
- 学習開始ボタン
- 全体進捗バー（mastered / 全カード数）

**条件分岐表示:**

| 状態 | 表示内容 |
|------|---------|
| 今日未学習 & カードあり | 通常表示 + 「Start Learning」ボタン |
| 今日学習済み | 「✅ Today's session complete!」+ 「Review again」ボタン |
| 全カード mastered | 「🎊 All cards mastered!」+ 「Review weak cards」ボタン（ease_factor が低い順に20枚） |

**「Review again」ボタンの挙動:**
- タップ時、デイリーセットを**再生成**する（復習対象の再取得 + 新規カードは追加しない）
- 復習対象がない場合（全て今日以降にスケジュール済み）: 「No cards to review right now」トースト表示、セッションは開始しない
- 2回目以降のセッション完了は daily_stats の `cards_studied` / `cards_correct` に**加算**する
- ストリークは1日1回のみ加算（既に加算済みなら再加算しない）

### 7.2 カード学習画面 (`study_screen.dart`)

**■ 表面（フリップ前）**
```
┌─────────────────────────────┐
│  ← Back          3 / 13     │
│                              │
│  ┌────────────────────────┐  │
│  │                        │  │
│  │                        │  │
│  │   "LGTM with a nit"   │  │  ← phraseText
│  │                        │  │
│  │     [ Code Review ]    │  │  ← カテゴリバッジ
│  │                        │  │
│  └────────────────────────┘  │
│                              │
│      Tap or swipe to flip    │  ← captionText
│                              │
└─────────────────────────────┘
```

**■ 裏面（フリップ後）**
```
┌─────────────────────────────┐
│  ← Back          3 / 13     │
│                              │
│  ┌────────────────────────┐  │  ← SingleChildScrollView
│  │  "LGTM with a nit"    │  │  ← bodyText（小さく）
│  │  ─────────────────     │  │  ← Divider
│  │                        │  │
│  │  おおむね問題ないが、     │  │  ← translationText
│  │  細かい指摘がある        │  │
│  │                        │  │
│  │  💬 Example            │  │  ← captionText ラベル
│  │  "LGTM with a nit —    │  │  ← bodyText（イタリック）
│  │   can you rename this   │  │
│  │   variable to be more   │  │
│  │   descriptive?"         │  │
│  │                        │  │
│  │  おおむねOKだけど、この   │  │  ← bodyText
│  │  変数名をもっとわかり    │  │
│  │  やすく変えてほしい      │  │
│  │                        │  │
│  │  📍 使用場面            │  │  ← captionText ラベル
│  │  PRを承認しつつ軽微な    │  │  ← bodyText
│  │  修正を求める際に使用。  │  │
│  │  nitは"nitpick"の略。   │  │
│  └────────────────────────┘  │
│                              │
│  ┌──────┬──────┬──────────┐  │  ← 画面下部固定
│  │  ✗   │  △   │    ◎     │  │
│  │ 忘れた │ 曖昧  │ 覚えてた  │  │
│  └──────┴──────┴──────────┘  │
└─────────────────────────────┘
```

**カード裏面のレイアウトルール:**
- カード裏面全体は `SingleChildScrollView` でスクロール可能
- 評価ボタンはスクロール領域の外、画面下部に固定配置
- 表示優先順位: ①日本語訳 → ②例文 → ③例文訳 → ④使用場面

**操作仕様:**

| 操作 | 状態 | 動作 |
|------|------|------|
| タップ | 表面表示中 | 裏面にフリップ |
| 上方向スワイプ | 表面表示中 | 裏面にフリップ |
| タップ | 裏面表示中 | 何もしない |
| 左スワイプ | 裏面表示中 | 「忘れた」として評価 |
| 右スワイプ | 裏面表示中 | 「覚えてた」として評価 |
| 評価ボタンタップ | 裏面表示中 | 対応する評価で処理 |

**スワイプ操作の詳細仕様:**
- 確定閾値: 画面幅の **30%** 以上ドラッグで確定
- 閾値未満でリリース: スナップバック（200ms）
- スワイプ中のビジュアルフィードバック:
  - 左ドラッグ: カード左傾き（最大-15度）、背景 `ratingForgot` 10%透明度、左上に ✗ フェードイン
  - 右ドラッグ: カード右傾き（最大+15度）、背景 `ratingRemembered` 10%透明度、右上に ◎ フェードイン
  - フィードバック強度はドラッグ距離に線形比例

**フリップアニメーション:** Y軸回転3Dフリップ、300ms、`Curves.easeInOut`

**次のカード遷移:** 評価確定後スライドアウト（200ms）→ 次カード右からスライドイン（250ms）→ 必ず**表面**から開始

**進捗カウンター（"3 / 13"）:**
- 分母 = セッション開始時のユニークカード枚数（再出題含めない）
- 分子 = 評価済みユニークカード数（再出題は増やさない）

**「忘れた」カード再出題ルール:**
- キュー末尾に再追加、同一カード再出題上限 **2回**（初回含め最大3回）
- 再出題も表面から開始、`CardResult.isRetry = true` で記録
- セッション完了統計: Studied = ユニーク数、Correct = 最終評価が remembered/uncertain のユニーク数

### 7.3 セッション完了画面 (`session_complete_screen.dart`)

```
┌─────────────────────────────┐
│                              │
│           🎉                 │
│                              │
│     Session Complete!        │
│                              │
│   ┌──────────────────────┐   │
│   │  Studied:  13 cards  │   │
│   │  Correct:  10 (77%)  │   │
│   │  Time:     5:32      │   │
│   │  Streak:   12 days 🔥│   │
│   └──────────────────────┘   │
│                              │
│   New words learned: 5       │
│   Reviews completed: 8       │
│                              │
│   [ Back to Home ]           │
│                              │
└─────────────────────────────┘
```

**表示要素:**
- Studied / Correct / Time / Streak / New / Reviews の各値
- 正答率 = Correct / Studied

**遷移:**
- 「Back to Home」→ `context.go('/')`（スタックリセット）
- 戻るボタン（物理/ジェスチャー）も同様にホームへ

### 7.4 カテゴリ一覧画面 (`categories_screen.dart`)

- カテゴリ名＋アイコン＋進捗バー（mastered / 全カード数）
- MVPではタップ不可
- 進捗バー色: `primary` + `surfaceBorder`

### 7.5 設定画面 (`settings_screen.dart`)

| 設定項目 | Widget | デフォルト | 保存キー | 説明 |
|---------|--------|----------|---------|------|
| 1日の新規カード数 | Slider（1〜20） | 5 | `new_cards_per_day` | 横に現在値表示 |
| リマインダー通知 | SwitchListTile | true | `reminder_enabled` | ON/OFF |
| リマインダー時刻 | ListTile → showTimePicker | 08:00 | `reminder_hour`, `reminder_minute` | OFF時グレーアウト |
| 学習データリセット | ListTile（destructive） | — | — | 確認ダイアログ→全DELETE+再シード |

---

## 8. アプリ起動・初期化フロー

### 8.1 起動シーケンス

```dart
// lib/main.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. SQLite 初期化
  final db = await DatabaseHelper().initialize();

  // 2. シードデータ投入（初回 or バージョン更新時のみ）
  await SeedData(db).seed();

  // 3. ストリークチェック（2日以上空いていればリセット）
  await StreakManager().checkAndUpdateStreak();

  // 4. 通知スケジュール設定
  await NotificationService().initialize();
  await NotificationService().scheduleDailyReminder();

  // 5. UI起動
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const ShipItEnglishApp(),
    ),
  );
}
```

### 8.2 起動中のUI
- 初期化中はOSデフォルトのスプラッシュ画面を表示
- 初期化エラー時: エラー画面に「再試行」ボタンを配置

### 8.3 初期化の依存関係

```
SQLite初期化
    ↓
シードデータ投入（SQLiteに依存）
    ↓
ストリークチェック（shared_preferencesに依存）
    ↓
通知スケジュール（shared_preferencesに依存）
    ↓
UI起動（全初期化完了後）
```

---

## 9. Riverpod プロバイダー設計

### 9.1 プロバイダー一覧

```dart
// === アプリ全体スコープ（ProviderScope直下） ===

final databaseProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalCardRepository(db);
});

final srsEngineProvider = Provider<SrsEngine>((ref) => SrsEngine());

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});


// === ホーム画面 ===

final dailySessionInfoProvider = FutureProvider<DailySessionInfo>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  final settings = ref.watch(settingsProvider);
  // 新規カード数、復習カード数、推定時間、ストリーク情報を返す
});

final overallProgressProvider = FutureProvider<OverallProgress>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  // mastered数、全カード数を返す
});


// === 学習画面（セッション中のみ生存） ===

final studySessionProvider = StateNotifierProvider.autoDispose<StudySessionNotifier, StudySessionState>((ref) {
  final repo = ref.watch(cardRepositoryProvider);
  final srs = ref.watch(srsEngineProvider);
  return StudySessionNotifier(repo, srs);
});

// === セッション完了画面用（学習画面で確定した結果を保持） ===

final lastSessionResultProvider = StateProvider<SessionResult?>((ref) => null);
```

### 9.2 セッション完了データの受け渡し

```dart
/// 学習画面 → セッション完了画面へのデータ受け渡し方式:
///
/// studySessionProvider は autoDispose のため、画面遷移時に破棄される。
/// そのため、セッション完了時に結果を lastSessionResultProvider に書き込み、
/// SessionCompleteScreen はそこから読み取る。
///
/// フロー:
/// 1. StudySessionNotifier が全カード評価完了を検知
/// 2. SessionResult を生成し、ref.read(lastSessionResultProvider.notifier).state に書き込み
/// 3. daily_stats をDBに保存
/// 4. ストリークを更新
/// 5. context.go('/session-complete') で遷移
/// 6. SessionCompleteScreen が lastSessionResultProvider から結果を読み取り表示
/// 7. 「Back to Home」タップ時に lastSessionResultProvider を null にリセット

class SessionResult {
  final int studiedCount;       // ユニークカード数
  final int correctCount;       // remembered + uncertain のユニーク数
  final int newCardsCount;
  final int reviewCardsCount;
  final Duration duration;
  final int streakCount;
}
```

### 9.3 StudySessionState の構造

```dart
class StudySessionState {
  final List<TechCard> queue;
  final TechCard? currentCard;
  final bool isFlipped;
  final int completedCount;
  final int totalUniqueCount;
  final StudySession session;
  final Map<String, int> retryCount;
  final StudyPhase phase;
}

enum StudyPhase { studying, completed }
```

### 9.4 autoDispose の使い方

| プロバイダー | autoDispose | 理由 |
|-------------|-------------|------|
| databaseProvider | No | アプリ全体で共有 |
| cardRepositoryProvider | No | アプリ全体で共有 |
| srsEngineProvider | No | ステートレス |
| settingsProvider | No | アプリ全体で共有 |
| dailySessionInfoProvider | No | ホーム画面で常に参照 |
| lastSessionResultProvider | No | 画面遷移後も保持が必要 |
| studySessionProvider | **Yes** | 学習画面離脱時に破棄 |

---

## 10. ルーティング・ナビゲーション

### 10.1 ルート定義

```dart
// lib/app.dart

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
    GoRoute(path: '/study', builder: (_, __) => const StudyScreen()),
    GoRoute(path: '/session-complete', builder: (_, __) => const SessionCompleteScreen()),
  ],
);
```

### 10.2 AppShell と BottomNavigationBar

```dart
// lib/app.dart

class AppShell extends StatelessWidget {
  final Widget child;

  /// 現在のパスからタブインデックスを決定
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/categories') return 1;
    if (location == '/settings') return 2;
    return 0; // '/' → Home
  }

  /// タブタップ時のナビゲーション
  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/categories');
      case 2: context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        selectedItemColor: AppTheme.primaryDark,
        unselectedItemColor: AppTheme.textTertiary,
        backgroundColor: AppTheme.surface,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
```

### 10.3 ナビゲーションルール

| 遷移 | メソッド | 理由 |
|------|---------|------|
| ホーム → 学習画面 | `context.push('/study')` | スタックに積む（Backで戻れる） |
| 学習画面 → セッション完了 | `context.go('/session-complete')` | 学習画面をスタックから除去 |
| セッション完了 → ホーム | `context.go('/')` | スタック全リセット |
| タブ間の切り替え | `context.go('/...')` | ShellRoute内の切り替え |

---

## 11. 通知・リマインダー仕様

### 11.1 デイリーリマインダー
- パッケージ: `flutter_local_notifications`
- デフォルト: 毎日08:00にローカル通知
- 通知テキスト: `"Today's tech English session is ready! 🚀"`
- `zonedSchedule` + `matchDateTimeComponents: DateTimeComponents.time`
- 設定変更時: 既存通知キャンセル → 再スケジュール

### 11.2 通知チャネル設定（Android）
- チャネルID: `daily_reminder`
- チャネル名: `Daily Reminder`
- 重要度: `Importance.defaultImportance`

### 11.3 iOS 通知権限
- 初回起動時に権限リクエスト
- 拒否時: リマインダーSwitchをOFFにし、メッセージ表示

### 11.4 ストリーク管理ロジック

```dart
/// アプリ起動時に呼び出す
void checkAndUpdateStreak() {
  final lastDate = prefs.getString('last_study_date');
  final today = DateTime.now().toDateString();

  if (lastDate == null) return; // 初回起動

  final daysDiff = today.difference(lastDate).inDays;
  if (daysDiff >= 2) {
    prefs.setInt('streak_count', 0); // リセット
  }
}

/// セッション完了時に呼び出す
void recordStudyCompletion() {
  final today = DateTime.now().toDateString();
  final lastDate = prefs.getString('last_study_date');

  if (lastDate != today) {
    final currentStreak = prefs.getInt('streak_count') ?? 0;
    prefs.setInt('streak_count', currentStreak + 1);
    prefs.setString('last_study_date', today);
  }
  // lastDate == today の場合: 2回目以降のセッション。ストリーク加算しない
}
```

---

## 12. コンテンツデータ仕様

### 12.1 JSONスキーマ (`assets/data/cards.json`)

```json
{
  "version": "1.0.0",
  "categories": [
    {
      "id": "code_review",
      "name": "Code Review",
      "icon": "💬",
      "description": "コードレビューで使う表現"
    }
  ],
  "cards": [
    {
      "id": "cr_001",
      "phrase": "LGTM with a nit",
      "translation": "おおむね問題ないが、細かい指摘がある",
      "example": "LGTM with a nit — can you rename this variable to be more descriptive?",
      "example_translation": "おおむねOKだけど、この変数名をもっとわかりやすく変えてほしい",
      "context": "PRを承認しつつ軽微な修正を求める際に使用。nitは\"nitpick\"（重箱の隅をつつく）の略。",
      "category": "code_review",
      "difficulty": 1
    }
  ]
}
```

### 12.2 JSON バリデーション・投入ロジック

```dart
/// バリデーションルール:
/// - 必須フィールド: id, phrase, translation, example, example_translation, context, category
/// - id重複: 後勝ち（INSERT OR REPLACE）
/// - categoryが未登録: そのカードをスキップしログ出力
/// - difficulty範囲外: デフォルト値 1 にフォールバック
///
/// バージョン管理:
/// - 'seed_version' と JSON の 'version' を比較
/// - 異なる場合: INSERT OR IGNORE で既存IDの学習進捗は保持
///
/// エラーハンドリング:
/// - JSONパースエラー: アプリ起動は継続、ログ出力、ホームに「コンテンツ読み込み失敗」表示
/// - 個別バリデーションエラー: そのカードのみスキップ
```

### 12.3 MVPで用意するカテゴリと目標枚数

| カテゴリ | ID | 目標枚数 | 優先度 |
|---------|-----|---------|--------|
| Code Review | code_review | 25枚 | ★★★ |
| Git / CI/CD | git_cicd | 20枚 | ★★★ |
| Meetings / Standup | meetings | 20枚 | ★★☆ |
| Slack Communication | slack | 20枚 | ★★☆ |
| Architecture / Design | architecture | 20枚 | ★★☆ |
| Incident Response | incident | 15枚 | ★☆☆ |
| Tech Interview | interview | 15枚 | ★☆☆ |
| **合計** | | **135枚** | |

---

## 13. エッジケース・境界条件

### 13.1 セッション中の離脱

| パターン | 動作 |
|---------|------|
| Backボタン/ジェスチャー | 確認ダイアログ→OK: 評価済み分をDB保存してホームへ / キャンセル: 継続 |
| バックグラウンド移行 | メモリ保持。フォアグラウンド復帰時にそのまま継続 |
| アプリkill | セッション消失。ただし評価済み分は評価時点でDB保存済み。未評価は次回再出現 |

### 13.2 日付またぎ

| シナリオ | 動作 |
|---------|------|
| 23:58開始 → 0:02完了 | セッション開始日で記録。ストリークは開始日分として加算 |
| セッション中に日付変更後、長時間放置して再開 | セッション継続。記録は `startedAt` の日付ベース |

**ルール: セッションの日付は常に `StudySession.startedAt` の日付を使用。**

### 13.3 その他のエッジケース

| シナリオ | 動作 |
|---------|------|
| 復習0 & 新規0（全mastered） | ホームに「🎊 All cards mastered!」表示 |
| 復習カード大量（1週間放置等） | 上限なし。推定時間で心理的準備を促す |
| 全カード「忘れた」評価 | 再出題上限到達でセッション完了 |
| JSONに0枚カテゴリ | カテゴリ一覧に「0 / 0」で表示 |

---

## 14. Repository 抽象化

```dart
// lib/features/study/data/card_repository.dart

abstract class CardRepository {
  Future<List<TechCard>> getCardsForReview(DateTime asOf);
  Future<List<TechCard>> getNewCards({required int limit});
  Future<List<TechCard>> getAllCards();
  Future<List<TechCard>> getCardsByCategory(String categoryId);
  Future<TechCard?> getCard(String id);
  Future<void> upsertCard(TechCard card);
  Future<LearningProgress?> getProgress(String cardId);
  Future<void> saveProgress(LearningProgress progress);
  Future<Map<String, int>> getCategoryProgress();
  Future<int> getTotalMasteredCount();
  Future<int> getTotalCardCount();
  Future<void> saveDailyStats(DailyStats stats);
  Future<void> resetAllData();
}
```

```dart
// lib/features/study/data/local_card_repository.dart

class LocalCardRepository implements CardRepository {
  final DatabaseHelper _db;
  // ...
}
```

---

## 15. アクセシビリティ方針（MVP）

### 15.1 最低限の対応

| 項目 | 方針 |
|------|------|
| セマンティクスラベル | カード表面・裏面、評価ボタン、進捗カウンターに `Semantics` ウィジェットを付与 |
| フォントスケーリング | `MediaQuery.textScaleFactor` に対応。レイアウトが崩れないよう、カード裏面は `SingleChildScrollView` で吸収 |
| カラーコントラスト | WCAG AA基準（4.5:1以上）を満たす。上記カラーパレットは基準クリア済み |
| タッチターゲット | 全タップ可能要素は最小 48x48dp を確保 |

### 15.2 MVP対象外（Phase 2以降）
- VoiceOver / TalkBack での完全なナビゲーション最適化
- ダイナミックタイプ対応
- ハイコントラストモード

---

## 16. テスト戦略

### 16.1 ユニットテスト（必須）

| テスト対象 | ファイル | カバレッジ目標 |
|-----------|---------|---------------|
| SRSアルゴリズム | `srs_engine_test.dart` | 100% |
| CardRepository | `card_repository_test.dart` | 90%+ |
| ストリーク計算 | `streak_test.dart` | 100% |
| デイリーセット取得 | `daily_set_test.dart` | 90%+ |

### 16.2 Widgetテスト（主要画面）

| テスト対象 | 検証内容 |
|-----------|---------|
| FlipCard | タップでフリップ、表裏の表示切替 |
| RatingButtons | 3ボタンが正しくコールバック発火 |
| StudyScreen | カード遷移、セッション完了への遷移 |
| HomeScreen | セッション情報の表示、ストリーク表示 |

### 16.3 テスト実行コマンド
```bash
flutter test
flutter test test/unit/
flutter test --coverage
```

---

## 17. 定数定義

```dart
// lib/core/constants/app_constants.dart

class AppConstants {
  // SRS
  static const double initialEaseFactor = 2.5;
  static const double minimumEaseFactor = 1.3;
  static const int masteredThresholdDays = 21;
  static const int maxRetriesPerSession = 2;

  // Daily session
  static const int defaultNewCardsPerDay = 5;
  static const int minNewCardsPerDay = 1;
  static const int maxNewCardsPerDay = 20;
  static const int estimatedSecondsPerCard = 30;

  // Notification
  static const int defaultReminderHour = 8;
  static const int defaultReminderMinute = 0;
  static const String notificationChannelId = 'daily_reminder';
  static const String notificationChannelName = 'Daily Reminder';

  // Swipe
  static const double swipeConfirmThreshold = 0.30;
  static const double swipeMaxRotationDegrees = 15.0;
  static const Duration swipeSnapBackDuration = Duration(milliseconds: 200);
  static const Duration flipDuration = Duration(milliseconds: 300);
  static const Duration slideOutDuration = Duration(milliseconds: 200);
  static const Duration slideInDuration = Duration(milliseconds: 250);

  // shared_preferences keys
  static const String keyStreakCount = 'streak_count';
  static const String keyLastStudyDate = 'last_study_date';
  static const String keySeedVersion = 'seed_version';
  static const String keyNewCardsPerDay = 'new_cards_per_day';
  static const String keyReminderEnabled = 'reminder_enabled';
  static const String keyReminderHour = 'reminder_hour';
  static const String keyReminderMinute = 'reminder_minute';
}
```

---

## 18. 将来の拡張に向けた設計考慮

1. **AI解説機能（Phase 2）**: `TechCard` にオプショナルな `aiExplanation` を追加可能に。カード裏面に「もっと詳しく」ボタン配置想定（MVPでは非表示）
2. **クラウド同期（Phase 3）**: `CardRepository` 抽象化済み。`RemoteCardRepository` を差し替え可能
3. **コンテンツ追加**: JSONバージョン管理で将来的にサーバー差分配信に切り替え可能
4. **ロールプレイ機能（Phase 3）**: `features/` に独立モジュールとして追加可能

---

## 19. 開発タスク（MVP）

| # | タスク | 依存 | 概算工数 |
|---|--------|------|---------|
| 1 | Flutter プロジェクトセットアップ + pubspec.yaml | — | 0.5日 |
| 2 | テーマ・定数・ユーティリティ | 1 | 0.5日 |
| 3 | SQLite セットアップ + マイグレーション基盤 | 1 | 0.5日 |
| 4 | データモデル（Dart クラス + fromMap/toMap） | 3 | 0.5日 |
| 5 | CardRepository 抽象 + LocalCardRepository 実装 | 3, 4 | 1日 |
| 6 | SRS エンジン実装 | 4 | 1日 |
| 7 | SRS ユニットテスト | 6 | 0.5日 |
| 8 | 初期コンテンツ JSON 作成（135枚） | — | 2日 |
| 9 | シードデータ投入（バリデーション含む） | 3, 8 | 0.5日 |
| 10 | アプリ起動・初期化フロー（main.dart） | 3, 9 | 0.5日 |
| 11 | ルーティング + AppShell + BottomNav | 1 | 0.5日 |
| 12 | Riverpod プロバイダー設計・実装 | 5, 6 | 0.5日 |
| 13 | ホーム画面（条件分岐 + Review again含む） | 5, 11, 12 | 1日 |
| 14 | カード学習画面（フリップ + スワイプ + 評価UI + 再出題） | 5, 6, 12 | 2.5日 |
| 15 | セッション完了画面 + データ受け渡し | 14, 12 | 0.5日 |
| 16 | カテゴリ一覧画面 | 5, 11, 12 | 0.5日 |
| 17 | 設定画面（リセット確認ダイアログ含む） | 11, 12 | 0.5日 |
| 18 | ストリーク管理ロジック | 5 | 0.5日 |
| 19 | ローカル通知（iOS権限リクエスト含む） | 17 | 1日 |
| 20 | アクセシビリティ（Semantics, タッチターゲット） | 13-17 | 0.5日 |
| 21 | エッジケース対応（離脱確認、日付またぎ、空セッション） | 13, 14 | 0.5日 |
| 22 | Widget テスト | 13-17 | 1日 |
| 23 | 統合テスト + バグ修正 | all | 1.5日 |
| | **合計** | | **約17.5日** |

---

## 20. 補足: フェーズ全体ロードマップ

```
Phase 1 (MVP) ─── 本ドキュメントの範囲
  SRS語彙学習 + デイリーセッション + ストリーク + ローカル通知

Phase 2 ─── AI解説 + コンテキスト学習
  AI解説機能（カード裏面の「もっと詳しく」）
  テック記事ディスカッション（AI対話）
  コードレビュー/Slackシーンの追加コンテンツ
  ダークモード対応

Phase 3 ─── アウトプット実践 + クラウド
  シーン別ロールプレイ（Slack, テック面接）
  デイリーミッション
  クラウド同期
  フレーズブック自動生成
  学習分析ダッシュボード
```
