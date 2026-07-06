/// Video factory — Web (Flutter 3.44+ uses dart:ui_web)
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void ensureVideoFactory() {
  try {
    ui_web.platformViewRegistry.registerViewFactory(
      'pawmart-video-player',
      (int viewId) => html.VideoElement()
        ..controls = true
        ..autoplay = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#000'
        ..style.outline = 'none',
    );
  } catch (_) {}
}

void ensureVideoFactoryRegistered() {
  try {
    ui_web.platformViewRegistry.registerViewFactory(
      'pawmart-video-player',
      (int viewId) {
        final el = html.VideoElement()
          ..controls = true
          ..autoplay = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#000'
          ..style.outline = 'none';
        return el;
      },
    );
  } catch (_) {}
}
