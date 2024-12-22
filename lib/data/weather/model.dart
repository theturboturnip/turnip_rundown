import 'dart:math' as math;
import 'package:turnip_rundown/data/units.dart';

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

class HourlyPredictedWeather {
  const HourlyPredictedWeather({
    required this.precipitationSince24hrAgo,
    required this.precipitation,
    required this.precipitationProb,
    required this.dryBulbTemp,
    required this.estimatedWetBulbGlobeTemp,
    required this.windspeed,
    required this.relHumidity,
  });

  final DataSeries<Precipitation> precipitationSince24hrAgo;
  final DataSeries<Precipitation> precipitation;
  final DataSeries<Percent> precipitationProb;
  final DataSeries<Temp> dryBulbTemp;
  final DataSeries<Temp> estimatedWetBulbGlobeTemp;
  final DataSeries<Speed> windspeed;
  final DataSeries<Percent> relHumidity;
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
