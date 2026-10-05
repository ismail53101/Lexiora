import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/services/ad_return_navigation_scope.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';

class _TestInterstitialManager extends RewardedAdManager {
  _TestInterstitialManager(this._show) : super(isPremium: () async => false);

  final Future<bool> Function() _show;
  int requestCount = 0;

  @override
  Future<bool> showReturnInterstitial() {
    requestCount++;
    return _show();
  }
}

Future<void> _openFeature(
  WidgetTester tester,
  _TestInterstitialManager manager, {
  Duration fallbackTimeout = const Duration(seconds: 18),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AdReturnNavigationScope(
                    manager: manager,
                    navigationFallbackTimeout: fallbackTimeout,
                    child: const Scaffold(
                      appBar: AppBar(title: Text('Feature screen')),
                      body: Center(child: Text('Feature content')),
                    ),
                  ),
                ),
              ),
              child: const Text('Open feature'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open feature'));
  await tester.pumpAndSettle();
  expect(find.text('Feature content'), findsOneWidget);
}

void main() {
  testWidgets(
    'AppBar Back makes one attempt and returns after the ad terminal result',
    (WidgetTester tester) async {
      final Completer<bool> terminal = Completer<bool>();
      final _TestInterstitialManager manager =
          _TestInterstitialManager(() => terminal.future);
      await _openFeature(tester, manager);

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      expect(manager.requestCount, 1);
      expect(find.text('Feature content'), findsOneWidget);

      // A second Back event during the same exit must not request another ad.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(manager.requestCount, 1);

      terminal.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Open feature'), findsOneWidget);
      expect(find.text('Feature content'), findsNothing);
    },
  );

  testWidgets(
    'unavailable ad continues system Back without delay',
    (WidgetTester tester) async {
      final _TestInterstitialManager manager =
          _TestInterstitialManager(() async => false);
      await _openFeature(tester, manager);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(manager.requestCount, 1);
      expect(find.text('Open feature'), findsOneWidget);
      expect(find.text('Feature content'), findsNothing);
    },
  );

  testWidgets(
    'missing terminal callback falls back to navigation once',
    (WidgetTester tester) async {
      final Completer<bool> terminal = Completer<bool>();
      addTearDown(() {
        if (!terminal.isCompleted) terminal.complete(false);
      });
      final _TestInterstitialManager manager =
          _TestInterstitialManager(() => terminal.future);
      await _openFeature(
        tester,
        manager,
        fallbackTimeout: const Duration(milliseconds: 50),
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Feature content'), findsOneWidget);
      expect(manager.requestCount, 1);

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();
      expect(find.text('Open feature'), findsOneWidget);
      expect(find.text('Feature content'), findsNothing);
      expect(manager.requestCount, 1);
    },
  );

  testWidgets(
    'interstitial exception cannot block AppBar Back',
    (WidgetTester tester) async {
      final _TestInterstitialManager manager = _TestInterstitialManager(
        () async => throw StateError('simulated show failure'),
      );
      await _openFeature(tester, manager);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(manager.requestCount, 1);
      expect(find.text('Open feature'), findsOneWidget);
      expect(find.text('Feature content'), findsNothing);
    },
  );

  testWidgets(
    'root Back is not treated as a screen exit',
    (WidgetTester tester) async {
      final _TestInterstitialManager manager =
          _TestInterstitialManager(() async => true);
      await tester.pumpWidget(
        MaterialApp(
          home: AdReturnNavigationScope(
            manager: manager,
            child: const Scaffold(
              body: Center(child: Text('Root feature')),
            ),
          ),
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(manager.requestCount, 0);
      expect(find.text('Root feature'), findsOneWidget);
    },
  );
}
