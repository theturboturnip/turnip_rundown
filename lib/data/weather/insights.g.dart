// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherInsightConfigV1 _$WeatherInsightConfigV1FromJson(
  Map<String, dynamic> json,
) => WeatherInsightConfigV1(
  useEstimatedWetBulbTemp: json['useEstimatedWetBulbTemp'] as bool,
  numberOfHoursPriorRainThreshold:
      (json['numberOfHoursPriorRainThreshold'] as num).toInt(),
  priorRainThreshold: Data<Length>.fromJson(
    json['priorRainThreshold'] as Map<String, dynamic>,
  ),
  rainProbabilityThreshold: Data<Percent>.fromJson(
    json['rainProbabilityThreshold'] as Map<String, dynamic>,
  ),
  mediumRainThreshold: Data<Length>.fromJson(
    json['mediumRainThreshold'] as Map<String, dynamic>,
  ),
  heavyRainThreshold: Data<Length>.fromJson(
    json['heavyRainThreshold'] as Map<String, dynamic>,
  ),
  highHumidityThreshold: Data<Percent>.fromJson(
    json['highHumidityThreshold'] as Map<String, dynamic>,
  ),
  maxTemperatureForHighHumidityMist: Data<Temp>.fromJson(
    json['maxTemperatureForHighHumidityMist'] as Map<String, dynamic>,
  ),
  minTemperatureForHighHumiditySweat: Data<Temp>.fromJson(
    json['minTemperatureForHighHumiditySweat'] as Map<String, dynamic>,
  ),
  minimumBreezyWindspeed: Data<Speed>.fromJson(
    json['minimumBreezyWindspeed'] as Map<String, dynamic>,
  ),
  minimumWindyWindspeed: Data<Speed>.fromJson(
    json['minimumWindyWindspeed'] as Map<String, dynamic>,
  ),
  minimumGaleyWindspeed: Data<Speed>.fromJson(
    json['minimumGaleyWindspeed'] as Map<String, dynamic>,
  ),
  boilingMinTemp: json['boilingMinTemp'] == null
      ? null
      : Data<Temp>.fromJson(json['boilingMinTemp'] as Map<String, dynamic>),
  freezingMaxTemp: json['freezingMaxTemp'] == null
      ? null
      : Data<Temp>.fromJson(json['freezingMaxTemp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WeatherInsightConfigV1ToJson(
  WeatherInsightConfigV1 instance,
) => <String, dynamic>{
  'useEstimatedWetBulbTemp': instance.useEstimatedWetBulbTemp,
  'numberOfHoursPriorRainThreshold': instance.numberOfHoursPriorRainThreshold,
  'priorRainThreshold': instance.priorRainThreshold.toJson(),
  'rainProbabilityThreshold': instance.rainProbabilityThreshold.toJson(),
  'mediumRainThreshold': instance.mediumRainThreshold.toJson(),
  'heavyRainThreshold': instance.heavyRainThreshold.toJson(),
  'highHumidityThreshold': instance.highHumidityThreshold.toJson(),
  'maxTemperatureForHighHumidityMist': instance
      .maxTemperatureForHighHumidityMist
      .toJson(),
  'minTemperatureForHighHumiditySweat': instance
      .minTemperatureForHighHumiditySweat
      .toJson(),
  'minimumBreezyWindspeed': instance.minimumBreezyWindspeed.toJson(),
  'minimumWindyWindspeed': instance.minimumWindyWindspeed.toJson(),
  'minimumGaleyWindspeed': instance.minimumGaleyWindspeed.toJson(),
  'boilingMinTemp': instance.boilingMinTemp?.toJson(),
  'freezingMaxTemp': instance.freezingMaxTemp?.toJson(),
};

WeatherInsightConfigV2 _$WeatherInsightConfigV2FromJson(
  Map<String, dynamic> json,
) => WeatherInsightConfigV2(
  useEstimatedWetBulbTemp: json['useEstimatedWetBulbTemp'] as bool,
  numberOfHoursPriorRainThreshold:
      (json['numberOfHoursPriorRainThreshold'] as num).toInt(),
  priorRainThreshold: Data<Length>.fromJson(
    json['priorRainThreshold'] as Map<String, dynamic>,
  ),
  rainProbabilityThreshold: Data<Percent>.fromJson(
    json['rainProbabilityThreshold'] as Map<String, dynamic>,
  ),
  rainMinLight: Data<Length>.fromJson(
    json['rainMinLight'] as Map<String, dynamic>,
  ),
  rainMinMedium: Data<Length>.fromJson(
    json['rainMinMedium'] as Map<String, dynamic>,
  ),
  rainMinHeavy: Data<Length>.fromJson(
    json['rainMinHeavy'] as Map<String, dynamic>,
  ),
  highHumidityThreshold: Data<Percent>.fromJson(
    json['highHumidityThreshold'] as Map<String, dynamic>,
  ),
  maxTemperatureForHighHumidityMist: Data<Temp>.fromJson(
    json['maxTemperatureForHighHumidityMist'] as Map<String, dynamic>,
  ),
  minTemperatureForHighHumiditySweat: Data<Temp>.fromJson(
    json['minTemperatureForHighHumiditySweat'] as Map<String, dynamic>,
  ),
  windMinBreezy: Data<Speed>.fromJson(
    json['windMinBreezy'] as Map<String, dynamic>,
  ),
  windMinWindy: Data<Speed>.fromJson(
    json['windMinWindy'] as Map<String, dynamic>,
  ),
  windMinGaley: Data<Speed>.fromJson(
    json['windMinGaley'] as Map<String, dynamic>,
  ),
  tempMinBoiling: Data<Temp>.fromJson(
    json['tempMinBoiling'] as Map<String, dynamic>,
  ),
  tempMinHot: Data<Temp>.fromJson(json['tempMinHot'] as Map<String, dynamic>),
  tempMinWarm: Data<Temp>.fromJson(json['tempMinWarm'] as Map<String, dynamic>),
  tempMinMild: Data<Temp>.fromJson(json['tempMinMild'] as Map<String, dynamic>),
  tempMinChilly: Data<Temp>.fromJson(
    json['tempMinChilly'] as Map<String, dynamic>,
  ),
  uvMinModerate: Data<UVIndex>.fromJson(
    json['uvMinModerate'] as Map<String, dynamic>,
  ),
  uvMinHigh: Data<UVIndex>.fromJson(json['uvMinHigh'] as Map<String, dynamic>),
  uvMinVeryHigh: Data<UVIndex>.fromJson(
    json['uvMinVeryHigh'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$WeatherInsightConfigV2ToJson(
  WeatherInsightConfigV2 instance,
) => <String, dynamic>{
  'version': instance.version,
  'useEstimatedWetBulbTemp': instance.useEstimatedWetBulbTemp,
  'numberOfHoursPriorRainThreshold': instance.numberOfHoursPriorRainThreshold,
  'priorRainThreshold': instance.priorRainThreshold.toJson(),
  'rainProbabilityThreshold': instance.rainProbabilityThreshold.toJson(),
  'rainMinLight': instance.rainMinLight.toJson(),
  'rainMinMedium': instance.rainMinMedium.toJson(),
  'rainMinHeavy': instance.rainMinHeavy.toJson(),
  'highHumidityThreshold': instance.highHumidityThreshold.toJson(),
  'maxTemperatureForHighHumidityMist': instance
      .maxTemperatureForHighHumidityMist
      .toJson(),
  'minTemperatureForHighHumiditySweat': instance
      .minTemperatureForHighHumiditySweat
      .toJson(),
  'windMinBreezy': instance.windMinBreezy.toJson(),
  'windMinWindy': instance.windMinWindy.toJson(),
  'windMinGaley': instance.windMinGaley.toJson(),
  'tempMinChilly': instance.tempMinChilly.toJson(),
  'tempMinMild': instance.tempMinMild.toJson(),
  'tempMinWarm': instance.tempMinWarm.toJson(),
  'tempMinHot': instance.tempMinHot.toJson(),
  'tempMinBoiling': instance.tempMinBoiling.toJson(),
  'uvMinModerate': instance.uvMinModerate.toJson(),
  'uvMinHigh': instance.uvMinHigh.toJson(),
  'uvMinVeryHigh': instance.uvMinVeryHigh.toJson(),
};
