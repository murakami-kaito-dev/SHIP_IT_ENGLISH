import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【デザインプレビュー・案C「リキッドグラス」】
///
/// iOS 26 の Liquid Glass の文法に寄せた**静的モック**。
/// 特徴：オーロラ背景 / 半透明ガラスのカード（本物のブラー）/ 光沢のある
/// グラデーションCTA / 浮遊するガラスのタブバー。
class DesignCHome extends StatelessWidget {
  const DesignCHome({super.key});

  // --- 案Cのデザイントークン ---
  static const ink = Color(0xFF1D2033);
  static const subText = Color(0xFF4E5578);
  static const indigo = Color(0xFF5B54E6);
  static const violet = Color(0xFF7C75FF);
  static const cyan = Color(0xFF4FC3F7);
  static const pink = Color(0xFFFF8AC4);
  static const coral = Color(0xFFF4652E);
  static const mint = Color(0xFF2EC27E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // ===== オーロラ背景 =====
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF2F1FC), Color(0xFFEAF3FF)],
                ),
              ),
            ),
          ),
          Positioned(top: -120, left: -80, child: _blob(360, const Color(0x8C7C75FF))),
          Positioned(top: 90, right: -120, child: _blob(320, const Color(0x80FF8AC4))),
          Positioned(bottom: -100, left: 40, child: _blob(380, const Color(0x8054CDFF))),
          // ===== コンテンツ =====
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _streakRow(),
                  const SizedBox(height: 14),
                  _sessionCard(),
                  const SizedBox(height: 16),
                  _questCard(),
                  const SizedBox(height: 16),
                  _levelCard(),
                  const SizedBox(height: 16),
                  _shieldCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _floatingNav(),
    );
  }

  // ============ 部品 ============

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  /// 半透明ガラスのカード（本物のブラー＝背後のオーロラが透ける）。
  Widget _glass({required Widget child, double radius = 20}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x243C4696),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.42),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withOpacity(0.75)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [violet, indigo]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: indigo.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            '>_',
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'ShipIt English',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
          ),
        ),
        _glassIconTile(const Icon(Icons.emoji_events_rounded,
            size: 18, color: indigo)),
        const SizedBox(width: 10),
        const DuckMascot(size: 38, mood: DuckMood.idle, rank: EngineerRank.intern),
      ],
    );
  }

  Widget _glassIconTile(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.9)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _streakRow() {
    return const Row(
      children: [
        Text('🔥', style: TextStyle(fontSize: 15)),
        SizedBox(width: 6),
        Text('1日連続',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: coral)),
        Spacer(),
        Text('8/15 (土)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A80A8))),
      ],
    );
  }

  Widget _sessionCard() {
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('今日のセッション',
                  style: TextStyle(
                      fontSize: 16.5, fontWeight: FontWeight.w800, color: ink)),
              Spacer(),
              Icon(Icons.help_outline_rounded, size: 18, color: subText),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _segPill('新規のみ', selected: false),
              const SizedBox(width: 7),
              _segPill('復習のみ', selected: true),
              const SizedBox(width: 7),
              _segPill('両方', selected: false),
            ],
          ),
          const SizedBox(height: 13),
          _statRow('⚡', '新規', '残り15 / 15枚', dimmed: true),
          const SizedBox(height: 7),
          _statRow('🔄', '復習', '24枚'),
          Divider(color: subText.withOpacity(0.25), height: 22),
          const Row(
            children: [
              Text('合計',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: subText)),
              SizedBox(width: 8),
              Text('24枚',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _ctaGradient('▶  学習を始める')),
              const SizedBox(width: 9),
              _glassIconTile(
                  const Icon(Icons.tune_rounded, size: 20, color: indigo)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
            ),
            child: const Text(
              '🔄 もう一度復習する (0)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9AA0BA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segPill(String label, {required bool selected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [violet, indigo])
              : null,
          color: selected ? null : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(0.6)
                  : Colors.white.withOpacity(0.9)),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: indigo.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : subText,
          ),
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String label, String value,
      {bool dimmed = false}) {
    final color = dimmed ? const Color(0xFFA0A5C2) : ink;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dimmed ? const Color(0xFFA0A5C2) : subText)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }

  /// 光沢グラデーションのCTA（ガラスの世界の主役ボタン）。
  Widget _ctaGradient(String label) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [violet, indigo, cyan],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: indigo.withOpacity(0.45),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _questCard() {
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎁', style: TextStyle(fontSize: 15)),
              SizedBox(width: 7),
              Text('今日のクエスト',
                  style: TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w800, color: ink)),
              Spacer(),
              Text('0 / 3',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 12),
          _questRow('🃏', 'カードを20枚学習する', '0/20',
              const [violet, indigo], 0.05),
          const SizedBox(height: 10),
          _questRow('✅', '「覚えてた」を6回出す', '0/6',
              const [Color(0xFF5EDFA7), mint], 0.04),
          const SizedBox(height: 10),
          _questRow('⚡', '5コンボを達成する', '0/5',
              const [pink, Color(0xFFFF6B9C)], 0.04),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lock_rounded, size: 13, color: subText),
              SizedBox(width: 6),
              Text('3つすべて達成で宝箱が開く',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: subText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _questRow(String emoji, String title, String count,
      List<Color> barColors, double progress) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white.withOpacity(0.9)),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink)),
            ),
            Text(count,
                style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: subText)),
          ],
        ),
        const SizedBox(height: 7),
        _glassBar(progress, barColors),
      ],
    );
  }

  Widget _glassBar(double value, List<Color> colors) {
    return Container(
      height: 9,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x263C4696),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.03, 1.0),
        heightFactor: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _levelCard() {
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 14)),
              SizedBox(width: 7),
              Text('レベル',
                  style: TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w800, color: ink)),
              Spacer(),
              Text('通算 411 XP',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: indigo.withOpacity(0.3)),
                ),
                child: const Text(
                  'Intern',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4038B8)),
                ),
              ),
              const Spacer(),
              const Text('LV 3 ・ 171/180',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ink)),
            ],
          ),
          const SizedBox(height: 10),
          _glassBar(0.95, const [violet, cyan]),
          const SizedBox(height: 8),
          const Text('あと 9 XP で LV 4！',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: mint)),
        ],
      ),
    );
  }

  Widget _shieldCard() {
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🛡️', style: TextStyle(fontSize: 14)),
              SizedBox(width: 7),
              Text('ストリーク保護',
                  style: TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w800, color: ink)),
              Spacer(),
              Text('使えるXP 211',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 22, color: coral),
              const SizedBox(width: 5),
              Icon(Icons.shield_rounded,
                  size: 22, color: subText.withOpacity(0.25)),
              const SizedBox(width: 5),
              Icon(Icons.shield_rounded,
                  size: 22, color: subText.withOpacity(0.25)),
              const SizedBox(width: 10),
              const Text('所持 1 / 3',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 12),
          _ctaGradient('🛡  200 XP で交換'),
        ],
      ),
    );
  }

  /// 浮遊するガラスのタブバー（iOS 26 らしさの見せ場）。
  Widget _floatingNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E3C4696),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                ),
                child: Row(
                  children: [
                    _navItem(Icons.home_rounded, 'ホーム', active: true),
                    _navItem(Icons.grid_view_rounded, 'カテゴリ', active: false),
                    _navItem(Icons.settings_rounded, '設定', active: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {required bool active}) {
    final color = active ? indigo : const Color(0xFF9AA0BA);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 23, color: color),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
