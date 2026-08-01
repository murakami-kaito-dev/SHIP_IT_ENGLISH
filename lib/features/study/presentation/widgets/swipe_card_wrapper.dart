import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_it_english/core/constants/app_constants.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/study/domain/models/study_session.dart';

class SwipeCardWrapper extends StatefulWidget {
  final Widget child;
  final bool isFlipped;
  final void Function(Rating rating) onSwipe;

  const SwipeCardWrapper({
    super.key,
    required this.child,
    required this.isFlipped,
    required this.onSwipe,
  });

  @override
  State<SwipeCardWrapper> createState() => _SwipeCardWrapperState();
}

class _SwipeCardWrapperState extends State<SwipeCardWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: AppConstants.swipeSnapBackDuration,
    );
    _snapBackAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.easeOut),
    );
    _snapBackAnimation.addListener(() {
      setState(() {
        _dragOffset = _snapBackAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  void _snapBack() {
    _snapBackAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0,
    ).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.easeOut),
    );
    _snapBackAnimation.addListener(() {
      setState(() {
        _dragOffset = _snapBackAnimation.value;
      });
    });
    _snapBackController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * AppConstants.swipeConfirmThreshold;
    final progress = (_dragOffset / screenWidth).clamp(-1.0, 1.0);
    final rotationAngle =
        progress * AppConstants.swipeMaxRotationDegrees * (3.14159 / 180);

    return GestureDetector(
      onHorizontalDragUpdate: widget.isFlipped
          ? (details) {
              setState(() {
                _dragOffset += details.delta.dx;
              });
            }
          : null,
      onHorizontalDragEnd: widget.isFlipped
          ? (details) {
              if (_dragOffset.abs() >= threshold) {
                final rating = _dragOffset < 0 ? Rating.forgot : Rating.remembered;
                HapticFeedback.mediumImpact();
                setState(() => _dragOffset = 0);
                widget.onSwipe(rating);
              } else {
                _snapBack();
              }
            }
          : null,
      onVerticalDragUpdate: !widget.isFlipped
          ? null
          : null,
      // 子に key を付けて、条件付きの子（フィードバック背景・アイコン）が
      // 出入りしても FlipCard のインデックスがずれず State が保持されるようにする。
      // key が無いと、ドラッグ開始でフィードバック背景が先頭に挿入された瞬間に
      // カードの位置がずれ、Flutter が FlipCard を作り直してフリップが表面に戻る。
      child: Stack(
        children: [
          // スワイプフィードバック背景
          if (widget.isFlipped && _dragOffset != 0)
            Positioned.fill(
              key: const ValueKey('swipe-feedback'),
              child: Container(
                decoration: BoxDecoration(
                  color: (_dragOffset < 0
                          ? AppTheme.ratingForgot
                          : AppTheme.ratingRemembered)
                      .withOpacity(
                    0.1 * (_dragOffset.abs() / threshold).clamp(0, 1),
                  ),
                  borderRadius: BorderRadius.circular(
                    AppTheme.cardBorderRadius,
                  ),
                ),
              ),
            ),
          // メインカード
          Transform(
            key: const ValueKey('swipe-card'),
            transform: Matrix4.identity()
              ..translate(_dragOffset, 0.0)
              ..rotateZ(rotationAngle),
            alignment: Alignment.center,
            child: widget.child,
          ),
          // スワイプアイコン（フェードイン）
          if (widget.isFlipped && _dragOffset < -20)
            Positioned(
              key: const ValueKey('swipe-icon-left'),
              top: 16,
              left: 16,
              child: Opacity(
                opacity: ((_dragOffset.abs() - 20) / (threshold - 20)).clamp(
                  0,
                  1,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.ratingForgot,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          if (widget.isFlipped && _dragOffset > 20)
            Positioned(
              key: const ValueKey('swipe-icon-right'),
              top: 16,
              right: 16,
              child: Opacity(
                opacity: ((_dragOffset.abs() - 20) / (threshold - 20)).clamp(
                  0,
                  1,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.ratingRemembered,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
