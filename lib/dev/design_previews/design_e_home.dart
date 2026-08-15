import 'package:flutter/material.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【デザインプレビュー・案E「スタディノート」】
///
/// 「勉強道具の文法」で学習感を主役にした静的モック。
/// 特徴：ノートの罫線背景 / 大事な数字・語句への蛍光マーカー下塗り /
/// インデックスタブのセレクタ / ノートに貼ったステッカーのダッキー /
/// 細線1.5px（大人っぽさ）＋下エッジの押せるボタン。
class DesignEHome extends StatelessWidget {
  const DesignEHome({super.key});

  // --- 案Eのデザイントークン ---
  static const paper = Color(0xFFFBF9F3); // ノートの紙
  static const ruled = Color(0x22708CB4); // 罫線
  static const ink = Color(0xFF2F3037);
  static const subText = Color(0xFF6B6E7E);
  static const cardBorder = Color(0xFFE9E4D8);
  static const redRule = Color(0xFFF2B8BE); // インデックスカードの赤罫
  static const indigo = Color(0xFF5B54E6);
  static const indigoEdge = Color(0xFF443CC9);
  static const markerYellow = Color(0xFFFFE34D);
  static const markerYellowDeep = Color(0xFFFFD21E);
  static const markerGreen = Color(0xFFA9EDC3);
  static const markerGreenDeep = Color(0xFF3ECF8E);
  static const markerBlue = Color(0xFFBFE0FF);
  static const markerBlueDeep = Color(0xFF4B9FEF);
  static const tabIdle = Color(0xFFF1EDE2);
  static const tabIdleEdge = Color(0xFFE0DACB);
  static const tabOnEdge = Color(0xFFE8C51E);
  static const mint = Color(0xFF3EAF74);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: Stack(
        children: [
          // ノートの罫線（背景全体）
          const Positioned.fill(
            child: CustomPaint(painter: _RuledPaperPainter()),
          ),
          SafeArea(
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
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ============ 部品 ============

  /// インデックスカード風：タイトル行→赤罫（カード幅いっぱい）→本文。
  Widget _card({required Widget title, required Widget body}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x175F5537),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: title,
          ),
          // 赤罫はカードの端から端まで（本物のインデックスカードの作法）
          Container(
            height: 1.5,
            color: redRule,
            margin: const EdgeInsets.only(top: 8, bottom: 10),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
            child: body,
          ),
        ],
      ),
    );
  }

  /// 蛍光マーカーの下塗り（テキストの下半分に色を敷く）。
  Widget _hl(String text, Color marker,
      {double fontSize = 12.5,
      FontWeight weight = FontWeight.w700,
      Color color = ink,
      String? fontFamily}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.52, 0.52, 0.94, 0.94, 1],
          colors: [
            Colors.transparent,
            Colors.transparent,
            marker,
            marker,
            Colors.transparent,
            Colors.transparent,
          ],
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          fontFamily: fontFamily,
        ),
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
            color: indigo,
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(color: indigoEdge, offset: Offset(0, 2.5)),
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
        // ノートに貼ったステッカーのダッキー（少し傾ける）
        Transform.rotate(
          angle: 0.10,
          child: Container(
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40504628),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const DuckMascot(
                size: 34, mood: DuckMood.idle, rank: EngineerRank.intern),
          ),
        ),
      ],
    );
  }

  Widget _streakRow() {
    return Row(
      children: [
        const Text('🔥', style: TextStyle(fontSize: 15)),
        const SizedBox(width: 5),
        _hl('1日連続', markerYellow, fontSize: 14, weight: FontWeight.w800),
        const Spacer(),
        const Text('8/15 (土)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B9884))),
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
          // インデックスタブ（ノートの見出しタブの作法）
          Row(
            children: [
              _indexTab('新規のみ', selected: false),
              const SizedBox(width: 6),
              _indexTab('復習のみ', selected: true),
              const SizedBox(width: 6),
              _indexTab('両方', selected: false),
            ],
          ),
          const SizedBox(height: 12),
          _statRow('⚡', '新規', '残り15 / 15枚', dimmed: true),
          const SizedBox(height: 7),
          Row(
            children: [
              const Text('🔄', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 7),
              const Text('復習',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subText)),
              const Spacer(),
              _hl('24枚', markerBlue,
                  fontSize: 13.5, weight: FontWeight.w700, fontFamily: 'Menlo'),
            ],
          ),
          const SizedBox(height: 12),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: tabIdleEdge, offset: Offset(0, 3)),
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
              color: paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder, width: 1.5),
            ),
            child: const Text(
              '🔄 もう一度復習する (0)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA6A290)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _indexTab(String label, {required bool selected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? markerYellow : tabIdle,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(9),
            bottom: Radius.circular(3),
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? tabOnEdge : tabIdleEdge,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? ink : subText,
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

  /// 下エッジで「押せる」CTA（文房具らしい落ち着いた立体）。
  Widget _cta(String label) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: indigo,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(color: indigoEdge, offset: Offset(0, 4)),
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
          _questRow(markerYellow, '🃏', 'カードを', '20枚', '学習する', '0/20',
              markerYellowDeep, 0.06),
          const SizedBox(height: 10),
          _questRow(markerGreen, '✅', '「覚えてた」を', '6回', '出す', '0/6',
              markerGreenDeep, 0.05),
          const SizedBox(height: 10),
          _questRow(markerBlue, '⚡', '', '5コンボ', 'を達成する', '0/5',
              markerBlueDeep, 0.05),
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

  /// クエスト1行。お題の中の**目標値だけ**にマーカーを引く（ノートで大事な
  /// ところに線を引く作法そのもの）。
  Widget _questRow(Color marker, String emoji, String pre, String key,
      String post, String count, Color barColor, double progress) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: marker,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x405F5537),
                    blurRadius: 3,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Row(
                children: [
                  if (pre.isNotEmpty)
                    Text(pre,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                  _hl(key, marker),
                  Flexible(
                    child: Text(post,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                  ),
                ],
              ),
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

  /// マーカーで塗り進めるゲージ。
  Widget _bar(double value, Color color) {
    return Container(
      height: 11,
      width: double.infinity,
      decoration: BoxDecoration(
        color: tabIdle,
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
                  color: indigo)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _hl('Intern', markerYellow,
                  fontSize: 13,
                  weight: FontWeight.w800,
                  color: ink,
                  fontFamily: 'Menlo'),
              const Spacer(),
              const Text('LV 3 ・ 171/180',
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
              color: tabIdle,
              borderRadius: BorderRadius.circular(5),
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
                  color: indigo)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded,
                  size: 22, color: Color(0xFFFF7A3D)),
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

/// ノートの罫線（横線を等間隔に引く）。
class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignEHome.ruled
      ..strokeWidth = 1;
    for (double y = 26; y < size.height; y += 27) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
