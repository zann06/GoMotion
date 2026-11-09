import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/data/repositories/json_fixture_repository.dart';
import 'package:gomotion/domain/entities/fixtures.dart';
import 'package:gomotion/simulation/driver_assigner.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';
import 'package:gomotion/simulation/simulation_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DriverAssigner', () {
    late List<Driver> drivers;

    setUpAll(() async {
      drivers = (await JsonFixtureRepository().load()).drivers;
    });

    test('is reproducible for the same ride id', () {
      final first = DriverAssigner.assign(
        rideId: 'ride_123',
        candidates: drivers,
      );
      final second = DriverAssigner.assign(
        rideId: 'ride_123',
        candidates: drivers,
      );

      expect(first, isNotNull);
      expect(first!.id, second!.id);
    });

    test('is stable regardless of candidate ordering', () {
      final forward = DriverAssigner.assign(
        rideId: 'ride_abc',
        candidates: drivers,
      );
      final reversed = DriverAssigner.assign(
        rideId: 'ride_abc',
        candidates: drivers.reversed.toList(),
      );

      expect(forward!.id, reversed!.id);
    });

    test('can select different drivers for different ride ids', () {
      final ids = {
        for (var i = 0; i < 40; i++)
          DriverAssigner.assign(rideId: 'ride_$i', candidates: drivers)!.id,
      };

      // With three fixture drivers and 40 rides, assignment must not collapse
      // to a single driver.
      expect(ids.length, greaterThan(1));
    });

    test('returns null when there are no candidates', () {
      expect(
        DriverAssigner.assign(rideId: 'ride_x', candidates: const []),
        isNull,
      );
    });

    test('changing the seed can change the assignment', () {
      final assignments = {
        for (var seed = 0; seed < 10; seed++)
          DriverAssigner.assign(
            rideId: 'ride_seeded',
            candidates: drivers,
            seed: seed,
          )!.id,
      };

      expect(assignments.length, greaterThan(1));
    });
  });

  group('FakeSimulationClock', () {
    test('starts at a fixed deterministic time', () {
      final clock = FakeSimulationClock();
      final other = FakeSimulationClock();

      expect(clock.now(), other.now());
    });

    test('runs scheduled callbacks only when time advances', () {
      final clock = FakeSimulationClock();
      var fired = 0;

      clock.schedule(const Duration(seconds: 2), () => fired++);

      expect(fired, 0);
      clock.advance(const Duration(seconds: 1));
      expect(fired, 0);
      clock.advance(const Duration(seconds: 1));
      expect(fired, 1);
    });

    test('runs callbacks in due order', () {
      final clock = FakeSimulationClock();
      final order = <String>[];

      clock.schedule(const Duration(seconds: 3), () => order.add('c'));
      clock.schedule(const Duration(seconds: 1), () => order.add('a'));
      clock.schedule(const Duration(seconds: 2), () => order.add('b'));

      clock.advance(const Duration(seconds: 5));

      expect(order, ['a', 'b', 'c']);
    });

    test('respects cancellation', () {
      final clock = FakeSimulationClock();
      var fired = false;

      final cancel = clock.schedule(
        const Duration(seconds: 1),
        () => fired = true,
      );
      cancel();
      clock.advance(const Duration(seconds: 5));

      expect(fired, isFalse);
      expect(clock.pendingCount, 0);
    });

    test('cancelAll drops every pending task', () {
      final clock = FakeSimulationClock();
      var fired = 0;

      clock.schedule(const Duration(seconds: 1), () => fired++);
      clock.schedule(const Duration(seconds: 2), () => fired++);
      clock.cancelAll();
      clock.advance(const Duration(seconds: 10));

      expect(fired, 0);
      expect(clock.pendingCount, 0);
    });

    test('advanced time is reflected by now()', () {
      final start = DateTime.utc(2026, 1, 1);
      final clock = FakeSimulationClock(start: start);

      clock.advance(const Duration(minutes: 3));

      expect(clock.now(), start.add(const Duration(minutes: 3)));
    });

    test('implements the SimulationClock contract', () {
      final clock = FakeSimulationClock();

      expect(clock, isA<SimulationClock>());
    });
  });
}
