import 'package:flutter/material.dart';

/// ShipIt English のデザインシステム「Terminal-grade」。
///
/// エンジニアが毎日触れる開発者ツール（Linear / Raycast / GitHub / ターミナル）の
/// 洗練を主題に、平面的にならないよう「奥行き（多層シャドウ・グラデーション）」と
/// 「モノスペースのデータ表現」でアイデンティティを作る。
/// 色・寸法・文字スタイルはすべてここに集約し、画面側は AppTheme 経由で参照する。
class AppTheme {
  // === Brand（アイリス系インディゴ。既定の青より生きた発色） ===
  static const Color primary = Color(0xFF5B54E6);
  static const Color primaryLight = Color(0xFFE9E8FD); // チップ背景など淡色
  static const Color primaryDark = Color(0xFF3F37B8); // 押下・濃色
  static const Color primaryGlow = Color(0xFF837DFF); // グラデーションの相方

  // === Surfaces / Background ===
  static const Color background = Color(0xFFECEEF7); // 涼しいライトベース
  static const Color backgroundTop = Color(0xFFF5F6FC); // 背景グラデーション上端
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE4E6F1); // ヘアライン

  // === Text（ややインディゴ寄りの深い黒＝温かみと締まり） ===
  static const Color textPrimary = Color(0xFF14162E);
  static const Color textSecondary = Color(0xFF555C7C);
  static const Color textTertiary = Color(0xFF9AA0BA);

  // === Rating（シンタックスハイライトを想わせる3色） ===
  static const Color ratingForgot = Color(0xFFF04870); // rose
  static const Color ratingUncertain = Color(0xFFF0A020); // amber
  static const Color ratingRemembered = Color(0xFF1FB579); // emerald

  // === Streak ===
  static const Color streakFire = Color(0xFFFF7A3D);
  static const Color streakInactive = Color(0xFFCBD0E0);

  // === モノスペース（このアプリのシグネチャ。iOS標準の Menlo を使う） ===
  static const String monoFont = 'Menlo';

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGlow, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 画面背景に敷く、ごく淡い縦グラデーション（奥行きの土台）
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundTop, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // === Typography ===
  static const TextStyle headingLarge = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
    color: textPrimary,
  );
  static const TextStyle headingMedium = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: textPrimary,
  );
  static const TextStyle phraseText = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.3,
    color: textPrimary,
  );
  static const TextStyle translationText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: textPrimary,
  );
  static const TextStyle bodyText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: textSecondary,
  );
  static const TextStyle captionText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  /// モノスペースの小ラベル（カテゴリタグ・コード的な見出し）
  static const TextStyle monoLabel = TextStyle(
    fontFamily: monoFont,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: textSecondary,
  );

  /// モノスペースの数値（ストリーク・統計・進捗％など）
  static const TextStyle monoNumber = TextStyle(
    fontFamily: monoFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  /// 大きなモノスペース数値（セッション完了の統計・カレンダーの日数）
  static const TextStyle monoNumberLarge = TextStyle(
    fontFamily: monoFont,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  // === Radii / Spacing ===
  static const double cardBorderRadius = 18.0;
  static const double cardElevation = 0;
  static const EdgeInsets cardPadding = EdgeInsets.all(22.0);
  static final Border cardBorder = Border.all(color: surfaceBorder, width: 1.0);

  static const double buttonBorderRadius = 15.0;
  static const double buttonHeight = 56.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );

  static const double ratingButtonHeight = 54.0;
  static const double ratingButtonBorderRadius = 14.0;
  static const double ratingButtonSpacing = 10.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );

  static const double progressBarHeight = 9.0;
  static const double progressBarBorderRadius = 5.0;

  // === Elevation（インディゴで色付けした多層シャドウ＝奥行き） ===
  /// 通常カード用。接触影＋やわらかい環境影の2層
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF14162E).withOpacity(0.05),
      blurRadius: 18,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: const Color(0xFF14162E).withOpacity(0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  /// 学習カード（ヒーロー）用の強めの浮遊感
  static final List<BoxShadow> heroShadow = [
    BoxShadow(
      color: primary.withOpacity(0.16),
      blurRadius: 40,
      offset: const Offset(0, 18),
      spreadRadius: -10,
    ),
    BoxShadow(
      color: const Color(0xFF14162E).withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  /// 主ボタンのグロー影
  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.38),
      blurRadius: 20,
      offset: const Offset(0, 9),
      spreadRadius: -5,
    ),
  ];

  /// 標準カードの装飾（角丸＋ヘアライン＋やわらかい影）
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: cardBorder,
        boxShadow: cardShadow,
      );

  // === ThemeData ===
  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      surface: surface,
    ).copyWith(primary: primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: headingMedium,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
          side: const BorderSide(color: surfaceBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          shadowColor: primary.withOpacity(0.5),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, buttonHeight),
          side: const BorderSide(color: surfaceBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: buttonText.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primaryLight,
        side: const BorderSide(color: surfaceBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: captionText.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primaryLight,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.12),
        trackHeight: 5,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
      ),
    );
  }
}
