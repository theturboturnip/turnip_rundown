import 'dart:math' as math;
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/util.dart';

part 'model.g.dart';

enum WeatherStatus {
  sunny,
  cloudy,
  showery,
  rainy,
  thunderstormy,
  snowy,
}

class CurrentWeather {
  const CurrentWeather({
    required this.status,
    required this.dryBulbTemp,
    required this.apparentTemp,
    required this.windspeed,
    required this.relHumidity,
  });

  final WeatherStatus status;
  final Data<Temp> dryBulbTemp;
  final Data<Temp> apparentTemp;
  final Data<Speed> windspeed;
  final Data<Percent> relHumidity;
}

@JsonSerializable()
@UtcDateTimeJsonConverter()
class SunriseSunset {
  final UtcDateTime? nextSunrise;
  // Will be before sunrise if the sun is currently up
  final UtcDateTime? nextSunset;

  SunriseSunset({
    required this.nextSunrise,
    required this.nextSunset,
  });

  factory SunriseSunset.fromJson(Map<String, dynamic> json) => _$SunriseSunsetFromJson(json);
  Map<String, dynamic> toJson() => _$SunriseSunsetToJson(this);
}

// A set of data series about the weather, starting at a consistent point.
// Assumed to be hourly.
@JsonSerializable()
@UtcDateTimeJsonConverter()
class WeatherDataBank {
  final List<UtcDateTime> datapointDateTimes;
  UtcDateTime get hardTimeout => datapointDateTimes.last;

  final DataSeries<Rainfall> precipitation;
  final DataSeries<Percent> precipitationProb;
  final DataSeries<Temp> dryBulbTemp;
  final DataSeries<Temp> estimatedWetBulbGlobeTemp;
  final DataSeries<Speed> windspeed;
  final DataSeries<Percent> relHumidity;
  final DataSeries<Length> snowfall;
  // These aren't available everywhere, so make them nullable.
  // TODO allow backend-specific Sunny detection
  final DataSeries<SolarRadiation>? directRadiation;
  final DataSeries<Percent>? cloudCover;

  final SunriseSunset? sunriseSunset;

  WeatherDataBank({
    required this.datapointDateTimes,
    required this.precipitation,
    required this.precipitationProb,
    required this.dryBulbTemp,
    required this.estimatedWetBulbGlobeTemp,
    required this.windspeed,
    required this.relHumidity,
    required this.snowfall,
    required this.directRadiation,
    required this.cloudCover,
    required this.sunriseSunset,
  }) {
    assert(datapointDateTimes.isNotEmpty);
    assert(datapointDateTimes.length == precipitation.length);
    assert(datapointDateTimes.length == precipitationProb.length);
    assert(datapointDateTimes.length == dryBulbTemp.length);
    assert(datapointDateTimes.length == estimatedWetBulbGlobeTemp.length);
    assert(datapointDateTimes.length == windspeed.length);
    assert(datapointDateTimes.length == relHumidity.length);
    assert(datapointDateTimes.length == snowfall.length);
    if (directRadiation != null) {
      assert(datapointDateTimes.length == directRadiation!.length);
    }
    if (cloudCover != null) {
      assert(datapointDateTimes.length == cloudCover!.length);
    }
  }

  factory WeatherDataBank.fromJson(Map<String, dynamic> json) => _$WeatherDataBankFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherDataBankToJson(this);

  HourlyPredictedWeather? tryExtract(
    UtcDateTime start, {
    int previousHours = 24,
    int nextHours = 24,
  }) {
    // Extract the 24hrs preceding right now and the 24hrs following right now
    final int nowIdx = datapointDateTimes.indexWhere((givenTime) {
      return start.difference(givenTime) < const Duration(hours: 1);
    });
    final int nextIdx = nowIdx + nextHours;
    if (nowIdx < 0 || nextIdx < 0 || nextIdx > datapointDateTimes.length) {
      print("have ${datapointDateTimes.length} times but need ${nextIdx + 1} to satisfy from now $nowIdx to $nextHours in the future. can't extract");
      return null;
    }

    int prevIdx = nowIdx - previousHours;
    if (prevIdx < 0) {
      print("Not enough previous data => truncate");
      prevIdx = 0;
    }
    assert(prevIdx >= 0 && prevIdx < datapointDateTimes.length);

    return HourlyPredictedWeather(
      precipitationUpToNow: precipitation.sublist(prevIdx, nowIdx),
      dateTimesForPredictions: datapointDateTimes.sublist(nowIdx, nextIdx),
      precipitation: precipitation.sublist(nowIdx, nextIdx),
      precipitationProb: precipitationProb.sublist(nowIdx, nextIdx),
      dryBulbTemp: dryBulbTemp.sublist(nowIdx, nextIdx),
      estimatedWetBulbGlobeTemp: estimatedWetBulbGlobeTemp.sublist(nowIdx, nextIdx),
      windspeed: windspeed.sublist(nowIdx, nextIdx),
      relHumidity: relHumidity.sublist(nowIdx, nextIdx),
      directRadiation: directRadiation?.sublist(nowIdx, nextIdx),
      snowfall: snowfall.sublist(nowIdx, nextIdx),
      cloudCover: cloudCover?.sublist(nowIdx, nextIdx),
      sunriseSunset: SunriseSunset(
        // take the nextSunrise and nextSunset only if they are after `start`.
        nextSunrise: (sunriseSunset?.nextSunrise?.isAfter(start) == true) ? sunriseSunset?.nextSunrise : null,
        nextSunset: (sunriseSunset?.nextSunset?.isAfter(start) == true) ? sunriseSunset?.nextSunset : null,
      ),
    );
  }
}

// A set of data series up to N hours from "now", and from M previous hours up to "now".
// TODO rename
class HourlyPredictedWeather {
  const HourlyPredictedWeather({
    required this.precipitationUpToNow,
    required this.dateTimesForPredictions,
    required this.precipitation,
    required this.precipitationProb,
    required this.dryBulbTemp,
    required this.estimatedWetBulbGlobeTemp,
    required this.windspeed,
    required this.relHumidity,
    required this.directRadiation,
    required this.snowfall,
    required this.cloudCover,
    required this.sunriseSunset,
  });

  final DataSeries<Rainfall> precipitationUpToNow;

  final List<UtcDateTime> dateTimesForPredictions;

  final DataSeries<Rainfall> precipitation;
  final DataSeries<Percent> precipitationProb;
  final DataSeries<Temp> dryBulbTemp;
  final DataSeries<Temp> estimatedWetBulbGlobeTemp;
  final DataSeries<Speed> windspeed;
  final DataSeries<Percent> relHumidity;
  final DataSeries<Length> snowfall;
  // These aren't available everywhere, so make them nullable.
  // TODO allow backend-specific Sunny detection
  final DataSeries<SolarRadiation>? directRadiation;
  final DataSeries<Percent>? cloudCover;

  // Sunrise and sunset - null if this API fails for whatever reason.
  final SunriseSunset? sunriseSunset;
}

/// Wet-bulb-globe-temp estimation based on
/// https://pmc.ncbi.nlm.nih.gov/articles/PMC7240860/#gh2152-sec-0002

Data<Temp> estimateWetBulbGlobeTemp({
  required Data<Temp> dryBulbTemp,
  required Data<Speed> windspeed,
  required Data<Percent> relHumidity,
  Data<Temp>? globeTemp,
  Data<Temp>? dewPointTemp,
  Data<SolarRadiation>? solarRadiation,
}) {
  globeTemp ??= (solarRadiation == null)
      ? dryBulbTemp
      : _estimateGlobeTemp(
          dryBulbTemp: dryBulbTemp,
          relHumidity: relHumidity,
          solarRadiation: solarRadiation,
        );

  final globeTempC = globeTemp.valueAs(Temp.celsius); // T_g
  final dryBulbTempC = dryBulbTemp.valueAs(Temp.celsius); // T_a
  final windspeedMPerS = windspeed.valueAs(Speed.mPerS);

  final psychrometricWetBulbTempC = _estimatePsychrometricWetBulbTemp(
    dryBulbTemp: dryBulbTemp,
    ambientVaporPressure: (dewPointTemp == null)
        ? _estimateAmbientVaporPressureFromRelHumidity(relHumidity: relHumidity, dryBulbTemp: dryBulbTemp)
        : _estimateAmbientVaporPressureFromDewPoint(dewPointTemp: dewPointTemp),
  ).valueAs(Temp.celsius);

  double naturalWetBulbTempC;

  if ((globeTempC - dryBulbTempC) < 4) {
    double constantTerm;
    if (windspeedMPerS < 0.03) {
      constantTerm = 0.85;
    } else if (windspeedMPerS > 3) {
      constantTerm = 1.0;
    } else {
      constantTerm = 0.96 + 0.069 * (math.log(windspeedMPerS) / math.ln10);
    }
    naturalWetBulbTempC = dryBulbTempC - constantTerm * (dryBulbTempC - psychrometricWetBulbTempC);
  } else {
    // The effect of radiant heat (equation 2)
    double e;
    if (windspeedMPerS < 0.1) {
      e = 1.1;
    } else if (windspeedMPerS > 1.0) {
      e = -0.1;
    } else {
      e = (0.1 / math.pow(windspeedMPerS, 1.1)) - 0.2;
    }

    naturalWetBulbTempC = psychrometricWetBulbTempC + 0.25 * (globeTempC - dryBulbTempC) + e;
  }

  return Data(
    0.7 * naturalWetBulbTempC + 0.2 * globeTempC + 0.1 * dryBulbTempC,
    Temp.celsius,
  );
}

// Data<Temp> _estimateNaturalWetBulbTemp() {}
Data<Temp> _estimateGlobeTemp({required Data<Temp> dryBulbTemp, required Data<Percent> relHumidity, required Data<SolarRadiation> solarRadiation}) {
  return Data(
    0.009624 * solarRadiation.valueAs(SolarRadiation.wPerM2) + 1.102 * dryBulbTemp.valueAs(Temp.celsius) - 0.00404 * relHumidity.valueAs(Percent.outOf100) - 2.2776,
    Temp.celsius,
  );
}

// TODO: unsure of ambient vapor pressure unit
Data<Temp> _estimatePsychrometricWetBulbTemp({required double ambientVaporPressure, required Data<Temp> dryBulbTemp}) {
  final pwbTempC = 0.376 + 5.79 * ambientVaporPressure + (0.388 - 0.0465 * ambientVaporPressure) * dryBulbTemp.valueAs(Temp.celsius);
  return Data(pwbTempC, Temp.celsius);
}

double _estimateAmbientVaporPressureFromRelHumidity({required Data<Percent> relHumidity, required Data<Temp> dryBulbTemp}) {
  return relHumidity.valueAs(Percent.outOf1) * _estimateAmbientVaporPressureFromDewPoint(dewPointTemp: dryBulbTemp);
}

double _estimateAmbientVaporPressureFromDewPoint({required Data<Temp> dewPointTemp}) {
  const a = 0.6107;
  const b = 17.27;
  const c = 237.3;
  final dewPointC = dewPointTemp.valueAs(Temp.celsius);

  return a * math.exp((b * dewPointC) / (dewPointC + c));
}
