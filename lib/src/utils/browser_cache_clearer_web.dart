import 'dart:html' as html;

Future<void> clearBrowserCache() async {
  html.window.localStorage.clear();
  html.window.sessionStorage.clear();

  try {
    final cacheStorage = html.window.caches;
    if (cacheStorage != null) {
      final keys = await cacheStorage.keys();
      for (final key in keys) {
        await cacheStorage.delete(key);
      }
    }
  } catch (_) {}

  try {
    final registrations =
        await html.window.navigator.serviceWorker?.getRegistrations() ?? [];
    for (final registration in registrations) {
      await registration.unregister();
    }
  } catch (_) {}

  try {
    await _clearIndexedDatabases();
  } catch (_) {}

  html.window.location.reload();
}

Future<void> _clearIndexedDatabases() async {
  final indexedDb = html.window.indexedDB;
  if (indexedDb == null) {
    return;
  }

  const knownNames = <String>[
    'firebaseLocalStorageDb',
    'firebase-heartbeat-database',
    'firebase-installations-database',
  ];

  for (final name in knownNames) {
    try {
      await indexedDb.deleteDatabase(name);
    } catch (_) {}
  }
}

bool get isBrowserCacheClearSupported => true;
