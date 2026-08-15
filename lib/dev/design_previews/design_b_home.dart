import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【デザインプレビュー・案B「キャンディ・ポップ」】
///
/// Duolingo 系の文法（白背景・緑・下に厚みのあるボタン・太い丸文字）に寄せた
/// **静的モック**。効果実証済みの見た目だが「借り物」感のリスクも比較する。
class DesignBHome extends StatelessWidget {
  const DesignBHome({super.key});

  // --- 案Bのデザイントークン ---
  static const bg = Colors.white;
  static const ink = Color(0xFF3C3C3C);
  static const title = Color(0xFF4B4B4B);
  static const subText = Color(0xFF777777);
  static const line = Color(0xFFE5E5E5);
  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF46A302);
  static const blue = Color(0xFF1CB0F6);
  static const blueSoft = Color(0xFFDDF4FF);
  static const blueText = Color(0xFF1899D6);
  static const gold = Color(0xFFFFC800);
  static const goldSoft = Color(0xFFFFF0C2);
  static const purpleSoft = Color(0xFFF2E8FF);
  static const orange = Color(0xFFFF9600);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 14),
              _streakRow(),
              const SizedBox(height: 12),
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
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ============ 部品 ============

  /// 下辺だけ厚い枠のカード（Duolingo の基本面）。
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          top: BorderSide(color: line, width: 2),
          left: BorderSide(color: line, width: 2),
          right: BorderSide(color: line, width: 2),
          bottom: BorderSide(color: line, width: 5),
        ),
      ),
      child: child,
    );
  }

  Widget _header() {
    return Row(
      children: [
        const DuckMascot(size: 40, mood: DuckMood.idle, rank: EngineerRank.intern),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'ShipIt English',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: green,
            letterSpacing: 0.3,
          ),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              top: BorderSide(color: line, width: 2),
              left: BorderSide(color: line, width: 2),
              right: BorderSide(color: line, width: 2),
              bottom: BorderSide(color: line, width: 4),
            ),
          ),
          child: const Icon(Icons.emoji_events_rounded, size: 19, color: gold),
        ),
      ],
    );
  }

  Widget _streakRow() {
    return const Row(
      children: [
        Text('🔥', style: TextStyle(fontSize: 16)),
        SizedBox(width: 6),
        Text('1日連続',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: orange)),
        Spacer(),
        Text('8/15 (土)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFAFAFAF))),
      ],
    );
  }

  Widget _sessionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('今日のセッション',
                  style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: title)),
              Spacer(),
              Icon(Icons.help_outline_rounded, size: 18, color: subText),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _segChip('新規のみ', selected: false),
              const SizedBox(width: 7),
              _segChip('復習のみ', selected: true),
              const SizedBox(width: 7),
              _segChip('両方', selected: false),
            ],
          ),
          const SizedBox(height: 13),
          _statRow('⚡', '新規', '残り15 / 15枚', dimmed: true),
          const SizedBox(height: 7),
          _statRow('🔄', '復習', '24枚'),
          const Divider(color: line, thickness: 2, height: 24),
          const Row(
            children: [
              Text('合計',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: subText)),
              SizedBox(width: 8),
              Text('24枚',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900, color: green)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _cta3d('学習を始める')),
              const SizedBox(width: 9),
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: const Border(
                    top: BorderSide(color: line, width: 2),
                    left: BorderSide(color: line, width: 2),
                    right: BorderSide(color: line, width: 2),
                    bottom: BorderSide(color: line, width: 5),
                  ),
                ),
                child: const Icon(Icons.tune_rounded, size: 22, color: blue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: const Border(
                top: BorderSide(color: line, width: 2),
                left: BorderSide(color: line, width: 2),
                right: BorderSide(color: line, width: 2),
                bottom: BorderSide(color: line, width: 4),
              ),
            ),
            child: const Text(
              'もう一度復習する (0)',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFAFAFAF),
                  letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segChip(String label, {required bool selected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? blueSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: selected ? blue : line, width: 2),
            left: BorderSide(color: selected ? blue : line, width: 2),
            right: BorderSide(color: selected ? blue : line, width: 2),
            bottom: BorderSide(color: selected ? blue : line, width: 3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? blueText : subText,
          ),
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String label, String value,
      {bool dimmed = false}) {
    final color = dimmed ? const Color(0xFFBDBDBD) : ink;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: dimmed ? const Color(0xFFBDBDBD) : subText)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  /// 下に厚みのある緑ボタン（Duolingo の主役）。
  Widget _cta3d(String label) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: greenDark, offset: Offset(0, 5)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _questCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎁', style: TextStyle(fontSize: 15)),
              SizedBox(width: 7),
              Text('今日のクエスト',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: title)),
              Spacer(),
              Text('0 / 3',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, color: subText)),
            ],
          ),
          const SizedBox(height: 12),
          _questRow(goldSoft, '🃏', 'カードを20枚学習する', '0/20', gold, 0.05),
          const SizedBox(height: 10),
          _questRow(blueSoft, '✅', '「覚えてた」を6回出す', '0/6', blue, 0.04),
          const SizedBox(height: 10),
          _questRow(purpleSoft, '⚡', '5コンボを達成する', '0/5',
              const Color(0xFFA560E8), 0.04),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lock_rounded, size: 14, color: subText),
              SizedBox(width: 6),
              Text('3つすべて達成で宝箱が開く',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: subText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _questRow(Color tileColor, String emoji, String title_, String count,
      Color barColor, double progress) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title_,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: ink)),
            ),
            Text(count,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w900, color: subText)),
          ],
        ),
        const SizedBox(height: 7),
        _fatBar(progress, barColor),
      ],
    );
  }

  /// 太くて丸いバー（キャンディのゲージ感）。
  Widget _fatBar(double value, Color color) {
    return Container(
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: line,
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.04, 1.0),
        heightFactor: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  Widget _levelCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 14)),
              SizedBox(width: 7),
              Text('レベル',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: title)),
              Spacer(),
              Text('通算 411 XP',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, color: green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: blueSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Intern',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: blueText),
                ),
              ),
              const Spacer(),
              const Text('LV 3 ・ 171/180',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
            ],
          ),
          const SizedBox(height: 10),
          _fatBar(0.95, green),
          const SizedBox(height: 8),
          const Text('あと 9 XP で LV 4！',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w900, color: green)),
        ],
      ),
    );
  }

  Widget _shieldCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🛡️', style: TextStyle(fontSize: 14)),
              SizedBox(width: 7),
              Text('ストリーク保護',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: title)),
              Spacer(),
              Text('使えるXP 211',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, color: blue)),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.shield_rounded, size: 22, color: orange),
              SizedBox(width: 5),
              Icon(Icons.shield_rounded, size: 22, color: line),
              SizedBox(width: 5),
              Icon(Icons.shield_rounded, size: 22, color: line),
              SizedBox(width: 10),
              Text('所持 1 / 3',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 12),
          _cta3d('200 XP で交換'),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: line, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _navItem(Icons.home_rounded, active: true),
              _navItem(Icons.grid_view_rounded, active: false),
              _navItem(Icons.settings_rounded, active: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, {required bool active}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 26),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: active
            ? BoxDecoration(
                color: blueSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: blue, width: 2),
              )
            : null,
        child: Icon(icon,
            size: 26, color: active ? blueText : const Color(0xFFAFAFAF)),
      ),
    );
  }
}
