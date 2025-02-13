// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'units.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data<TUnit> _$DataFromJson<TUnit extends Unit<TUnit>>(
        Map<String, dynamic> json) =>
    Data<TUnit>(
      (json['value'] as num).toDouble(),
      UnitConverter<TUnit>().fromJson(json['unit']),
    );

Map<String, dynamic> _$DataToJson<TUnit extends Unit<TUnit>>(
        Data<TUnit> instance) =>
    <String, dynamic>{
      'value': instance._value,
      'unit': UnitConverter<TUnit>().toJson(instance._unit),
    };

Coordinate _$CoordinateFromJson(Map<String, dynamic> json) => Coordinate(
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      elevation: (json['elevation'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CoordinateToJson(Coordinate instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'long': instance.long,
      'elevation': instance.elevation,
    };

const _$TempEnumMap = {
  Temp.farenheit: 'farenheit',
  Temp.celsius: 'celsius',
  Temp.kelvin: 'kelvin',
};

const _$SpeedEnumMap = {
  Speed.kmPerH: 'kmPerH',
  Speed.mPerS: 'mPerS',
  Speed.milesPerHour: 'milesPerHour',
};

const _$PercentEnumMap = {
  Percent.outOf1: 'outOf1',
  Percent.outOf100: 'outOf100',
};

const _$PressureEnumMap = {
  Pressure.millibars: 'millibars',
  Pressure.hectopascals: 'hectopascals',
};

const _$SolarRadiationEnumMap = {
  SolarRadiation.wPerM2: 'wPerM2',
};

const _$LengthEnumMap = {
  Length.m: 'm',
  Length.cm: 'cm',
  Length.mm: 'mm',
  Length.inch: 'inch',
};
