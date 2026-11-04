import 'package:xml/xml.dart';
import 'gpx.dart';

class GpxWriter {
  String asString(Gpx gpx, {bool pretty = false}) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('gpx', attributes: {
      'version': '1.1',
      'creator': gpx.creator,
      'xmlns': 'http://www.topografix.com/GPX/1/1',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation': 'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd',
    }, nest: () {
      for (var wpt in gpx.wpts) {
        builder.element('wpt', attributes: {'lat': wpt.lat.toString(), 'lon': wpt.lon.toString()}, nest: () {
          if (wpt.ele != null) builder.element('ele', nest: wpt.ele.toString());
          if (wpt.time != null) builder.element('time', nest: wpt.time!.toUtc().toIso8601String());
          if (wpt.name != null) builder.element('name', nest: wpt.name);
          if (wpt.desc != null) builder.element('desc', nest: wpt.desc);
          if (wpt.sym != null) builder.element('sym', nest: wpt.sym);
        });
      }

      for (var trk in gpx.trks) {
        builder.element('trk', nest: () {
          if (trk.name != null) builder.element('name', nest: trk.name);
          if (trk.desc != null) builder.element('desc', nest: trk.desc);
          for (var trkseg in trk.trksegs) {
            builder.element('trkseg', nest: () {
              for (var pt in trkseg.trkpts) {
                builder.element('trkpt', attributes: {'lat': pt.lat.toString(), 'lon': pt.lon.toString()}, nest: () {
                  if (pt.ele != null) builder.element('ele', nest: pt.ele.toString());
                  if (pt.time != null) builder.element('time', nest: pt.time!.toUtc().toIso8601String());
                });
              }
            });
          }
        });
      }
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: pretty, indent: '  ');
  }
}
