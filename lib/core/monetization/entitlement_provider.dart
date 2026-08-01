import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/monetization/purchase_service.dart';

/// Pro権利の保持状態（端末内に永続化）。
/// 購入/復元成功時に PurchaseService から setPro(true) が呼ばれ、
/// 定期的な再検証（[verify]）で解約・期限切れを検出して false に戻す。
class EntitlementNotifier extends StateNotifier<bool> {
  EntitlementNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppConstants.keyProEntitlement) ?? false;
  }

  Future<void> setPro(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyProEntitlement, value);
    if (value) {
      // 購入・復元できた時点で検証成功として扱う
      await prefs.setString(
        AppConstants.keyEntitlementVerifiedAt,
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// ストアに現在の権利を問い合わせ、解約・期限切れなら Pro を失効させる。
  ///
  /// - 有効 → 権利を維持し、検証時刻を更新
  /// - 無効 → **即座に失効**（解約・返金の反映）
  /// - 判定不能（オフライン等） → 猶予期間内は維持し、期間を過ぎたら失効
  Future<void> verify(PurchaseService service) async {
    if (!MonetizationConfig.subscriptionEnabled) return;
    if (!state) return; // 元々Proでないなら何もしない

    final prefs = await SharedPreferences.getInstance();
    final verifiedAtStr =
        prefs.getString(AppConstants.keyEntitlementVerifiedAt);
    final verifiedAt =
        verifiedAtStr != null ? DateTime.tryParse(verifiedAtStr) : null;

    // 直近に検証済みなら毎回問い合わせない（起動のたびの復元処理を避ける）
    if (verifiedAt != null &&
        DateTime.now().difference(verifiedAt) <
            MonetizationConfig.entitlementRecheckInterval) {
      return;
    }

    final result = await service.verifyEntitlement();

    switch (result) {
      case EntitlementCheckResult.active:
        await prefs.setString(
          AppConstants.keyEntitlementVerifiedAt,
          DateTime.now().toIso8601String(),
        );
      case EntitlementCheckResult.inactive:
        debugPrint('[Entitlement] subscription is no longer active → revoke');
        await setPro(false);
      case EntitlementCheckResult.unknown:
        // ストアに到達できず判定不能。猶予期間を超えていれば失効させる
        final since = verifiedAt;
        if (since != null &&
            DateTime.now().difference(since) >
                MonetizationConfig.entitlementGracePeriod) {
          debugPrint('[Entitlement] grace period exceeded → revoke');
          await setPro(false);
        }
    }
  }
}

final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, bool>((ref) {
  return EntitlementNotifier();
});

/// 画面側が参照するのは必ずこちら。
/// サブスク機能が無効（subscriptionEnabled = false）の間は常に true を返す
/// ＝全機能開放（現在の挙動そのまま）。
final isProProvider = Provider<bool>((ref) {
  if (!MonetizationConfig.subscriptionEnabled) return true;
  return ref.watch(entitlementProvider);
});

/// 購入処理サービス。購入/復元成功時に entitlement を更新するよう配線済み。
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService(
    onEntitlementChanged: (isPro) =>
        ref.read(entitlementProvider.notifier).setPro(isPro),
  );
  ref.onDispose(service.dispose);
  return service;
});
