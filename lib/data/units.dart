import 'package:equatable/equatable.dart';
import 'dart:math' as math;

abstract interface class Unit<T> {
  double convertDataTo(double data, T to);
  String get display;
}

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
}

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
        return data * 3.6;
      case (Speed.mPerS, Speed.kmPerH):
        return data / 3.6;

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
}

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
}

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
}

enum SolarRadiation implements Unit<SolarRadiation> {
  wPerM2;

  @override
  double convertDataTo(double data, SolarRadiation to) {
    assert(to == SolarRadiation.wPerM2);
    return data;
  }

  @override
  String get display => "W/m²";
}

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
        return data * 3.93701;

      case (Length.mm, Length.m):
        return data * 1000;
      case (Length.mm, Length.cm):
        return data * 10;
      case (Length.mm, Length.inch):
        return data * 0.393701;

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
}

typedef Rainfall = Length;

class Data<TUnit extends Unit<TUnit>> extends Equatable {
  const Data(this._value, this._unit);

  final double _value;
  final TUnit _unit;

  @override
  List<Object?> get props => [_value, _unit];

  Data<TUnit> convertedTo(TUnit newUnit) {
    return Data(_unit.convertDataTo(_value, newUnit), newUnit);
  }

  double valueAs(TUnit newUnit) {
    return _unit.convertDataTo(_value, newUnit);
  }
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