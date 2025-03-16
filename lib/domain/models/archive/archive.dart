import 'package:flov/config/type.dart';
import 'package:flov/domain/models/tool/stroke.dart';

class Archive {
  final int version = 0;
  final DateTime dateCreated;
  final DateTime? dateModified;
  // 
  Map<PageNumber, List<Marker>> markers = {};
  Map<PageNumber, List<Stroke>> strokes = {};

  Archive({
    required this.dateCreated,
    this.dateModified,
    Map<int, List<Marker>>? initialMarkers,
    Map<int, List<Stroke>>? initialStrokes,
  }) {
    if (initialMarkers != null) markers = initialMarkers;
    if (initialStrokes != null) strokes = initialStrokes;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified?.toIso8601String(),
      'markers': markers.map((pageNumber, markers) => MapEntry(
          pageNumber.toString(), markers.map((m) => m.toJson()).toList())),
      'strokes': strokes.map((pageNumber, strokes) => MapEntry(
          pageNumber.toString(), strokes.map((s) => s.toJson()).toList())),
    };
  }

  factory Archive.fromJson(Map<String, dynamic> json) {
    var archive = Archive(
      dateCreated: DateTime.parse(json['dateCreated']),
      dateModified: json['dateModified'] != null
          ? DateTime.parse(json['dateModified'])
          : null,
    );

    var markersJson = json['markers'] as Map<String, dynamic>;
    markersJson.forEach((pageStr, markersJson) {
      var pageNumber = int.parse(pageStr);
      var markers = (markersJson as List)
          .map((m) => Marker.fromJson(m as Map<String, dynamic>))
          .toList();
      archive.markers[pageNumber] = markers;
    });

    if (json.containsKey('strokes')) {
      var strokesJson = json['strokes'] as Map<String, dynamic>;
      strokesJson.forEach((pageStr, strokesJson) {
        var pageNumber = int.parse(pageStr);
        var strokes = (strokesJson as List)
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList();
        archive.strokes[pageNumber] = strokes;
      });
    }

    return archive;
  }
}
