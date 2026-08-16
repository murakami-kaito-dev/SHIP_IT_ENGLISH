import 'package:flutter/material.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/features/gamification/domain/gamification.dart';
import 'package:ship_it_english/features/gamification/presentation/widgets/duck_mascot.dart';

/// 【開発専用】ダッキーの全ランク（アクセサリー差分）を並べて確認する。
///
///   flutter run -t lib/dev/main_duck_preview.dart
void main() {
  runApp(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  children: [
                    for (final rank in EngineerRank.values)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(rank.name, style: AppTheme.monoLabel),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DuckMascot(size: 118, rank: rank),
                              const SizedBox(width: 12),
                              DuckMascot(size: 44, rank: rank),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
