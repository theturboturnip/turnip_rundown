import 'package:test/test.dart';
import 'package:turnip_rundown/data/units.dart';
import 'dart:math' as math;

// Test actual is within 1% of expected
Matcher approxEquals(double expected) => closeTo(expected, math.max(expected * 0.005, 0.5));

void Function() testUnit<TUnit extends Unit<TUnit>>(List<TUnit> units, List<(Data<TUnit>, Data<TUnit>)> examples) => () {
      for (final (expected1, expected2) in examples) {
        for (final unit in units) {
          test("${expected1.toDisplayString()} = ${expected2.toDisplayString()} in ${unit.display}", () {
            expect(expected1.valueAs(unit), approxEquals(expected2.valueAs(unit)));
          });
        }
      }
    };

void main() {
  group(
    "temperature",
    testUnit(
      Temp.values,
      const [
        (Data(0.0, Temp.celsius), Data(32.0, Temp.farenheit)),
        (Data(100.0, Temp.celsius), Data(212.0, Temp.farenheit)),
        (Data(50.0, Temp.celsius), Data(323.15, Temp.kelvin)),
        (Data(32.0, Temp.farenheit), Data(273.15, Temp.kelvin)),
      ],
    ),
  );

  group(
    "speed",
    testUnit(
      Speed.values,
      const [
        (Data(1, Speed.milesPerHour), Data(0.447, Speed.mPerS)),
        (Data(1, Speed.milesPerHour), Data(1.609, Speed.kmPerH)),
        (Data(1, Speed.mPerS), Data(3.6, Speed.kmPerH)),
      ],
    ),
  );

  group(
    "percent",
    testUnit(
      Percent.values,
      const [
        (Data(0, Percent.outOf1), Data(0, Percent.outOf100)),
        (Data(1.0, Percent.outOf1), Data(100, Percent.outOf100)),
      ],
    ),
  );

  group(
    "pressure",
    testUnit(
      Pressure.values,
      const [
        (Data(0, Pressure.millibars), Data(0, Pressure.hectopascals)),
        (Data(1000, Pressure.millibars), Data(1000, Pressure.hectopascals)),
      ],
    ),
  );

  group(
    "length",
    testUnit(
      Length.values,
      const [
        (Data(1.0, Length.m), Data(1.0, Length.m)),
        (Data(1.0, Length.m), Data(100.0, Length.cm)),
        (Data(1.0, Length.m), Data(1000.0, Length.mm)),
        (Data(1.0, Length.inch), Data(2.54, Length.cm)),
      ],
    ),
  );
}
