import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';

/// 権利検証の結果。
enum EntitlementCheckResult {
  /// 有効なサブスクリプションが確認できた
  active,

  /// ストアに問い合わせできたが、有効な権利が無かった（解約・期限切れ）
  inactive,

  /// ストアに到達できず判定できなかった（オフライン等）。この場合は
  /// **既存の権利を剥奪しない**（猶予期間の判定に委ねる）
  unknown,
}

/// App Store / Google Play のアプリ内課金（自動更新サブスクリプション）を扱う。
///
/// - StoreKit 2（iOS）/ Billing Library（Android）を公式プラグイン
///   `in_app_purchase` 経由で使用。外部サーバー・第三者SDKは使わないため、
///   ストアの「データ収集なし」申告に影響しない。
/// - subscriptionEnabled = false の間は全メソッドが何もせず即returnする。
class PurchaseService {
  final void Function(bool isPro) onEntitlementChanged;

  PurchaseService({required this.onEntitlementChanged});

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 購入エラーの通知先（パウォール画面が登録する）
  void Function(String message)? onError;

  /// 権利検証中に復元されたプロダクトIDを集める作業用バッファ
  Set<String>? _verifyBuffer;

  /// アプリ起動時に一度呼ぶ。未処理のトランザクション（アプリ外での
  /// 購入承認・中断された購入など）を受け取るために必要。
  Future<void> init() async {
    if (!MonetizationConfig.subscriptionEnabled) return;
    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object e) => onError?.call(e.toString()),
    );
  }

  Future<bool> isAvailable() async {
    if (!MonetizationConfig.subscriptionEnabled) return false;
    return _iap.isAvailable();
  }

  /// ストアから商品情報（価格はストア設定のローカライズ済み文字列）を取得
  Future<List<ProductDetails>> loadProducts() async {
    if (!MonetizationConfig.subscriptionEnabled) return [];
    final response =
        await _iap.queryProductDetails(MonetizationConfig.productIds);
    if (response.error != null) {
      onError?.call(response.error!.message);
    }
    // 表示順: 年額 → 月額（年額を主役にする）
    final products = response.productDetails;
    products.sort(
      (a, b) => a.id == MonetizationConfig.yearlyProductId ? -1 : 1,
    );
    return products;
  }

  Future<void> buy(ProductDetails product) async {
    if (!MonetizationConfig.subscriptionEnabled) return;
    final param = PurchaseParam(productDetails: product);
    // iOSでは自動更新サブスクも buyNonConsumable を使う
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (!MonetizationConfig.subscriptionEnabled) return;
    await _iap.restorePurchases();
  }

  /// 現在も有効なサブスクリプションを保持しているかをストアに問い合わせる。
  ///
  /// `in_app_purchase` には「現在の権利」を直接返すAPIが無いため、
  /// `restorePurchases()` を実行し、一定時間内に対象商品が `restored` として
  /// 返ってくるかで判定する。期限切れ・解約済みのサブスクは復元対象に
  /// 含まれないため、これで失効を検出できる。
  ///
  /// ストアに到達できない場合は [EntitlementCheckResult.unknown] を返し、
  /// **呼び出し側は権利を剥奪してはならない**（オフラインでの誤剥奪を防ぐ）。
  Future<EntitlementCheckResult> verifyEntitlement() async {
    if (!MonetizationConfig.subscriptionEnabled) {
      return EntitlementCheckResult.unknown;
    }

    try {
      if (!await _iap.isAvailable()) return EntitlementCheckResult.unknown;

      await init(); // ストリーム購読を確実に開始しておく

      final buffer = <String>{};
      _verifyBuffer = buffer;

      await _iap.restorePurchases();
      await Future<void>.delayed(MonetizationConfig.entitlementVerifyTimeout);

      _verifyBuffer = null;
      return buffer.isNotEmpty
          ? EntitlementCheckResult.active
          : EntitlementCheckResult.inactive;
    } catch (e) {
      _verifyBuffer = null;
      debugPrint('[PurchaseService] verifyEntitlement failed: $e');
      return EntitlementCheckResult.unknown;
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final isOurProduct =
          MonetizationConfig.productIds.contains(purchase.productID);

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (isOurProduct) {
            // 検証中なら結果バッファにも記録する
            _verifyBuffer?.add(purchase.productID);
            onEntitlementChanged(true);
          }
        case PurchaseStatus.error:
          onError?.call(purchase.error?.message ?? 'purchase failed');
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.pending:
          break;
      }
      if (purchase.pendingCompletePurchase) {
        // completePurchase を呼ばないとトランザクションがキューに残り続ける
        _iap.completePurchase(purchase).catchError((Object e) {
          debugPrint('[PurchaseService] completePurchase error: $e');
        });
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
