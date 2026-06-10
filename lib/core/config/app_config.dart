import 'package:equatable/equatable.dart';

class AppConfig extends Equatable {
  const AppConfig({
    required this.appName,
    required this.apiBaseUrl,
    required this.useMockApi,
  });

  factory AppConfig.fromEnvironment() {
    const rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const useMockApiOverride = bool.fromEnvironment(
      'USE_MOCK_API',
      defaultValue: true,
    );
    final apiBaseUrl = _normalizeBaseUrl(rawApiBaseUrl);
    return AppConfig(
      appName: 'Procurement Management',
      apiBaseUrl: apiBaseUrl,
      useMockApi: useMockApiOverride || apiBaseUrl.isEmpty,
    );
  }

  final String appName;
  final String apiBaseUrl;
  final bool useMockApi;

  String get effectiveBaseUrl =>
      apiBaseUrl.isEmpty ? 'https://example.invalid/api/v1' : apiBaseUrl;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final withoutConst = trimmed.startsWith('const ')
        ? trimmed.substring('const '.length).trim()
        : trimmed;
    return withoutConst.endsWith('/')
        ? withoutConst.substring(0, withoutConst.length - 1)
        : withoutConst;
  }

  @override
  List<Object?> get props => [appName, apiBaseUrl, useMockApi];
}
