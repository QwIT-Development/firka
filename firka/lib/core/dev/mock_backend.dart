import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";

class MockBackend {
  static String rewrite(String url) {
    if (!Settings.mockBackendEnabled.value) return url;

    final mockBase = Settings.mockBackendUrl.value;
    if (mockBase.isEmpty) return url;

    final mockUri = Uri.parse(mockBase);
    final uri = Uri.parse(url);

    return uri
        .replace(
          scheme: mockUri.scheme,
          host: mockUri.host,
          port: mockUri.hasPort ? mockUri.port : null,
        )
        .toString();
  }
}
