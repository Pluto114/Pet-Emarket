/// Web helpers — Web platform (uses dart:html)
import 'dart:html' as html;

void openUrlInNewTab(String url) => html.window.open(url, '_blank');

dynamic getFirstVideoElement() {
  final els = html.document.getElementsByTagName('video');
  return els.isNotEmpty ? els.last : null;
}

Type get videoElementType => html.VideoElement;
