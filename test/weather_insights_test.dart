import 'package:test/test.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

import 'data_units_test.dart';

void main() {
  group(
    "active hours",
    () {
      test(
        "empty activehours",
        () {
          final empty = ActiveHours.empty();
          expect(empty.individualHours, <int>{});
          expect(empty.isEmpty, true);
          expect(empty.isNotEmpty, false);
          expect(empty.numActiveHours, 0);
          expect(empty.asRanges, []);
        },
      );

      test(
        "consecutive run",
        () {
          final empty = ActiveHours({1, 2, 3, 4, 5});
          expect(empty.individualHours, {1, 2, 3, 4, 5});
          expect(empty.isEmpty, false);
          expect(empty.isNotEmpty, true);
          expect(empty.numActiveHours, 5);
          expect(empty.asRanges, [(1, 5)]);
        },
      );

      test(
        "separate hours",
        () {
          final hours = ActiveHours({1, 5, 10, 100, 250});
          expect(hours.individualHours, {1, 5, 10, 100, 250});
          expect(hours.isEmpty, false);
          expect(hours.isNotEmpty, true);
          expect(hours.numActiveHours, 5);
          expect(hours.asRanges, [
            (1, 1),
            (5, 5),
            (10, 10),
            (100, 100),
            (250, 250),
          ]);
        },
      );

      test(
        "combined",
        () {
          final hours = ActiveHours({1, 2, 3, 5, 9, 10, 20, 21, 22});
          expect(hours.individualHours, {1, 2, 3, 5, 9, 10, 20, 21, 22});
          expect(hours.isEmpty, false);
          expect(hours.isNotEmpty, true);
          expect(hours.numActiveHours, 9);
          expect(hours.asRanges, [
            (1, 3),
            (5, 5),
            (9, 10),
            (20, 22),
          ]);
        },
      );
    },
  );

  final genericHeatLevelMap = LevelMap(min: Heat.freezing, minValueForLevel: {
    Heat.chilly: const Data(5, Temp.celsius),
    Heat.mild: const Data(10, Temp.celsius),
    Heat.warm: const Data(15, Temp.celsius),
    Heat.hot: const Data(20, Temp.celsius),
    Heat.boiling: const Data(25, Temp.celsius),
  });

  test(
    "heat insight",
    () {
      final insight = HeatLevelInsight(
        const DataSeries(
          [
            // freezing
            1.5,
            2.5,
            3.5,
            4.5,
            // chilly
            5.5,
            6.5,
            7.5,
            8.5,
            9.5,
            // mild
            10.5,
          ],
          Temp.celsius,
        ),
        genericHeatLevelMap,
      );
      expect(insight.min.valueAs(Temp.celsius), approxEquals(1.5));
      expect(insight.max.valueAs(Temp.celsius), approxEquals(10.5));
      expect(insight.levelRanges, [
        (Heat.freezing, 0, 3),
        (Heat.chilly, 4, 8),
        (Heat.mild, 9, 10),
      ]);
      // Can't do this, list equality doesn't happen right
      // expect(insight.nonNullLevelRanges(), [
      //   ([Heat.freezing, Heat.chilly, Heat.mild], 0, 10),
      // ]);
      // so instead
      expect(insight.nonNullLevelRanges().length, 1);
      expect(insight.nonNullLevelRanges().first.$1, [Heat.freezing, Heat.chilly, Heat.mild]);
      expect(insight.nonNullLevelRanges().first.$2, 0);
      expect(insight.nonNullLevelRanges().first.$3, 10);
    },
  );
}
