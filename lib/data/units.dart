import 'package:equatable/equatable.dart';
import 'dart:math' as math;

abstract interface class Convert<T> {
  double convertDataTo(double data, T to);
}

enum Temp implements Convert<Temp> {
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
}

enum Speed implements Convert<Speed> {
  kmPerH,
  mPerS;

  @override
  double convertDataTo(double data, Speed to) {
    switch ((this, to)) {
      case (Speed.kmPerH, Speed.kmPerH):
      case (Speed.mPerS, Speed.mPerS):
        return data;

      case (Speed.kmPerH, Speed.mPerS):
        return data * 3.6;
      case (Speed.mPerS, Speed.kmPerH):
        return data / 3.6;
    }
  }
}

enum Percent implements Convert<Percent> {
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
}

enum Pressure implements Convert<Pressure> {
  millibars,
  hectopascals;

  @override
  double convertDataTo(double data, Pressure to) {
    // millibars = hectopascals
    return data;
  }
}

enum SolarRadiation implements Convert<SolarRadiation> {
  wPerM2;

  @override
  double convertDataTo(double data, SolarRadiation to) {
    assert(to == SolarRadiation.wPerM2);
    return data;
  }
}

enum Length implements Convert<Length> {
  m,
  cm,
  mm;
  // inch;

  @override
  double convertDataTo(double data, Length to) {
    switch ((this, to)) {
      case (Length.m, Length.m):
      case (Length.cm, Length.cm):
      case (Length.mm, Length.mm):
        return data;

      case (Length.m, Length.cm):
        return data / 100;
      case (Length.m, Length.mm):
        return data / 1000;

      case (Length.cm, Length.m):
        return data * 100;
      case (Length.cm, Length.mm):
        return data / 10;

      case (Length.mm, Length.m):
        return data * 1000;
      case (Length.mm, Length.cm):
        return data * 10;
    }
  }
}

typedef Rainfall = Length;

class Data<TUnit extends Convert<TUnit>> extends Equatable {
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
class DataSeries<TUnit extends Convert<TUnit>> {
  const DataSeries(this._values, this._unit);

  final List<double> _values;
  final TUnit _unit;

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
  DataSeries<TUnit> toDataSeries<TUnit extends Convert<TUnit>>(TUnit unit) {
    return DataSeries(
      toList(),
      unit,
    );
  }
}

extension ConvertToDataSeries<TUnit extends Convert<TUnit>> on Iterable<Data<TUnit>> {
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
  List<Object?> get props => [lat, long, elevation];
}
