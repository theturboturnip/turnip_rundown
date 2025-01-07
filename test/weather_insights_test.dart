import 'package:test/test.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

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

  // TODO test actual insights
}
