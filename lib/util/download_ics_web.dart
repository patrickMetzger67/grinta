import 'dart:convert';
import 'dart:html' as html;

void downloadIcsFile({
  required String fileName,
  required String icsContent,
}) {
  final bytes = utf8.encode(icsContent);
  final blob = html.Blob([bytes], 'text/calendar;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}
