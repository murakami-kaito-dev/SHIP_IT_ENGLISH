import 'package:flutter/material.dart';

/// ShipIt English のデザインシステム「Soft Arcade Warm」（採用案H＝色:案E×骨格:案F）。
///
/// 温かい紙色の背景と暖色の細枠（1.5px）に、「下エッジで押すと沈む」立体ボタンと
/// 意味で使い分ける多彩色（マーカー由来の黄/緑/青）を載せる。ゲーム感はほどよく、
/// 線は細く大人に。数値は従来どおりモノスペース（Menlo）＝このアプリのDNA。
/// 色・寸法・文字スタイルはすべてここに集約し、画面側は AppTheme 経由で参照する。
class AppTheme {
  // === Brand（アイリス系インディゴ。既定の青より生きた発色） ===
  static const Color primary = Color(0xFF5B54E6);
  static const Color primaryLight = Color(0xFFEDEBFF); // チップ背景など淡色
  static const Color primaryDark = Color(0xFF443CC9); // 押下・下エッジ・濃色
  static const Color primaryGlow = Color(0xFF837DFF); // グラデーションの相方

  // === Surfaces / Background（温かい紙色＝案Eの色味） ===
  static const Color background = Color(0xFFFAF7EF); // 温かい紙色
  static const Color backgroundTop = Color(0xFFFCFAF5); // 背景グラデーション上端
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE9E4D8); // 暖色の細枠
  /// カード・ボタンの「下エッジ」（押せる厚み。骨格=案F）
  static const Color surfaceEdge = Color(0xFFE0DACB);
  /// ゲージの溝（暖色トラック）
  static const Color track = Color(0xFFF1EDE2);

  // === Text（暖色寄りのチャコール） ===
  static const Color textPrimary = Color(0xFF2F3037);
  static const Color textSecondary = Color(0xFF6B6E7E);
  static const Color textTertiary = Color(0xFFA5A08F);

  // === Rating（シンタックスハイライトを想わせる3色） ===
  static const Color ratingForgot = Color(0xFFF04870); // rose
  static const Color ratingUncertain = Color(0xFFF0A020); // amber
  static const Color ratingRemembered = Color(0xFF1FB579); // emerald

  // === Streak ===
  static const Color streakFire = Color(0xFFFF7A3D);
  static const Color streakInactive = Color(0xFFD8D3C4);

  // === クエスト等の多彩色（案Eのマーカー由来パレット。soft=タイル / deep=ゲージ） ===
  static const Color questYellow = Color(0xFFFFD21E);
  static const Color questYellowSoft = Color(0xFFFFE34D);
  static const Color questGreen = Color(0xFF3ECF8E);
  static const Color questGreenSoft = Color(0xFFA9EDC3);
  static const Color questBlue = Color(0xFF4B9FEF);
  static const Color questBlueSoft = Color(0xFFBFE0FF);
  static const Color questOrange = Color(0xFFFF7A3D);
  static const Color questOrangeSoft = Color(0xFFFFDFC9);

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
  static const double cardBorderRadius = 16.0;
  static const double cardElevation = 0;
  static const EdgeInsets cardPadding = EdgeInsets.all(18.0);
  static final Border cardBorder = Border.all(color: surfaceBorder, width: 1.5);

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

  // === Elevation ===
  /// 通常カード用。「下エッジ」1枚＝押せそうな厚み（骨格=案F）。
  /// ブラーのない solid シャドウなので描画も軽い。
  static final List<BoxShadow> cardShadow = [
    const BoxShadow(color: surfaceEdge, offset: Offset(0, 3)),
  ];

  /// 学習カード（ヒーロー）用の強めの浮遊感（インディゴの浮遊＋暖色の接地）
  static final List<BoxShadow> heroShadow = [
    BoxShadow(
      color: primary.withOpacity(0.14),
      blurRadius: 36,
      offset: const Offset(0, 16),
      spreadRadius: -10,
    ),
    const BoxShadow(color: surfaceEdge, offset: Offset(0, 3)),
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
          // グローではなく「下エッジ」1枚で立体を出す（案Hの押し心地）
          shadowColor: primaryDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: buttonText,
        ),
      ),
      // 学習範囲セレクタ等のセグメント（選択中＝淡インディゴ＋濃インディゴ文字）
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primaryLight
                : surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primaryDark
                : textSecondary,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFC9C4FF)
                  : surfaceBorder,
              width: 1.5,
            ),
          ),
          textStyle: WidgetStateProperty.all(const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          )),
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
