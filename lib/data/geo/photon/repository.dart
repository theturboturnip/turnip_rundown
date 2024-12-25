import 'dart:convert';

import 'package:turnip_rundown/data/api_cache.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/units.dart';

/// Uses the free Photon API (https://photon.komoot.io/)
/// which returns GeoJson coded responses.
class PhotonGeocoderRepository extends GeocoderRepository {
  PhotonGeocoderRepository({required this.cache});

  final ApiCacheRepository cache;

  @override
  Future<List<Location>> suggestLocations(String query, {Coordinate? near, int nSuggestions = 5}) async {
    final results = await cache.makeHttpRequest(
      Uri(
        scheme: "https",
        host: "photon.komoot.io",
        path: "api",
        queryParameters: {
          "q": query,
          if (near != null) "lat": near.lat.toString(),
          if (near != null) "lon": near.long.toString(),
          "limit": nSuggestions.toString(),
          "lang": "en",
        },
      ),
      timeout: const Duration(days: 14), // something crazy. we really don't need this.
    );
    // Decode the GeoJSON manually because it uses a lot of obj["type"] == "blah" type deserializing, which I don't think JsonSerialize handles.
    final resultsJson = jsonDecode(results) as Map<String, dynamic>;
    assert(resultsJson["type"] == "FeatureCollection");
    final resultFeatures = resultsJson["features"] as List<dynamic>;
    return resultFeatures
        .map((feature) {
          final featureMap = feature as Map<String, dynamic>;
          assert(featureMap["type"] == "Feature");
          final properties = featureMap["properties"] as Map<String, dynamic>;
          if (properties["name"] is String) {
            final name = properties["name"] as String;
            final geometry = featureMap["geometry"] as Map<String, dynamic>;
            if (geometry["type"] == "Point") {
              final coords = geometry["coordinates"] as List<dynamic>;

              // Weird moment: long then lat?
              // see https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.1
              return Location(
                name: name,
                // Try to grab as many of these properties as possible, then combine them to make an approximate address
                address: ["street", "district", "city", "state", "country"].map((property) => properties[property] as String?).whereType<String>().join(", "),
                coordinate: Coordinate(
                  lat: coords[1] as double,
                  long: coords[0] as double,
                ),
              );
            }
          }
          return null;
        })
        .whereType<Location>()
        .toList();
  }
}
