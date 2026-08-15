import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【デザインプレビュー・案G「単語帳デスク」】
///
/// アプリの中身（フラッシュカード）を見た目にも。カードは**リング穴の開いた
/// 単語帳**、赤ペン・青ペンの2色軸、机の上の紙の温度。日本の勉強文化
/// （単語帳・赤シート）に強く刺さる静的モック。
class DesignGHome extends StatelessWidget {
  const DesignGHome({super.key});

  // --- 案Gのデザイントークン ---
  static const desk = Color(0xFFF6F1E7); // 机の上の温度
  static const cardPaper = Color(0xFFFFFEFA);
  static const cardBorder = Color(0xFFE5DECF);
  static const ink = Color(0xFF33323B);
  static const subText = Color(0xFF6E6A5E);
  static const redPen = Color(0xFFE4484D);
  static const redEdge = Color(0xFFB23237);
  static const redRule = Color(0xFFE88A93);
  static const bluePen = Color(0xFF2F6FD6);
  static const blueEdge = Color(0xFF1F52A8);
  static const ringGray = Color(0xFFC2BCAD);
  static const markerGold = Color(0xFFE8B31E);
  static const tileGold = Color(0xFFFCE49B);
  static const tileRed = Color(0xFFF5C6C9);
  static const tileBlue = Color(0xFFC4D9F5);
  static const green = Color(0xFF2F9E68);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: desk,
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

  /// リング穴つきの単語帳カード：穴＋タイトル→赤罫（端から端）→本文。
  Widget _card({required Widget title, required Widget body}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F5F502D),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // リング穴（パンチ穴。背景の机の色が覗く）
          Positioned(
            top: 12,
            left: 9,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: desk,
                shape: BoxShape.circle,
                border: Border.all(color: ringGray, width: 2.5),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 12, 14, 0),
                child: title,
              ),
              Container(
                height: 1.5,
                color: redRule,
                margin: const EdgeInsets.only(top: 8, bottom: 10),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 14, 13),
                child: body,
              ),
            ],
          ),
        ],
      ),
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
            color: bluePen,
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(color: blueEdge, offset: Offset(0, 2.5)),
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
            color: cardPaper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E5F502D),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child:
              const Icon(Icons.emoji_events_rounded, size: 18, color: markerGold),
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
                fontSize: 14, fontWeight: FontWeight.w800, color: redPen)),
        Spacer(),
        Text('8/15 (土)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA39C87))),
      ],
    );
  }

  Widget _sessionCard() {
    return _card(
      title: const Row(
        children: [
          Text('今日のセッション',
              style: TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w800, color: ink)),
          Spacer(),
          Icon(Icons.help_outline_rounded, size: 18, color: subText),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip('新規のみ', selected: false),
              const SizedBox(width: 6),
              _chip('復習のみ', selected: true),
              const SizedBox(width: 6),
              _chip('両方', selected: false),
            ],
          ),
          const SizedBox(height: 12),
          _statRow('⚡', '新規', '残り15 / 15枚', dimmed: true),
          const SizedBox(height: 7),
          _statRow('🔄', '復習', '24枚', valueColor: bluePen),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text('合計',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: ink)),
              Spacer(),
              // 大事な数字は赤ペンで（採点の作法）
              Text('24枚',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: redPen)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _cta('▶  学習を始める')),
              const SizedBox(width: 9),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cardPaper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E5F502D),
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, size: 21, color: bluePen),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: desk,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder, width: 1.5),
            ),
            child: const Text(
              '🔄 もう一度復習する (0)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA39C87)),
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
          color: selected ? bluePen : cardPaper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? blueEdge : cardBorder, width: 1.5),
          boxShadow: selected
              ? const [BoxShadow(color: blueEdge, offset: Offset(0, 2.5))]
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
      {bool dimmed = false, Color? valueColor}) {
    final color = dimmed ? const Color(0xFFB3AD99) : (valueColor ?? ink);
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dimmed ? const Color(0xFFB3AD99) : subText)),
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

  /// 青ペン色のCTA（下エッジで押せる）。
  Widget _cta(String label) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bluePen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: blueEdge, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _questCard() {
    return _card(
      title: const Row(
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questRow(tileGold, '🃏', 'カードを20枚学習する', '0/20', markerGold, 0.06),
          const SizedBox(height: 10),
          _questRow(tileRed, '✅', '「覚えてた」を6回出す', '0/6', redPen, 0.05),
          const SizedBox(height: 10),
          _questRow(tileBlue, '⚡', '5コンボを達成する', '0/5', bluePen, 0.05),
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
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x405F502D),
                    blurRadius: 3,
                    offset: Offset(0, 1.5),
                  ),
                ],
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
        color: const Color(0xFFEFE9DB),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.03, 1.0),
        heightFactor: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _levelCard() {
    return _card(
      title: const Row(
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
                  color: bluePen)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              // 称号は赤ペンの書き込み風
              Text('Intern',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: redPen)),
              Spacer(),
              Text('LV 3 ・ 171/180',
                  style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ink)),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            height: 13,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEFE9DB),
              borderRadius: BorderRadius.circular(5),
            ),
            clipBehavior: Clip.antiAlias,
            child: const FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.95,
              heightFactor: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF5A8FE0), bluePen]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text('あと 9 XP で LV 4！',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: green)),
        ],
      ),
    );
  }

  Widget _shieldCard() {
    return _card(
      title: const Row(
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
                  color: bluePen)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 22, color: redPen),
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
        color: cardPaper,
        border: Border(top: BorderSide(color: cardBorder, width: 1.5)),
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
    final color = active ? bluePen : const Color(0xFFA39C87);
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
