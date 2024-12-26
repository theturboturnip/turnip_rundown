import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';

part 'units.g.dart';

abstract interface class Unit<T> {
  double convertDataTo(double data, T to);
  String get display;
  Map<T, String> get toJson;
  List<T> get enumValues;
}

@JsonEnum(alwaysCreate: true)
enum Temp implements Unit<Temp> {
  farenheit,
  celsius,
  kelvin;

  @override
  double convertDataTo(double data, Temp to) {
    switch ((this, to)) {
      case (Temp.farenheit, Temp.farenheit):
      case (Temp.celsius, Temp.celsius):
      case (Temp.kelvin, Temp.kelvin):
        return data;

      case (Temp.kelvin, Temp.celsius):
        return (data - 273.15);
      case (Temp.kelvin, Temp.farenheit):
        return (data - 273.15) * 1.8 + 32;
      case (Temp.celsius, Temp.kelvin):
        return (data + 273.15);
      case (Temp.celsius, Temp.farenheit):
        return data * 1.8 + 32;
      case (Temp.farenheit, Temp.celsius):
        return ((data - 32) * 5 / 9);
      case (Temp.farenheit, Temp.kelvin):
        return ((data - 32) * 5 / 9) + 273.15;
    }
  }

  @override
  String get display => switch (this) {
        Temp.farenheit => "°F",
        Temp.celsius => "°C",
        Temp.kelvin => "°K",
      };

  @override
  Map<Temp, String> get toJson => _$TempEnumMap;

  @override
  List<Temp> get enumValues => values;
}

@JsonEnum(alwaysCreate: true)
enum Speed implements Unit<Speed> {
  kmPerH,
  mPerS,
  milesPerHour;

  @override
  double convertDataTo(double data, Speed to) {
    switch ((this, to)) {
      case (Speed.kmPerH, Speed.kmPerH):
      case (Speed.mPerS, Speed.mPerS):
      case (Speed.milesPerHour, Speed.milesPerHour):
        return data;

      case (Speed.kmPerH, Speed.mPerS):
        return data / 3.6;
      case (Speed.mPerS, Speed.kmPerH):
        return data * 3.6;

      case (Speed.milesPerHour, Speed.kmPerH):
        return data * 1.609;
      case (Speed.kmPerH, Speed.milesPerHour):
        return data / 1.609;

      case (Speed.milesPerHour, Speed.mPerS):
        return data / 2.237;
      case (Speed.mPerS, Speed.milesPerHour):
        return data * 2.237; // i.e. 3.6 / 1.609
    }
  }

  @override
  String get display => switch (this) {
        Speed.kmPerH => "kmph",
        Speed.mPerS => "m/s",
        Speed.milesPerHour => "mph",
      };

  @override
  Map<Speed, String> get toJson => _$SpeedEnumMap;

  @override
  List<Speed> get enumValues => values;
}

@JsonEnum(alwaysCreate: true)
enum Percent implements Unit<Percent> {
  outOf1,
  outOf100;

  @override
  double convertDataTo(double data, Percent to) {
    switch ((this, to)) {
      case (Percent.outOf1, Percent.outOf1):
      case (Percent.outOf100, Percent.outOf100):
        return data;
      case (Percent.outOf1, Percent.outOf100):
        return data * 100;
      case (Percent.outOf100, Percent.outOf1):
        return data / 100;
    }
  }

  @override
  String get display => switch (this) {
        Percent.outOf1 => "/1.0",
        Percent.outOf100 => "%",
      };

  @override
  Map<Percent, String> get toJson => _$PercentEnumMap;

  @override
  List<Percent> get enumValues => values;
}

@JsonEnum(alwaysCreate: true)
enum Pressure implements Unit<Pressure> {
  millibars,
  hectopascals;

  @override
  double convertDataTo(double data, Pressure to) {
    // millibars = hectopascals
    return data;
  }

  @override
  String get display => switch (this) {
        Pressure.millibars => "mbar",
        Pressure.hectopascals => "hPa",
      };

  @override
  Map<Pressure, String> get toJson => _$PressureEnumMap;

  @override
  List<Pressure> get enumValues => values;
}

@JsonEnum(alwaysCreate: true)
enum SolarRadiation implements Unit<SolarRadiation> {
  wPerM2;

  @override
  double convertDataTo(double data, SolarRadiation to) {
    assert(to == SolarRadiation.wPerM2);
    return data;
  }

  @override
  String get display => "W/m²";

  @override
  Map<SolarRadiation, String> get toJson => _$SolarRadiationEnumMap;

  @override
  List<SolarRadiation> get enumValues => values;
}

@JsonEnum(alwaysCreate: true)
enum Length implements Unit<Length> {
  m,
  cm,
  mm,
  inch;

  @override
  double convertDataTo(double data, Length to) {
    switch ((this, to)) {
      case (Length.m, Length.m):
      case (Length.cm, Length.cm):
      case (Length.mm, Length.mm):
      case (Length.inch, Length.inch):
        return data;

      case (Length.m, Length.cm):
        return data / 100;
      case (Length.m, Length.mm):
        return data / 1000;
      case (Length.m, Length.inch):
        return data * 39.3701;

      case (Length.cm, Length.m):
        return data * 100;
      case (Length.cm, Length.mm):
        return data / 10;
      case (Length.cm, Length.inch):
        return data / 2.54;

      case (Length.mm, Length.m):
        return data * 1000;
      case (Length.mm, Length.cm):
        return data * 10;
      case (Length.mm, Length.inch):
        return data / 25.4;

      case (Length.inch, Length.m):
        return data / 39.3701;
      case (Length.inch, Length.cm):
        return data * 2.54;
      case (Length.inch, Length.mm):
        return data * 0.254;
    }
  }

  @override
  String get display => switch (this) {
        Length.m => "m",
        Length.cm => "cm",
        Length.mm => "mm",
        Length.inch => "in",
      };

  @override
  Map<Length, String> get toJson => _$LengthEnumMap;

  @override
  List<Length> get enumValues => values;
}

typedef Rainfall = Length;

// Helper class for converting a generic type T-extends-Unit to and from JSON.
// Introspects on the generic type (fixed to one of a set of possible values)
// to figure out which decoder map to use.
// https://stackoverflow.com/a/71812430
class UnitConverter<T extends Unit> implements JsonConverter<T, Object?> {
  const UnitConverter();

  TA _$enumDecode<TA>(
    Map<TA, dynamic> enumValues,
    dynamic source, {
    TA? unknownValue,
  }) {
    if (source == null) {
      throw ArgumentError('A value must be provided. Supported values: '
          '${enumValues.values.join(', ')}');
    }

    final value = enumValues.entries.singleWhereOrNull((e) => e.value == source)?.key;

    if (value == null && unknownValue == null) {
      throw ArgumentError('`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}');
    }
    return (value ?? unknownValue)!;
  }

  @override
  T fromJson(Object? json) {
    switch (T) {
      case const (Temp):
        return _$enumDecode(_$TempEnumMap, json) as T;
      case const (Speed):
        return _$enumDecode(_$SpeedEnumMap, json) as T;
      case const (Percent):
        return _$enumDecode(_$PercentEnumMap, json) as T;
      case const (Pressure):
        return _$enumDecode(_$PressureEnumMap, json) as T;
      case const (SolarRadiation):
        return _$enumDecode(_$SolarRadiationEnumMap, json) as T;
      case const (Length):
        return _$enumDecode(_$LengthEnumMap, json) as T;
      default:
        throw UnsupportedError('Unsupported type: $T');
    }
  }

  @override
  Object? toJson(T object) => object.toJson[object];
}

@JsonSerializable()
class Data<TUnit extends Unit<TUnit>> extends Equatable {
  const Data(this._value, this._unit);

  @JsonKey(name: "value", includeFromJson: true, includeToJson: true)
  final double _value;
  @JsonKey(name: "unit", includeFromJson: true, includeToJson: true)
  @UnitConverter()
  final TUnit _unit;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson<TUnit>(json);
  Map<String, dynamic> toJson() => _$DataToJson(this);

  @override
  List<Object?> get props => [_value, _unit];

  Data<TUnit> convertedTo(TUnit newUnit) {
    return Data(_unit.convertDataTo(_value, newUnit), newUnit);
  }

  double valueAs(TUnit newUnit) {
    return _unit.convertDataTo(_value, newUnit);
  }

  TUnit get unit => _unit;
}

// 0-indexed series of data, all under one unit.
// Immutable.
class DataSeries<TUnit extends Unit<TUnit>> {
  const DataSeries(this._values, this._unit);

  final List<double> _values;
  final TUnit _unit;

  int get length => _values.length;

  Iterable<Data<TUnit>> datas() {
    return _values.map((val) => Data(val, _unit));
  }

  Iterable<double> valuesAs(TUnit newUnit) {
    return _values.map((data) => _unit.convertDataTo(data, newUnit));
  }

  DataSeries<TUnit> slice(int startIndexIncl, int endIndexIncl) {
    return DataSeries(_values.sublist(startIndexIncl, endIndexIncl + 1), _unit);
  }

  operator [](int i) => Data(_values[i], _unit);
}

extension ToDataSeries on Iterable<double> {
  DataSeries<TUnit> toDataSeries<TUnit extends Unit<TUnit>>(TUnit unit) {
    return DataSeries(
      toList(),
      unit,
    );
  }
}

extension ConvertToDataSeries<TUnit extends Unit<TUnit>> on Iterable<Data<TUnit>> {
  DataSeries<TUnit> toDataSeries(TUnit baseUnit) {
    return DataSeries(
      map((data) => data.valueAs(baseUnit)).toList(),
      baseUnit,
    );
  }
}

extension RoundTo on double {
  double roundTo(int places) {
    final factor = math.pow(10, places);
    return (this * factor).roundToDouble() / factor;
  }
}

class Coordinate extends Equatable {
  const Coordinate({required this.lat, required this.long, this.elevation});

  final double lat;
  final double long;
  final double? elevation;

  Coordinate roundedTo(int latLongDp, {required int elevationDp}) {
    return Coordinate(
      lat: lat.roundTo(latLongDp),
      long: long.roundTo(latLongDp),
      elevation: elevation?.roundTo(elevationDp),
    );
  }

  @override
  String toString() {
    if (elevation != null) {
      return "$lat, $long, ${elevation}m";
    }
    return "$lat, $long";
  }

  @override
  List<Object?> get props => [lat, long, elevation];
}

extension MinMax on Iterable<num> {
  /// The minimal and maximal elements of the iterable.
  ///
  /// If any element is [NaN](double.nan), the result is NaN.#
  ///
  /// If the iterable is empty, returns null.
  (num, num)? get minMaxOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var min = iterator.current;
      var max = iterator.current;
      if (min.isNaN) {
        return (min, min);
      }

      while (iterator.moveNext()) {
        var newMin = iterator.current;
        var newMax = iterator.current;
        if (newMin.isNaN) {
          return (newMin, newMin);
        }
        if (newMin < min) {
          min = newMin;
        }
        if (newMax > max) {
          max = newMax;
        }
      }
      return (min, max);
    }
    return null;
  }

  /// The minimal and maximal elements of the iterable.
  ///
  /// If any element is [NaN](double.nan), the result is NaN.
  ///
  /// The iterable must not be empty.
  (num, num) get minMax => minMaxOrNull ?? (throw StateError('No element'));
}
