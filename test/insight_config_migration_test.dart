import 'package:test/test.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

void main() {
  test(
    "migrate from default v1 to v2",
    () {
      expect(weatherInsightLoader.withoutDefault().fromJson(WeatherInsightConfigV1.initial.toJson()), WeatherInsightConfigV2.initial);
    },
  );
  test(
    "migrate from v1 with insane finangled temperatures to v2",
    () {
      final v1 = WeatherInsightConfigV1.initial.copyWith(
        boilingMinTemp: const Data(10.0, Temp.celsius),
        freezingMaxTemp: const Data(30.0, Temp.celsius),
      );
      expect(weatherInsightLoader.withoutDefault().fromJson(v1.toJson()), WeatherInsightConfigV2.initial);
    },
  );
  test(
    "migrate from v1 with finangled temperatures to v2",
    () {
      final v1 = WeatherInsightConfigV1.initial.copyWith(
        boilingMinTemp: const Data(30.0, Temp.celsius),
        freezingMaxTemp: const Data(10.0, Temp.celsius),
      );
      final v2 = WeatherInsightConfigV2.initial.copyWith(
        tempMinBoiling: const Data(30.0, Temp.celsius),
        tempMinHot: const Data(25.0, Temp.celsius),
        tempMinWarm: const Data(20.0, Temp.celsius),
        tempMinMild: const Data(15.0, Temp.celsius),
        tempMinChilly: const Data(10.0, Temp.celsius),
      );
      expect(weatherInsightLoader.withoutDefault().fromJson(v1.toJson()), v2);
    },
  );
  test(
    "migrate from v1 with finangled boiling temperature to v2",
    () {
      final v1 = WeatherInsightConfigV1.initial.copyWith(
        boilingMinTemp: const Data(25.0, Temp.celsius),
      );
      final v2 = WeatherInsightConfigV2.initial.copyWith(
        tempMinBoiling: const Data(25.0, Temp.celsius),
        tempMinHot: const Data(20.0, Temp.celsius),
        tempMinWarm: const Data(15.0, Temp.celsius),
        tempMinMild: const Data(10.0, Temp.celsius),
        tempMinChilly: const Data(5.0, Temp.celsius),
      );
      expect(weatherInsightLoader.withoutDefault().fromJson(v1.toJson()), v2);
    },
  );
  test(
    "migrate from v1 with finangled freezing temperatures to v2",
    () {
      final v1 = WeatherInsightConfigV1.initial.copyWith(
        freezingMaxTemp: const Data(-20.0, Temp.celsius),
      );
      final v2 = WeatherInsightConfigV2.initial.copyWith(
        tempMinBoiling: const Data(20.0, Temp.celsius),
        tempMinHot: const Data(10.0, Temp.celsius),
        tempMinWarm: const Data(0.0, Temp.celsius),
        tempMinMild: const Data(-10.0, Temp.celsius),
        tempMinChilly: const Data(-20.0, Temp.celsius),
      );
      expect(weatherInsightLoader.withoutDefault().fromJson(v1.toJson()), v2);
    },
  );
  test(
    "migrate v2 -> v2",
    () {
      expect(weatherInsightLoader.withoutDefault().fromJson(WeatherInsightConfigV2.initial.toJson()), WeatherInsightConfigV2.initial);
    },
  );
}
