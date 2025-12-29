// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/navigation/navigation_route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final routeA = MaterialPageRoute<void>(builder: (context) => const Text('A'), settings: const RouteSettings(name: 'ROUTE A'));
  final routeB = MaterialPageRoute<void>(builder: (context) => const Text('B'), settings: const RouteSettings(name: 'ROUTE B'));
  final routeC = MaterialPageRoute<void>(builder: (context) => const Text('C'), settings: const RouteSettings(name: 'ROUTE C'));

  group('Navigation route observer', () {
    test('Initial route should be null', () {
      final routeObserver = NavigationRouteObserver();

      expect(routeObserver.top, isNull);
    });

    test('Push route B', () {
      final routeObserver = NavigationRouteObserver();

      routeObserver.didPush(routeB, routeA);

      expect(routeObserver.top, routeB);

      routeObserver.clear();
    });

    test('Push route C', () {
      final routeObserver = NavigationRouteObserver();

      routeObserver.didPush(routeB, routeA);
      routeObserver.didPush(routeC, routeB);

      expect(routeObserver.top, routeC);

      routeObserver.clear();
    });

    test('Pop route C', () {
      final routeObserver = NavigationRouteObserver();

      routeObserver.didPush(routeA, null);
      routeObserver.didPush(routeB, routeA);
      routeObserver.didPush(routeC, routeB);
      routeObserver.didPop(routeC, routeB);

      expect(routeObserver.top, routeB);

      routeObserver.clear();
    });

    test('Replace route B with A', () {
      final routeObserver = NavigationRouteObserver();

      routeObserver.didPush(routeA, null);
      routeObserver.didPush(routeB, routeA);
      routeObserver.didReplace(newRoute: routeA, oldRoute: routeB);

      expect(routeObserver.top, routeA);

      routeObserver.clear();
    });

    test('Remove route A', () {
      final routeObserver = NavigationRouteObserver();

      routeObserver.didPush(routeA, null);
      routeObserver.didPush(routeB, routeA);
      routeObserver.didRemove(routeA, routeC);

      expect(routeObserver.top, routeB);

      routeObserver.clear();
    });
  });
}
