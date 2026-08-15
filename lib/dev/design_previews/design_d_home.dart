import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【デザインプレビュー・案D「クレイ・ポップ」】
///
/// ぷにぷにした柔らかい3D（クレイモーフィズム）の**静的モック**。
/// 明るい面（上）と沈む影（下）のダブルシャドウ＋淡いグラデで「粘土の厚み」を
/// 出す。マスコットが住める、触りたくなる世界観。
class DesignDHome extends StatelessWidget {
  const DesignDHome({super.key});

  // --- 案Dのデザイントークン ---
  static const bg = Color(0xFFECEAFB); // ラベンダーの土台
  static const surface = Color(0xFFF7F6FF);
  static const ink = Color(0xFF33355A);
  static const subText = Color(0xFF666B95);
  static const indigo = Color(0xFF5B54E6);
  static const violet = Color(0xFF7C75FF);
  static const coral = Color(0xFFFF7A3D);
  static const amber = Color(0xFFFFB300);
  static const mint = Color(0xFF2EC27E);
  static const sky = Color(0xFF3BA8F5);

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
              const SizedBox(height: 14),
              _sessionCard(),
              const SizedBox(height: 18),
              _questCard(),
              const SizedBox(height: 18),
              _levelCard(),
              const SizedBox(height: 18),
              _shieldCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ============ 部品 ============

  /// 粘土の面：上から光が当たる淡いグラデ＋（左上＝白い光 / 右下＝沈む影）の
  /// ダブルシャドウでぷにっとした厚みを出す。
  Widget _clay({required Widget child, double radius = 24}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, surface],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E5A5AAA),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 12,
            offset: Offset(-6, -6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [violet, indigo]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: indigo.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
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
            style: TextStyle(
              fontSize: 20.5, fontWeight: FontWeight.w900, color: ink),
          ),
        ),
        _clayTile(const Icon(Icons.emoji_events_rounded,
            size: 19, color: amber)),
        const SizedBox(width: 10),
        const DuckMascot(size: 40, mood: DuckMood.idle, rank: EngineerRank.intern),
      ],
    );
  }

  Widget _clayTile(Widget child, {double size = 36, Color? color}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(size * 0.33),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E5A5AAA),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 6,
            offset: Offset(-3, -3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _streakRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF9A62), coral]),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: coral.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            '🔥 1日連続',
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Colors.white),
          ),
        ),
        const Spacer(),
        const Text('8/15 (土)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A8FB8))),
      ],
    );
  }

  Widget _sessionCard() {
    return _clay(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('今日のセッション',
                  style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: ink)),
              Spacer(),
              Icon(Icons.help_outline_rounded, size: 18, color: subText),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _segPuff('新規のみ', selected: false),
              const SizedBox(width: 8),
              _segPuff('復習のみ', selected: true),
              const SizedBox(width: 8),
              _segPuff('両方', selected: false),
            ],
          ),
          const SizedBox(height: 13),
          _statRow('⚡', '新規', '残り15 / 15枚', dimmed: true),
          const SizedBox(height: 7),
          _statRow('🔄', '復習', '24枚'),
          Divider(color: subText.withOpacity(0.18), height: 24),
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
                      fontFamily: 'Menlo',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _ctaPuff('▶  学習を始める')),
              const SizedBox(width: 10),
              _clayTile(
                  const Icon(Icons.tune_rounded, size: 22, color: indigo),
                  size: 52),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F5A5AAA),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '🔄 もう一度復習する (0)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9BA0C4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segPuff(String label, {required bool selected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [violet, indigo])
              : null,
          color: selected ? null : bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: indigo.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ]
              : const [
                  BoxShadow(
                      color: Color(0x1F5A5AAA),
                      blurRadius: 3,
                      offset: Offset(0, 2)),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : subText,
          ),
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String label, String value,
      {bool dimmed = false}) {
    final color = dimmed ? const Color(0xFFA9ADCC) : ink;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: dimmed ? const Color(0xFFA9ADCC) : subText)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: color)),
      ],
    );
  }

  /// ぷにっとした立体CTA（上ハイライト＋下に沈む影）。
  Widget _ctaPuff(String label) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8F88FF), Color(0xFF544CE0)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: indigo.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0x66FFFFFF),
            blurRadius: 2,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _questCard() {
    return _clay(
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
                      color: ink)),
              Spacer(),
              Text('0 / 3',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 13),
          _questRow(const Color(0xFFFFE9B8), '🃏', 'カードを20枚学習する', '0/20',
              amber, 0.05),
          const SizedBox(height: 11),
          _questRow(const Color(0xFFCFF3E2), '✅', '「覚えてた」を6回出す', '0/6',
              mint, 0.04),
          const SizedBox(height: 11),
          _questRow(const Color(0xFFCBE7FF), '⚡', '5コンボを達成する', '0/5',
              sky, 0.04),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lock_rounded, size: 13, color: subText),
              SizedBox(width: 6),
              Text('3つすべて達成で宝箱が開く',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: subText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _questRow(Color tileColor, String emoji, String title, String count,
      Color barColor, double progress) {
    return Column(
      children: [
        Row(
          children: [
            _clayTile(Text(emoji, style: const TextStyle(fontSize: 13)),
                size: 32, color: tileColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
        const SizedBox(height: 8),
        _puffBar(progress, barColor),
      ],
    );
  }

  /// くぼんだ溝＋ぷっくりした中身のバー。
  Widget _puffBar(double value, Color color) {
    return Container(
      height: 13,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E0F6),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x335A5AAA),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.04, 1.0),
        heightFactor: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.75), color],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _levelCard() {
    return _clay(
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
                      color: ink)),
              Spacer(),
              Text('通算 411 XP',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEDBFF),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.white,
                        blurRadius: 3,
                        offset: Offset(0, -2)),
                    BoxShadow(
                        color: Color(0x265A5AAA),
                        blurRadius: 4,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: const Text(
                  'Intern',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4038B8)),
                ),
              ),
              const Spacer(),
              const Text('LV 3 ・ 171/180',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ink)),
            ],
          ),
          const SizedBox(height: 11),
          _puffBar(0.95, indigo),
          const SizedBox(height: 8),
          const Text('あと 9 XP で LV 4！',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: mint)),
        ],
      ),
    );
  }

  Widget _shieldCard() {
    return _clay(
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
                      color: ink)),
              Spacer(),
              Text('使えるXP 211',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 23, color: coral),
              const SizedBox(width: 5),
              Icon(Icons.shield_rounded,
                  size: 23, color: subText.withOpacity(0.2)),
              const SizedBox(width: 5),
              Icon(Icons.shield_rounded,
                  size: 23, color: subText.withOpacity(0.2)),
              const SizedBox(width: 10),
              const Text('所持 1 / 3',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 13),
          _ctaPuff('🛡  200 XP で交換'),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x335A5AAA),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              _navItem(Icons.home_rounded, 'ホーム', active: true),
              _navItem(Icons.grid_view_rounded, 'カテゴリ', active: false),
              _navItem(Icons.settings_rounded, '設定', active: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {required bool active}) {
    final color = active ? indigo : const Color(0xFFA9ADCC);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
