import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【デザインプレビュー・案A「アーケード・ターミナル」】
///
/// 実アプリのロジックとは無関係の**静的モック**。デザイン判断のためだけに
/// ホーム画面の見た目を再現している（`flutter run -t lib/main_design_preview.dart`）。
/// 特徴：太いインクの輪郭 / 押すと沈む厚みボタン / 意味で使い分ける多色 /
/// ピクセル世界観（ダッキーと地続き）。
class DesignAHome extends StatelessWidget {
  const DesignAHome({super.key});

  // --- 案Aのデザイントークン ---
  static const bg = Color(0xFFFFFDF4); // 温かみのある紙
  static const ink = Color(0xFF26283A); // インクの輪郭
  static const indigo = Color(0xFF5B54E6);
  static const indigoDark = Color(0xFF3B35A8);
  static const coral = Color(0xFFFF7A3D);
  static const amber = Color(0xFFFFB300);
  static const yellow = Color(0xFFFFD43B);
  static const mint = Color(0xFF2EC27E);
  static const mintSoft = Color(0xFF7DE3AE);
  static const sky = Color(0xFF3BA8F5);
  static const skySoft = Color(0xFF8FD0FF);
  static const tintYellow = Color(0xFFFFF6DE);
  static const tintPurple = Color(0xFFF0EEFF);
  static const subText = Color(0xFF585E7A);

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

  /// インク輪郭＋オフセット影のカード（案Aの基本面）。
  Widget _card({required Widget child, Color color = Colors.white}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0xE626283A), offset: Offset(4, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _header() {
    return Row(
      children: [
        // ロゴタイル（">_" ＝ ターミナルの芯は残す）
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: indigo,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: ink, width: 2.5),
            boxShadow: const [
              BoxShadow(color: ink, offset: Offset(2.5, 2.5)),
            ],
          ),
          child: const Text(
            '>_',
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 13,
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
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: ink,
            letterSpacing: 0.2,
          ),
          ),
        ),
        // バッジ（トロフィー）タイル
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: yellow,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x8026283A), offset: Offset(2, 2)),
            ],
          ),
          child: const Icon(Icons.emoji_events_rounded, size: 19, color: ink),
        ),
        const SizedBox(width: 10),
        const DuckMascot(size: 42, mood: DuckMood.idle, rank: EngineerRank.intern),
      ],
    );
  }

  Widget _streakRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: coral,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x9926283A), offset: Offset(2, 2)),
            ],
          ),
          child: const Text(
            '🔥 1日連続',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        const Text(
          '8/15 (土)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A8FA8),
          ),
        ),
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
                      fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
              Spacer(),
              Icon(Icons.help_outline_rounded, size: 18, color: subText),
            ],
          ),
          const SizedBox(height: 12),
          // 学習範囲セレクタ（選択中＝藍で塗る）
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
          const Divider(color: ink, thickness: 1.2, height: 22),
          const Row(
            children: [
              Text('合計',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: subText)),
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
              Expanded(child: _cta3d('▶  学習を始める')),
              const SizedBox(width: 9),
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: ink, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0xB326283A), offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, size: 22, color: indigo),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // セカンダリ（アウトライン式）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFB9BDD4), width: 2),
            ),
            child: const Text(
              '🔄 もう一度復習する (0)',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9AA0BA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segChip(String label, {required bool selected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? indigo : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ink, width: 2),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0xFF3B35A8), offset: Offset(0, 3))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : subText,
          ),
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String label, String value,
      {bool dimmed = false}) {
    final color = dimmed ? const Color(0xFFA6ABC4) : ink;
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 14, color: color)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: dimmed ? const Color(0xFFA6ABC4) : subText)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color)),
      ],
    );
  }

  /// 押すと沈む3Dボタン（案Aの主役）。
  Widget _cta3d(String label) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: indigo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink, width: 2.5),
        boxShadow: const [
          BoxShadow(color: indigoDark, offset: Offset(0, 5)),
          BoxShadow(color: Color(0x5926283A), offset: Offset(4, 8)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _questCard() {
    return _card(
      color: tintYellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎁', style: TextStyle(fontSize: 16)),
              SizedBox(width: 7),
              Text('今日のクエスト',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
              Spacer(),
              Text('0 / 3',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 12),
          _questRow(yellow, '🃏', 'カードを20枚学習する', '0/20', amber, 0.06),
          const SizedBox(height: 10),
          _questRow(mintSoft, '✅', '「覚えてた」を6回出す', '0/6', mint, 0.04),
          const SizedBox(height: 10),
          _questRow(skySoft, '⚡', '5コンボを達成する', '0/5', sky, 0.04),
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

  Widget _questRow(Color tileColor, String emoji, String title, String count,
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
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x8026283A), offset: Offset(2, 2)),
                ],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: ink)),
            ),
            Text(count,
                style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: subText)),
          ],
        ),
        const SizedBox(height: 7),
        _chunkyBar(progress, barColor),
      ],
    );
  }

  /// 太枠つきの進捗バー（案Aは細いヘアラインではなく「ゲージ感」を出す）。
  Widget _chunkyBar(double value, Color color) {
    return Container(
      height: 13,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.02, 1.0),
        heightFactor: 1.0,
        child: DecoratedBox(decoration: BoxDecoration(color: color)),
      ),
    );
  }

  Widget _levelCard() {
    return _card(
      color: tintPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 15)),
              SizedBox(width: 7),
              Text('レベル',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
              Spacer(),
              Text('通算 411 XP',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 称号バッジ（黒地×金のモノスペース＝アーケードの筐体感）
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x8026283A), offset: Offset(2, 2)),
                  ],
                ),
                child: const Text(
                  'INTERN',
                  style: TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: yellow,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              const Text('LV 3 ・ 171/180',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ink)),
            ],
          ),
          const SizedBox(height: 10),
          // XPゲージは藍→ミントのグラデ（もうすぐレベルアップの高揚感）
          Container(
            height: 15,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ink, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: const FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.95,
              heightFactor: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF7C75FF), mint]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('あと 9 XP で LV 4！',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800, color: mint)),
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
              Text('🛡️', style: TextStyle(fontSize: 15)),
              SizedBox(width: 7),
              Text('ストリーク保護',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
              Spacer(),
              Text('使えるXP 211',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _shieldIcon(active: true),
              const SizedBox(width: 6),
              _shieldIcon(active: false),
              const SizedBox(width: 6),
              _shieldIcon(active: false),
              const SizedBox(width: 10),
              const Text('所持 1 / 3',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 12),
          _cta3d('🛡  200 XP で交換'),
        ],
      ),
    );
  }

  Widget _shieldIcon({required bool active}) {
    return Icon(
      Icons.shield_rounded,
      size: 24,
      color: active ? coral : const Color(0xFFD5D7E4),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ink, width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
    final color = active ? indigo : const Color(0xFFA6ABC4);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
