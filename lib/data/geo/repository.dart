import 'package:turnip_rundown/data/units.dart';

class NamedCoordinate {
  NamedCoordinate({required this.name, required this.location});

  final String name;
  final Coordinate location;
}

/// Repository for suggesting (lat, long) coordinates from a name query
abstract class GeocoderRepository {
  /// Suggest locations with a name similar to 'query',
  /// potentially prioritizing those closer to 'near',
  /// returning up to 'nSuggestions' suggestions.
  Future<List<NamedCoordinate>> suggestLocations(String query, {Coordinate? near, int nSuggestions = 5});
}
