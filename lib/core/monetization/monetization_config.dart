/// サブスクリプション（ShipIt Pro）の設定。
///
/// ═══════════════════════════════════════════════════════════════
///  マスタースイッチ（有効化手順）
/// ═══════════════════════════════════════════════════════════════
/// 下の `subscriptionEnabled` を true にするだけで、以下がすべて有効になる:
///   - カテゴリのロック（無料は code_review / meetings / slack のみ）
///   - 新規カード枚数の上限（無料は 5枚/日）
///   - カテゴリ集中学習の Pro 限定化
///   - パウォール画面（/paywall）への導線・購入・復元
///
/// false の間は現在のアプリと完全に同一の動作（全機能無料開放）。
///
/// ★ 有効化する前に必ず docs/subscription_setup_guide.md の
///   チェックリストを完了させること（App Store Connect の商品登録、
///   privacyPolicyUrl の設定など）。
/// ═══════════════════════════════════════════════════════════════
class MonetizationConfig {
  // ↓↓↓ 有効化するときは false を true に変更する（これが唯一のスイッチ） ↓↓↓
  static const bool subscriptionEnabled = false;
  // ↑↑↑ ═══════════════════════════════════════════════════════ ↑↑↑

  /// 無料プランで開放するカテゴリ（習慣形成の入口。65枚）
  /// Pro限定: architecture / git_cicd / incident / interview（緊急性が高く課金動機が強い）
  static const Set<String> freeCategoryIds = {
    'code_review',
    'meetings',
    'slack',
  };

  /// 無料プランの新規カード上限（枚/日）。Proは AppConstants.maxNewCardsPerDay まで
  static const int freeMaxNewCardsPerDay = 5;

  /// App Store Connect に登録するプロダクトID（完全一致が必須）
  static const String monthlyProductId = 'shipit_pro_monthly';
  static const String yearlyProductId = 'shipit_pro_yearly';
  static const Set<String> productIds = {monthlyProductId, yearlyProductId};

  /// 権利の再検証を行う間隔。これより古い検証結果しかなければ起動/復帰時に再検証する
  static const Duration entitlementRecheckInterval = Duration(hours: 12);

  /// 検証が一度も成功しないまま この期間 を過ぎたら Pro を失効させる。
  /// オフラインや一時的なストア障害で即座に剥奪しないための猶予。
  static const Duration entitlementGracePeriod = Duration(days: 7);

  /// 復元結果を待つ時間（これを過ぎても対象商品が返らなければ「権利なし」と判定）
  static const Duration entitlementVerifyTimeout = Duration(seconds: 10);

  /// サブスクリプションの管理・解約画面（App Store 共通）
  static const String manageSubscriptionsUrl =
      'https://apps.apple.com/account/subscriptions';

  /// パウォールに必須のリンク（App Store Review Guideline 3.1.2）
  /// ★ 有効化前に privacyPolicyUrl を実際に公開したURLへ差し替えること
  static const String privacyPolicyUrl =
      'https://example.github.io/shipit-english-privacy/'; // TODO: 差し替え
  static const String termsOfUseUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
}
