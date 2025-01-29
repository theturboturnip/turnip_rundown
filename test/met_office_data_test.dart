import 'package:test/test.dart';
import 'package:turnip_rundown/data/units.dart';

import 'package:turnip_rundown/data/weather/met/repository.dart';
import 'package:turnip_rundown/data/weather/model.dart';

void expectDataHasLength(HourlyPredictedWeather data, int expectedLength) {
  expect(data.precipitationUpToNow.length, 0);
  expect(data.dateTimesForPredictions.length, expectedLength);
  expect(data.precipitation.length, expectedLength);
  expect(data.precipitationProb.length, expectedLength);
  expect(data.dryBulbTemp.length, expectedLength);
  expect(data.estimatedWetBulbGlobeTemp.length, expectedLength);
  expect(data.windspeed.length, expectedLength);
  expect(data.relHumidity.length, expectedLength);
  expect(data.snowfall.length, expectedLength);
  expect(data.directRadiation, null);
  expect(data.cloudCover, null);
}

void expectDefaultUnits(HourlyPredictedWeather data) {
  expect(data.precipitation.unit, Length.mm);
  expect(data.precipitationProb.unit, Percent.outOf100);
  expect(data.dryBulbTemp.unit, Temp.celsius);
  expect(data.estimatedWetBulbGlobeTemp.unit, Temp.celsius);
  expect(data.windspeed.unit, Speed.mPerS);
  expect(data.relHumidity.unit, Percent.outOf100);
  expect(data.snowfall.unit, Length.mm);
}

void main() {
  test(
    "can parse cambridge example",
    () {
      final data = predictWeatherFromMetGeoJson(cambridgeExample, cutoffTime: DateTime.utc(2025, 01, 29, 1), numAfterCutoff: 100);
      expect(
        data.dryBulbTemp.valuesAs(Temp.celsius),
        pairwiseCompare(
          [
            6.38,
            6.29,
            6.17,
            5.93,
            5.96,
            6.18,
            5.94,
            5.52,
            5.75,
            6.48,
            7.26,
            7.85,
            8.23,
            8.25,
            8.07,
            7.37,
            6.54,
            6.07,
            6.09,
            5.92,
            5.75,
            5.52,
            5.42,
            4.96,
            4.53,
            4,
            3.49,
            2.9,
            2.36,
            1.91,
            1.77,
            1.52,
            1.91,
            3.17,
            4.52,
            5.79,
            6.3,
            6.67,
            6.73,
            5.79,
            4.6,
            3.59,
            3.1,
            2.51,
            2.02,
            1.93,
            1.88,
            1.71,
            1.71,
          ],
          (expected, actual) => closeTo(expected, 0.005).matches(actual, {}),
          "matches expected sequence",
        ),
      );
      expectDataHasLength(data, 49);
      expectDefaultUnits(data);
    },
  );

  test(
    "can parse cambridge example when cutoff time after start",
    () {
      // +55minutes shouldn't affect the start point
      final data = predictWeatherFromMetGeoJson(cambridgeExample, cutoffTime: DateTime.utc(2025, 01, 29, 1, 55), numAfterCutoff: 100);
      expect(data.dateTimesForPredictions.first, DateTime.utc(2025, 1, 29, 1, 0));
      expectDataHasLength(data, 49);
      expectDefaultUnits(data);

      // +1hr moves it up by one
      final data2 = predictWeatherFromMetGeoJson(cambridgeExample, cutoffTime: DateTime.utc(2025, 01, 29, 2, 1), numAfterCutoff: 100);
      expect(data2.dateTimesForPredictions.first, DateTime.utc(2025, 1, 29, 2, 0));
      expectDataHasLength(data2, 48);
      expectDefaultUnits(data2);

      // +24hr moves it up by 24
      final data3 = predictWeatherFromMetGeoJson(cambridgeExample, cutoffTime: DateTime.utc(2025, 01, 30, 1), numAfterCutoff: 100);
      expect(data3.dateTimesForPredictions.first, DateTime.utc(2025, 1, 30, 1, 0));
      expectDataHasLength(data3, 25);
      expectDefaultUnits(data3);
    },
  );
}

const String cambridgeExample = """{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          0.124,
          52.2075,
          7
        ]
      },
      "properties": {
        "location": {
          "name": "Cambridge"
        },
        "requestPointDistance": 389.4068,
        "modelRunDate": "2025-01-29T01:00Z",
        "timeSeries": [
          {
            "time": "2025-01-29T01:00Z",
            "screenTemperature": 6.38,
            "maxScreenAirTemp": 6.56,
            "minScreenAirTemp": 6.3,
            "screenDewPointTemperature": 3.57,
            "feelsLikeTemperature": 2.98,
            "windSpeed10m": 5.14,
            "windDirectionFrom10m": 259,
            "windGustSpeed10m": 11.83,
            "max10mWindGust": 12.43,
            "visibility": 19560,
            "screenRelativeHumidity": 82.23,
            "mslp": 99630,
            "uvIndex": 0,
            "significantWeatherCode": 2,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T02:00Z",
            "screenTemperature": 6.29,
            "maxScreenAirTemp": 6.38,
            "minScreenAirTemp": 6.25,
            "screenDewPointTemperature": 3.51,
            "feelsLikeTemperature": 2.96,
            "windSpeed10m": 4.95,
            "windDirectionFrom10m": 257,
            "windGustSpeed10m": 11.31,
            "max10mWindGust": 11.86,
            "visibility": 20675,
            "screenRelativeHumidity": 82.38,
            "mslp": 99678,
            "uvIndex": 0,
            "significantWeatherCode": 2,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T03:00Z",
            "screenTemperature": 6.17,
            "maxScreenAirTemp": 6.29,
            "minScreenAirTemp": 6,
            "screenDewPointTemperature": 3.95,
            "feelsLikeTemperature": 2.61,
            "windSpeed10m": 5.41,
            "windDirectionFrom10m": 258,
            "windGustSpeed10m": 12.18,
            "max10mWindGust": 12.18,
            "visibility": 20887,
            "screenRelativeHumidity": 85.69,
            "mslp": 99744,
            "uvIndex": 0,
            "significantWeatherCode": 2,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T04:00Z",
            "screenTemperature": 5.93,
            "maxScreenAirTemp": 6.17,
            "minScreenAirTemp": 5.88,
            "screenDewPointTemperature": 4.02,
            "feelsLikeTemperature": 2.61,
            "windSpeed10m": 4.76,
            "windDirectionFrom10m": 259,
            "windGustSpeed10m": 10.97,
            "max10mWindGust": 12.26,
            "visibility": 20486,
            "screenRelativeHumidity": 87.63,
            "mslp": 99831,
            "uvIndex": 0,
            "significantWeatherCode": 2,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T05:00Z",
            "screenTemperature": 5.96,
            "maxScreenAirTemp": 6.05,
            "minScreenAirTemp": 5.93,
            "screenDewPointTemperature": 4.05,
            "feelsLikeTemperature": 2.74,
            "windSpeed10m": 4.55,
            "windDirectionFrom10m": 254,
            "windGustSpeed10m": 10.65,
            "max10mWindGust": 11.23,
            "visibility": 19207,
            "screenRelativeHumidity": 87.54,
            "mslp": 99870,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 4
          },
          {
            "time": "2025-01-29T06:00Z",
            "screenTemperature": 6.18,
            "maxScreenAirTemp": 6.28,
            "minScreenAirTemp": 5.96,
            "screenDewPointTemperature": 4.06,
            "feelsLikeTemperature": 2.89,
            "windSpeed10m": 4.79,
            "windDirectionFrom10m": 251,
            "windGustSpeed10m": 10.46,
            "max10mWindGust": 11.01,
            "visibility": 19538,
            "screenRelativeHumidity": 86.32,
            "mslp": 99940,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 5
          },
          {
            "time": "2025-01-29T07:00Z",
            "screenTemperature": 5.94,
            "maxScreenAirTemp": 6.18,
            "minScreenAirTemp": 5.92,
            "screenDewPointTemperature": 3.98,
            "feelsLikeTemperature": 2.58,
            "windSpeed10m": 4.79,
            "windDirectionFrom10m": 251,
            "windGustSpeed10m": 10.75,
            "max10mWindGust": 11.03,
            "visibility": 19524,
            "screenRelativeHumidity": 87.37,
            "mslp": 100020,
            "uvIndex": 0,
            "significantWeatherCode": 2,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T08:00Z",
            "screenTemperature": 5.52,
            "maxScreenAirTemp": 5.94,
            "minScreenAirTemp": 5.51,
            "screenDewPointTemperature": 3.64,
            "feelsLikeTemperature": 2.44,
            "windSpeed10m": 4.09,
            "windDirectionFrom10m": 251,
            "windGustSpeed10m": 10,
            "max10mWindGust": 10.77,
            "visibility": 18190,
            "screenRelativeHumidity": 87.79,
            "mslp": 100052,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T09:00Z",
            "screenTemperature": 5.75,
            "maxScreenAirTemp": 5.77,
            "minScreenAirTemp": 5.52,
            "screenDewPointTemperature": 3.78,
            "feelsLikeTemperature": 3.05,
            "windSpeed10m": 3.53,
            "windDirectionFrom10m": 249,
            "windGustSpeed10m": 7.81,
            "max10mWindGust": 9.43,
            "visibility": 17533,
            "screenRelativeHumidity": 87.34,
            "mslp": 100092,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T10:00Z",
            "screenTemperature": 6.48,
            "maxScreenAirTemp": 6.5,
            "minScreenAirTemp": 5.75,
            "screenDewPointTemperature": 4.06,
            "feelsLikeTemperature": 3.53,
            "windSpeed10m": 4.25,
            "windDirectionFrom10m": 251,
            "windGustSpeed10m": 7.31,
            "max10mWindGust": 7.99,
            "visibility": 18915,
            "screenRelativeHumidity": 84.69,
            "mslp": 100166,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T11:00Z",
            "screenTemperature": 7.26,
            "maxScreenAirTemp": 7.27,
            "minScreenAirTemp": 6.48,
            "screenDewPointTemperature": 4.05,
            "feelsLikeTemperature": 4.54,
            "windSpeed10m": 4.17,
            "windDirectionFrom10m": 253,
            "windGustSpeed10m": 6.85,
            "max10mWindGust": 7.46,
            "visibility": 21073,
            "screenRelativeHumidity": 80.17,
            "mslp": 100224,
            "uvIndex": 1,
            "significantWeatherCode": 3,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-29T12:00Z",
            "screenTemperature": 7.85,
            "maxScreenAirTemp": 7.87,
            "minScreenAirTemp": 7.2,
            "screenDewPointTemperature": 3.97,
            "feelsLikeTemperature": 5.46,
            "windSpeed10m": 3.81,
            "windDirectionFrom10m": 262,
            "windGustSpeed10m": 6.56,
            "max10mWindGust": 6.56,
            "visibility": 24403,
            "screenRelativeHumidity": 76.59,
            "mslp": 100258,
            "uvIndex": 1,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 3
          },
          {
            "time": "2025-01-29T13:00Z",
            "screenTemperature": 8.23,
            "maxScreenAirTemp": 8.27,
            "minScreenAirTemp": 7.85,
            "screenDewPointTemperature": 3.19,
            "feelsLikeTemperature": 6.12,
            "windSpeed10m": 3.5,
            "windDirectionFrom10m": 270,
            "windGustSpeed10m": 5.88,
            "max10mWindGust": 6.15,
            "visibility": 26397,
            "screenRelativeHumidity": 70.75,
            "mslp": 100278,
            "uvIndex": 1,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 4
          },
          {
            "time": "2025-01-29T14:00Z",
            "screenTemperature": 8.25,
            "maxScreenAirTemp": 8.28,
            "minScreenAirTemp": 8.23,
            "screenDewPointTemperature": 2.95,
            "feelsLikeTemperature": 6.68,
            "windSpeed10m": 2.65,
            "windDirectionFrom10m": 264,
            "windGustSpeed10m": 4.48,
            "max10mWindGust": 5.52,
            "visibility": 25638,
            "screenRelativeHumidity": 69.4,
            "mslp": 100299,
            "uvIndex": 1,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 5
          },
          {
            "time": "2025-01-29T15:00Z",
            "screenTemperature": 8.07,
            "maxScreenAirTemp": 8.25,
            "minScreenAirTemp": 8.04,
            "screenDewPointTemperature": 2.96,
            "feelsLikeTemperature": 6.89,
            "windSpeed10m": 2.09,
            "windDirectionFrom10m": 273,
            "windGustSpeed10m": 3.9,
            "max10mWindGust": 4.55,
            "visibility": 24762,
            "screenRelativeHumidity": 70.25,
            "mslp": 100338,
            "uvIndex": 1,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T16:00Z",
            "screenTemperature": 7.37,
            "maxScreenAirTemp": 8.07,
            "minScreenAirTemp": 7.33,
            "screenDewPointTemperature": 3,
            "feelsLikeTemperature": 6.47,
            "windSpeed10m": 1.63,
            "windDirectionFrom10m": 289,
            "windGustSpeed10m": 3.56,
            "max10mWindGust": 4.17,
            "visibility": 21967,
            "screenRelativeHumidity": 74,
            "mslp": 100389,
            "uvIndex": 1,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T17:00Z",
            "screenTemperature": 6.54,
            "maxScreenAirTemp": 7.37,
            "minScreenAirTemp": 6.51,
            "screenDewPointTemperature": 2.91,
            "feelsLikeTemperature": 5.57,
            "windSpeed10m": 1.52,
            "windDirectionFrom10m": 301,
            "windGustSpeed10m": 3.46,
            "max10mWindGust": 4.01,
            "visibility": 18638,
            "screenRelativeHumidity": 77.82,
            "mslp": 100460,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T18:00Z",
            "screenTemperature": 6.07,
            "maxScreenAirTemp": 6.54,
            "minScreenAirTemp": 6.06,
            "screenDewPointTemperature": 2.88,
            "feelsLikeTemperature": 4.94,
            "windSpeed10m": 1.65,
            "windDirectionFrom10m": 333,
            "windGustSpeed10m": 4.27,
            "max10mWindGust": 4.69,
            "visibility": 17705,
            "screenRelativeHumidity": 80.11,
            "mslp": 100520,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T19:00Z",
            "screenTemperature": 6.09,
            "maxScreenAirTemp": 6.11,
            "minScreenAirTemp": 6.04,
            "screenDewPointTemperature": 2.81,
            "feelsLikeTemperature": 4.3,
            "windSpeed10m": 2.41,
            "windDirectionFrom10m": 343,
            "windGustSpeed10m": 5.59,
            "max10mWindGust": 5.99,
            "visibility": 18166,
            "screenRelativeHumidity": 79.69,
            "mslp": 100610,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T20:00Z",
            "screenTemperature": 5.92,
            "maxScreenAirTemp": 6.09,
            "minScreenAirTemp": 5.9,
            "screenDewPointTemperature": 2.83,
            "feelsLikeTemperature": 3.69,
            "windSpeed10m": 2.92,
            "windDirectionFrom10m": 355,
            "windGustSpeed10m": 6.88,
            "max10mWindGust": 7.46,
            "visibility": 18255,
            "screenRelativeHumidity": 80.7,
            "mslp": 100700,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T21:00Z",
            "screenTemperature": 5.75,
            "maxScreenAirTemp": 5.92,
            "minScreenAirTemp": 5.71,
            "screenDewPointTemperature": 2.83,
            "feelsLikeTemperature": 3.1,
            "windSpeed10m": 3.48,
            "windDirectionFrom10m": 0,
            "windGustSpeed10m": 7.49,
            "max10mWindGust": 8.21,
            "visibility": 18631,
            "screenRelativeHumidity": 81.66,
            "mslp": 100781,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T22:00Z",
            "screenTemperature": 5.52,
            "maxScreenAirTemp": 5.75,
            "minScreenAirTemp": 5.5,
            "screenDewPointTemperature": 2.68,
            "feelsLikeTemperature": 2.78,
            "windSpeed10m": 3.56,
            "windDirectionFrom10m": 358,
            "windGustSpeed10m": 7.52,
            "max10mWindGust": 8.44,
            "visibility": 20099,
            "screenRelativeHumidity": 82.11,
            "mslp": 100851,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-29T23:00Z",
            "screenTemperature": 5.42,
            "maxScreenAirTemp": 5.52,
            "minScreenAirTemp": 5.41,
            "screenDewPointTemperature": 2.12,
            "feelsLikeTemperature": 2.4,
            "windSpeed10m": 3.98,
            "windDirectionFrom10m": 352,
            "windGustSpeed10m": 7.93,
            "max10mWindGust": 8.67,
            "visibility": 23261,
            "screenRelativeHumidity": 79.61,
            "mslp": 100950,
            "uvIndex": 0,
            "significantWeatherCode": 8,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 10
          },
          {
            "time": "2025-01-30T00:00Z",
            "screenTemperature": 4.96,
            "maxScreenAirTemp": 5.42,
            "minScreenAirTemp": 4.95,
            "screenDewPointTemperature": 1.68,
            "feelsLikeTemperature": 1.69,
            "windSpeed10m": 4.22,
            "windDirectionFrom10m": 348,
            "windGustSpeed10m": 8.2,
            "max10mWindGust": 8.91,
            "visibility": 22808,
            "screenRelativeHumidity": 79.59,
            "mslp": 101039,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 7
          },
          {
            "time": "2025-01-30T01:00Z",
            "screenTemperature": 4.53,
            "maxScreenAirTemp": 4.96,
            "minScreenAirTemp": 4.5,
            "screenDewPointTemperature": 0.92,
            "feelsLikeTemperature": 1.14,
            "windSpeed10m": 4.25,
            "windDirectionFrom10m": 345,
            "windGustSpeed10m": 8.17,
            "max10mWindGust": 9.17,
            "visibility": 26395,
            "screenRelativeHumidity": 77.69,
            "mslp": 101129,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-30T02:00Z",
            "screenTemperature": 4,
            "maxScreenAirTemp": 4.53,
            "minScreenAirTemp": 3.99,
            "screenDewPointTemperature": 0.53,
            "feelsLikeTemperature": 0.43,
            "windSpeed10m": 4.35,
            "windDirectionFrom10m": 341,
            "windGustSpeed10m": 8.22,
            "max10mWindGust": 9.16,
            "visibility": 29494,
            "screenRelativeHumidity": 78.28,
            "mslp": 101237,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 5
          },
          {
            "time": "2025-01-30T03:00Z",
            "screenTemperature": 3.49,
            "maxScreenAirTemp": 4,
            "minScreenAirTemp": 3.46,
            "screenDewPointTemperature": -0.07,
            "feelsLikeTemperature": -0.15,
            "windSpeed10m": 4.3,
            "windDirectionFrom10m": 336,
            "windGustSpeed10m": 8.39,
            "max10mWindGust": 9.6,
            "visibility": 31699,
            "screenRelativeHumidity": 77.68,
            "mslp": 101345,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 5
          },
          {
            "time": "2025-01-30T04:00Z",
            "screenTemperature": 2.9,
            "maxScreenAirTemp": 3.49,
            "minScreenAirTemp": 2.88,
            "screenDewPointTemperature": -0.75,
            "feelsLikeTemperature": -0.79,
            "windSpeed10m": 4.13,
            "windDirectionFrom10m": 333,
            "windGustSpeed10m": 8.45,
            "max10mWindGust": 9.78,
            "visibility": 32642,
            "screenRelativeHumidity": 77.09,
            "mslp": 101435,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 6
          },
          {
            "time": "2025-01-30T05:00Z",
            "screenTemperature": 2.36,
            "maxScreenAirTemp": 2.9,
            "minScreenAirTemp": 2.35,
            "screenDewPointTemperature": -1,
            "feelsLikeTemperature": -1.31,
            "windSpeed10m": 3.9,
            "windDirectionFrom10m": 328,
            "windGustSpeed10m": 8.37,
            "max10mWindGust": 9.72,
            "visibility": 30202,
            "screenRelativeHumidity": 78.71,
            "mslp": 101534,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 2
          },
          {
            "time": "2025-01-30T06:00Z",
            "screenTemperature": 1.91,
            "maxScreenAirTemp": 2.36,
            "minScreenAirTemp": 1.9,
            "screenDewPointTemperature": -1.17,
            "feelsLikeTemperature": -1.75,
            "windSpeed10m": 3.72,
            "windDirectionFrom10m": 324,
            "windGustSpeed10m": 8.3,
            "max10mWindGust": 9.63,
            "visibility": 27905,
            "screenRelativeHumidity": 80.27,
            "mslp": 101624,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 1
          },
          {
            "time": "2025-01-30T07:00Z",
            "screenTemperature": 1.77,
            "maxScreenAirTemp": 1.91,
            "minScreenAirTemp": 1.77,
            "screenDewPointTemperature": -1.39,
            "feelsLikeTemperature": -1.84,
            "windSpeed10m": 3.62,
            "windDirectionFrom10m": 319,
            "windGustSpeed10m": 8.14,
            "max10mWindGust": 9.59,
            "visibility": 27822,
            "screenRelativeHumidity": 79.83,
            "mslp": 101742,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 1
          },
          {
            "time": "2025-01-30T08:00Z",
            "screenTemperature": 1.52,
            "maxScreenAirTemp": 1.77,
            "minScreenAirTemp": 1.51,
            "screenDewPointTemperature": -1.52,
            "feelsLikeTemperature": -2.01,
            "windSpeed10m": 3.42,
            "windDirectionFrom10m": 313,
            "windGustSpeed10m": 7.99,
            "max10mWindGust": 9.57,
            "visibility": 27949,
            "screenRelativeHumidity": 80.45,
            "mslp": 101851,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 1
          },
          {
            "time": "2025-01-30T09:00Z",
            "screenTemperature": 1.91,
            "maxScreenAirTemp": 1.93,
            "minScreenAirTemp": 1.52,
            "screenDewPointTemperature": -1.53,
            "feelsLikeTemperature": -1.63,
            "windSpeed10m": 3.55,
            "windDirectionFrom10m": 308,
            "windGustSpeed10m": 7.69,
            "max10mWindGust": 9.32,
            "visibility": 27867,
            "screenRelativeHumidity": 78.21,
            "mslp": 101950,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T10:00Z",
            "screenTemperature": 3.17,
            "maxScreenAirTemp": 3.19,
            "minScreenAirTemp": 1.91,
            "screenDewPointTemperature": -1.22,
            "feelsLikeTemperature": -0.31,
            "windSpeed10m": 3.9,
            "windDirectionFrom10m": 310,
            "windGustSpeed10m": 7.07,
            "max10mWindGust": 8.32,
            "visibility": 28423,
            "screenRelativeHumidity": 73.28,
            "mslp": 102019,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T11:00Z",
            "screenTemperature": 4.52,
            "maxScreenAirTemp": 4.55,
            "minScreenAirTemp": 3.17,
            "screenDewPointTemperature": -0.42,
            "feelsLikeTemperature": 1.29,
            "windSpeed10m": 4.03,
            "windDirectionFrom10m": 310,
            "windGustSpeed10m": 7.24,
            "max10mWindGust": 7.44,
            "visibility": 30946,
            "screenRelativeHumidity": 70.6,
            "mslp": 102070,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T12:00Z",
            "screenTemperature": 5.79,
            "maxScreenAirTemp": 5.81,
            "minScreenAirTemp": 4.52,
            "screenDewPointTemperature": 0.03,
            "feelsLikeTemperature": 2.67,
            "windSpeed10m": 4.38,
            "windDirectionFrom10m": 311,
            "windGustSpeed10m": 7.92,
            "max10mWindGust": 7.92,
            "visibility": 33230,
            "screenRelativeHumidity": 66.78,
            "mslp": 102111,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T13:00Z",
            "screenTemperature": 6.3,
            "maxScreenAirTemp": 6.35,
            "minScreenAirTemp": 5.79,
            "screenDewPointTemperature": 0.17,
            "feelsLikeTemperature": 3.29,
            "windSpeed10m": 4.37,
            "windDirectionFrom10m": 308,
            "windGustSpeed10m": 7.87,
            "max10mWindGust": 8.03,
            "visibility": 35044,
            "screenRelativeHumidity": 65.19,
            "mslp": 102160,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T14:00Z",
            "screenTemperature": 6.67,
            "maxScreenAirTemp": 6.7,
            "minScreenAirTemp": 6.3,
            "screenDewPointTemperature": 0.44,
            "feelsLikeTemperature": 3.79,
            "windSpeed10m": 4.26,
            "windDirectionFrom10m": 304,
            "windGustSpeed10m": 7.79,
            "max10mWindGust": 7.9,
            "visibility": 31921,
            "screenRelativeHumidity": 64.77,
            "mslp": 102209,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T15:00Z",
            "screenTemperature": 6.73,
            "maxScreenAirTemp": 6.78,
            "minScreenAirTemp": 6.67,
            "screenDewPointTemperature": 0.45,
            "feelsLikeTemperature": 3.91,
            "windSpeed10m": 4.21,
            "windDirectionFrom10m": 302,
            "windGustSpeed10m": 7.64,
            "max10mWindGust": 8.35,
            "visibility": 32484,
            "screenRelativeHumidity": 64.48,
            "mslp": 102268,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T16:00Z",
            "screenTemperature": 5.79,
            "maxScreenAirTemp": 6.73,
            "minScreenAirTemp": 5.79,
            "screenDewPointTemperature": 0.68,
            "feelsLikeTemperature": 3.19,
            "windSpeed10m": 3.45,
            "windDirectionFrom10m": 292,
            "windGustSpeed10m": 6.94,
            "max10mWindGust": 8.51,
            "visibility": 30849,
            "screenRelativeHumidity": 70.25,
            "mslp": 102327,
            "uvIndex": 1,
            "significantWeatherCode": 1,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T17:00Z",
            "screenTemperature": 4.6,
            "maxScreenAirTemp": 5.79,
            "minScreenAirTemp": 4.6,
            "screenDewPointTemperature": 0.63,
            "feelsLikeTemperature": 1.95,
            "windSpeed10m": 3.17,
            "windDirectionFrom10m": 278,
            "windGustSpeed10m": 6.94,
            "max10mWindGust": 9.4,
            "visibility": 32108,
            "screenRelativeHumidity": 75.98,
            "mslp": 102387,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 1
          },
          {
            "time": "2025-01-30T18:00Z",
            "screenTemperature": 3.59,
            "maxScreenAirTemp": 4.6,
            "minScreenAirTemp": 3.57,
            "screenDewPointTemperature": 0.5,
            "feelsLikeTemperature": 1.09,
            "windSpeed10m": 2.67,
            "windDirectionFrom10m": 266,
            "windGustSpeed10m": 6.19,
            "max10mWindGust": 10.11,
            "visibility": 31059,
            "screenRelativeHumidity": 80.58,
            "mslp": 102438,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T19:00Z",
            "screenTemperature": 3.1,
            "maxScreenAirTemp": 3.59,
            "minScreenAirTemp": 3.1,
            "screenDewPointTemperature": 0.08,
            "feelsLikeTemperature": 0.43,
            "windSpeed10m": 2.79,
            "windDirectionFrom10m": 262,
            "windGustSpeed10m": 6.29,
            "max10mWindGust": 9.39,
            "visibility": 32358,
            "screenRelativeHumidity": 80.99,
            "mslp": 102475,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 0
          },
          {
            "time": "2025-01-30T20:00Z",
            "screenTemperature": 2.51,
            "maxScreenAirTemp": 3.1,
            "minScreenAirTemp": 2.51,
            "screenDewPointTemperature": 0.1,
            "feelsLikeTemperature": -0.17,
            "windSpeed10m": 2.65,
            "windDirectionFrom10m": 256,
            "windGustSpeed10m": 6.04,
            "max10mWindGust": 8.81,
            "visibility": 28285,
            "screenRelativeHumidity": 84.48,
            "mslp": 102495,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 1
          },
          {
            "time": "2025-01-30T21:00Z",
            "screenTemperature": 2.02,
            "maxScreenAirTemp": 2.51,
            "minScreenAirTemp": 1.9,
            "screenDewPointTemperature": -0.04,
            "feelsLikeTemperature": -0.93,
            "windSpeed10m": 2.85,
            "windDirectionFrom10m": 251,
            "windGustSpeed10m": 6.13,
            "max10mWindGust": 8.2,
            "visibility": 28072,
            "screenRelativeHumidity": 86.64,
            "mslp": 102523,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 1
          },
          {
            "time": "2025-01-30T22:00Z",
            "screenTemperature": 1.93,
            "maxScreenAirTemp": 2.02,
            "minScreenAirTemp": 1.77,
            "screenDewPointTemperature": -0.06,
            "feelsLikeTemperature": -0.99,
            "windSpeed10m": 2.78,
            "windDirectionFrom10m": 247,
            "windGustSpeed10m": 6.3,
            "max10mWindGust": 8.4,
            "visibility": 28658,
            "screenRelativeHumidity": 87.13,
            "mslp": 102542,
            "uvIndex": 0,
            "significantWeatherCode": 0,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 1
          },
          {
            "time": "2025-01-30T23:00Z",
            "screenTemperature": 1.88,
            "maxScreenAirTemp": 1.93,
            "minScreenAirTemp": 1.88,
            "screenDewPointTemperature": -0.24,
            "feelsLikeTemperature": -1.13,
            "windSpeed10m": 2.9,
            "windDirectionFrom10m": 243,
            "windGustSpeed10m": 6.32,
            "max10mWindGust": 8.7,
            "visibility": 30625,
            "screenRelativeHumidity": 86.29,
            "mslp": 102542,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "totalPrecipAmount": 0,
            "totalSnowAmount": 0,
            "probOfPrecipitation": 4
          },
          {
            "time": "2025-01-31T00:00Z",
            "screenTemperature": 1.71,
            "screenDewPointTemperature": -0.26,
            "feelsLikeTemperature": -1.35,
            "windSpeed10m": 2.89,
            "windDirectionFrom10m": 236,
            "windGustSpeed10m": 6.08,
            "visibility": 30503,
            "screenRelativeHumidity": 87.28,
            "mslp": 102534,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "probOfPrecipitation": 3
          },
          {
            "time": "2025-01-31T01:00Z",
            "screenTemperature": 1.71,
            "screenDewPointTemperature": -0.16,
            "feelsLikeTemperature": -1.37,
            "windSpeed10m": 2.94,
            "windDirectionFrom10m": 233,
            "windGustSpeed10m": 5.8,
            "visibility": 31161,
            "screenRelativeHumidity": 88,
            "mslp": 102523,
            "uvIndex": 0,
            "significantWeatherCode": 7,
            "precipitationRate": 0,
            "probOfPrecipitation": 4
          }
        ]
      }
    }
  ],
  "parameters": [
    {
      "totalSnowAmount": {
        "type": "Parameter",
        "description": "Total Snow Amount Over Previous Hour",
        "unit": {
          "label": "millimetres",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "mm"
          }
        }
      },
      "screenTemperature": {
        "type": "Parameter",
        "description": "Screen Air Temperature",
        "unit": {
          "label": "degrees Celsius",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "Cel"
          }
        }
      },
      "visibility": {
        "type": "Parameter",
        "description": "Visibility",
        "unit": {
          "label": "metres",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "m"
          }
        }
      },
      "windDirectionFrom10m": {
        "type": "Parameter",
        "description": "10m Wind From Direction",
        "unit": {
          "label": "degrees",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "deg"
          }
        }
      },
      "precipitationRate": {
        "type": "Parameter",
        "description": "Precipitation Rate",
        "unit": {
          "label": "millimetres per hour",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "mm/h"
          }
        }
      },
      "maxScreenAirTemp": {
        "type": "Parameter",
        "description": "Maximum Screen Air Temperature Over Previous Hour",
        "unit": {
          "label": "degrees Celsius",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "Cel"
          }
        }
      },
      "feelsLikeTemperature": {
        "type": "Parameter",
        "description": "Feels Like Temperature",
        "unit": {
          "label": "degrees Celsius",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "Cel"
          }
        }
      },
      "screenDewPointTemperature": {
        "type": "Parameter",
        "description": "Screen Dew Point Temperature",
        "unit": {
          "label": "degrees Celsius",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "Cel"
          }
        }
      },
      "screenRelativeHumidity": {
        "type": "Parameter",
        "description": "Screen Relative Humidity",
        "unit": {
          "label": "percentage",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "%"
          }
        }
      },
      "windSpeed10m": {
        "type": "Parameter",
        "description": "10m Wind Speed",
        "unit": {
          "label": "metres per second",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "m/s"
          }
        }
      },
      "probOfPrecipitation": {
        "type": "Parameter",
        "description": "Probability of Precipitation",
        "unit": {
          "label": "percentage",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "%"
          }
        }
      },
      "max10mWindGust": {
        "type": "Parameter",
        "description": "Maximum 10m Wind Gust Speed Over Previous Hour",
        "unit": {
          "label": "metres per second",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "m/s"
          }
        }
      },
      "significantWeatherCode": {
        "type": "Parameter",
        "description": "Significant Weather Code",
        "unit": {
          "label": "dimensionless",
          "symbol": {
            "value": "https://datahub.metoffice.gov.uk/",
            "type": "1"
          }
        }
      },
      "minScreenAirTemp": {
        "type": "Parameter",
        "description": "Minimum Screen Air Temperature Over Previous Hour",
        "unit": {
          "label": "degrees Celsius",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "Cel"
          }
        }
      },
      "totalPrecipAmount": {
        "type": "Parameter",
        "description": "Total Precipitation Amount Over Previous Hour",
        "unit": {
          "label": "millimetres",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "mm"
          }
        }
      },
      "mslp": {
        "type": "Parameter",
        "description": "Mean Sea Level Pressure",
        "unit": {
          "label": "pascals",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "Pa"
          }
        }
      },
      "windGustSpeed10m": {
        "type": "Parameter",
        "description": "10m Wind Gust Speed",
        "unit": {
          "label": "metres per second",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "m/s"
          }
        }
      },
      "uvIndex": {
        "type": "Parameter",
        "description": "UV Index",
        "unit": {
          "label": "dimensionless",
          "symbol": {
            "value": "http://www.opengis.net/def/uom/UCUM/",
            "type": "1"
          }
        }
      }
    }
  ]
}""";
