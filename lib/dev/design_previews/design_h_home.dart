import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【デザインプレビュー・案H「E×F ハイブリッド」】
///
/// フィードバック指定の組み合わせ：
/// - **色味は案E**（温かい紙色の背景・暖色の枠・マーカー由来の黄/緑/青パレット）
/// - **骨格は案F**（細線1.5px＋下エッジのカード・押せるチップ/CTA・レイアウト）
/// - **ノート/ペン/マーカーを想起させる意匠は不採用**
///   （罫線背景・赤罫・マーカー下塗り・インデックスタブ・ステッカー枠は無し。
///   色だけを受け継ぎ、モチーフは持ち込まない）
class DesignHHome extends StatelessWidget {
  const DesignHHome({super.key});

  // --- 案Hのデザイントークン（色=E / 構造=F） ---
  static const bg = Color(0xFFFBF9F3); // Eの温かい紙色（罫線なし）
  static const ink = Color(0xFF2F3037);
  static const subText = Color(0xFF6B6E7E);
  static const line = Color(0xFFE9E4D8); // Eの暖色ボーダー
  static const lineEdge = Color(0xFFE0DACB); // 下エッジ（暖色）
  static const indigo = Color(0xFF5B54E6);
  static const indigoEdge = Color(0xFF443CC9);
  static const indigoSoft = Color(0xFFEDEBFF);
  static const indigoChipBorder = Color(0xFFC9C4FF);
  static const indigoChipEdge = Color(0xFF9C94F5);
  // クエスト3色（Eのマーカー由来パレット）
  static const yellowSoft = Color(0xFFFFE34D);
  static const yellowDeep = Color(0xFFFFD21E);
  static const greenSoft = Color(0xFFA9EDC3);
  static const greenDeep = Color(0xFF3ECF8E);
  static const blueSoft = Color(0xFFBFE0FF);
  static const blueDeep = Color(0xFF4B9FEF);
  static const track = Color(0xFFF1EDE2); // ゲージの溝（暖色）
  static const coral = Color(0xFFF2600C);
  static const mint = Color(0xFF3EAF74);

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

  // ============ 部品（構造はFそのまま・色だけE） ============

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line, width: 1.5),
        boxShadow: const [
          BoxShadow(color: lineEdge, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: indigo,
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(color: indigoEdge, offset: Offset(0, 3)),
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ),
        Container(
          width: 33,
          height: 33,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: line, width: 1.5),
            boxShadow: const [
              BoxShadow(color: lineEdge, offset: Offset(0, 2.5)),
            ],
          ),
          child: const Icon(Icons.emoji_events_rounded,
              size: 18, color: yellowDeep),
        ),
        const SizedBox(width: 10),
        const DuckMascot(size: 38, mood: DuckMood.idle, rank: EngineerRank.intern),
      ],
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
                color: Color(0xFF9B9884))),
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
                      fontSize: 15.5, fontWeight: FontWeight.w800, color: ink)),
              Spacer(),
              Icon(Icons.help_outline_rounded, size: 18, color: subText),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('新規のみ', selected: false),
              const SizedBox(width: 7),
              _chip('復習のみ', selected: true),
              const SizedBox(width: 7),
              _chip('両方', selected: false),
            ],
          ),
          const SizedBox(height: 13),
          _statRow('⚡', '新規', '残り15 / 15枚', dimmed: true),
          const SizedBox(height: 7),
          _statRow('🔄', '復習', '24枚'),
          const Divider(color: line, thickness: 1.5, height: 24),
          const Row(
            children: [
              Text('合計',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: ink)),
              Spacer(),
              Text('24枚',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: indigo)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _cta('▶  学習を始める')),
              const SizedBox(width: 9),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: line, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: lineEdge, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, size: 21, color: indigo),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: line, width: 1.5),
              boxShadow: const [
                BoxShadow(color: lineEdge, offset: Offset(0, 2.5)),
              ],
            ),
            child: const Text(
              '🔄 もう一度復習する (0)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFA6A290)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, {required bool selected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? indigoSoft : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: selected ? indigoChipBorder : line, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: selected ? indigoChipEdge : lineEdge,
              offset: const Offset(0, 2.5),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? indigoEdge : subText,
          ),
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String label, String value,
      {bool dimmed = false}) {
    final color = dimmed ? const Color(0xFFA9A695) : ink;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dimmed ? const Color(0xFFA9A695) : subText)),
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

  Widget _cta(String label) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: indigo,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: indigoEdge, offset: Offset(0, 5)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.4,
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
              Text('🎁', style: TextStyle(fontSize: 14)),
              SizedBox(width: 7),
              Text('今日のクエスト',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
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
          _questRow(yellowSoft, '🃏', 'カードを20枚学習する', '0/20',
              yellowDeep, 0.06),
          const SizedBox(height: 10),
          _questRow(greenSoft, '✅', '「覚えてた」を6回出す', '0/6', greenDeep, 0.05),
          const SizedBox(height: 10),
          _questRow(blueSoft, '⚡', '5コンボを達成する', '0/5', blueDeep, 0.05),
          const SizedBox(height: 11),
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

  Widget _questRow(Color tileColor, String emoji, String title, String count,
      Color barColor, double progress) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
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
        const SizedBox(height: 6),
        _bar(progress, barColor),
      ],
    );
  }

  Widget _bar(double value, Color color) {
    return Container(
      height: 11,
      width: double.infinity,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.03, 1.0),
        heightFactor: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
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
              Text('✨', style: TextStyle(fontSize: 13)),
              SizedBox(width: 7),
              Text('レベル',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
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
                  color: indigoSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Intern',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: indigoEdge),
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
          Container(
            height: 13,
            width: double.infinity,
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(7),
            ),
            clipBehavior: Clip.antiAlias,
            child: const FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.95,
              heightFactor: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: [Color(0xFF7C75FF), indigo]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text('あと 9 XP で LV 4！',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: mint)),
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
              Text('🛡️', style: TextStyle(fontSize: 13)),
              SizedBox(width: 7),
              Text('ストリーク保護',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
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
                  size: 22, color: subText.withOpacity(0.22)),
              const SizedBox(width: 5),
              Icon(Icons.shield_rounded,
                  size: 22, color: subText.withOpacity(0.22)),
              const SizedBox(width: 10),
              const Text('所持 1 / 3',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 12),
          _cta('🛡  200 XP で交換'),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: line, width: 1.5)),
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
    final color = active ? indigo : const Color(0xFFA9A695);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
