/// Video factory — Web-only (dart:html + platformViewRegistry)
import 'dart:html' as html;
import 'dart:ui' as ui;

void ensureVideoFactory() {
  try {
    ui.platformViewRegistry.registerViewFactory(
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
    ui.platformViewRegistry.registerViewFactory(
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
