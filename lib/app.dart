import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ship_it_english/core/monetization/entitlement_provider.dart';
import 'package:ship_it_english/core/monetization/monetization_config.dart';
import 'package:ship_it_english/core/providers/language_provider.dart';
import 'package:ship_it_english/core/theme/app_theme.dart';
import 'package:ship_it_english/shared/widgets/app_background.dart';
import 'package:ship_it_english/features/categories/presentation/categories_screen.dart';
import 'package:ship_it_english/features/categories/presentation/category_detail_screen.dart';
import 'package:ship_it_english/features/history/presentation/history_screen.dart';
import 'package:ship_it_english/features/listening/presentation/listening_screen.dart';
import 'package:ship_it_english/features/listening/providers/listening_providers.dart';
import 'package:ship_it_english/features/home/presentation/home_screen.dart';
import 'package:ship_it_english/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ship_it_english/features/paywall/presentation/paywall_screen.dart';
import 'package:ship_it_english/features/search/presentation/search_screen.dart';
import 'package:ship_it_english/features/settings/presentation/settings_screen.dart';
import 'package:ship_it_english/features/study/presentation/session_complete_screen.dart';
import 'package:ship_it_english/features/study/presentation/study_screen.dart';

GoRouter createRouter({required bool showOnboarding}) {
  return GoRouter(
    initialLocation: showOnboarding ? '/onboarding' : '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CategoriesScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/study',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          final statusesCsv = q['statuses'] ?? '';
          return StudyScreen(
            categoryId: q['category'],
            practice: q['mode'] == 'practice',
            rangeFrom: int.tryParse(q['from'] ?? ''),
            rangeTo: int.tryParse(q['to'] ?? ''),
            statuses: statusesCsv.isEmpty
                ? const {}
                : statusesCsv.split(',').toSet(),
            random: q['order'] == 'random',
          );
        },
      ),
      GoRoute(
        path: '/listen',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          final statusesCsv = q['statuses'] ?? '';
          return ListeningScreen(
            config: ListenConfig(
              categoryId: q['category'] ?? '',
              from: int.tryParse(q['from'] ?? '') ?? 1,
              to: int.tryParse(q['to'] ?? '') ?? 999999,
              statuses: statusesCsv.isEmpty
                  ? const {}
                  : statusesCsv.split(',').toSet(),
              random: q['order'] == 'random',
            ),
          );
        },
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, state) =>
            CategoryDetailScreen(categoryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/session-complete',
        builder: (_, __) => const SessionCompleteScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (_, __) => const HistoryScreen(),
      ),
    ],
  );
}

class ShipItEnglishApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const ShipItEnglishApp({super.key, required this.showOnboarding});

  @override
  ConsumerState<ShipItEnglishApp> createState() => _ShipItEnglishAppState();
}

class _ShipItEnglishAppState extends ConsumerState<ShipItEnglishApp>
    with WidgetsBindingObserver {
  late final GoRouter _router =
      createRouter(showOnboarding: widget.showOnboarding);

  @override
  void initState() {
    super.initState();
    // 未処理トランザクションを受け取るため起動時に購読を開始する
    // （subscriptionEnabled = false のときは内部で何もしない）
    if (MonetizationConfig.subscriptionEnabled) {
      WidgetsBinding.instance.addObserver(this);
      ref.read(purchaseServiceProvider).init();
      _verifyEntitlement();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App Store の設定画面で解約してから戻ってきたケースを拾う
    if (state == AppLifecycleState.resumed) {
      _verifyEntitlement();
    }
  }

  /// 解約・期限切れを検出して Pro を失効させる
  /// （検証間隔・猶予期間の判定は EntitlementNotifier 側で行う）
  void _verifyEntitlement() {
    ref
        .read(entitlementProvider.notifier)
        .verify(ref.read(purchaseServiceProvider));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShipIt English',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/categories') return 1;
    if (location == '/settings') return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/categories');
      case 2:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(child: child),
      // ナビバーに上ヘアライン＋やわらかい影を付けて浮かせる（奥行き）
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14162E).withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (i) => _onTap(context, i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: strings.tabHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view_rounded),
              label: strings.tabCategories,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings_rounded),
              label: strings.tabSettings,
            ),
          ],
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textTertiary,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }
}
