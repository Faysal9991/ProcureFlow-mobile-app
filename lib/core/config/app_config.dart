import 'package:equatable/equatable.dart';

class AppConfig extends Equatable {
  const AppConfig({
    required this.appName,
    required this.apiBaseUrl,
    required this.useMockApi,
  });

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const useMockApiOverride = bool.fromEnvironment(
      'USE_MOCK_API',
      defaultValue: true,
    );
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
      apiBaseUrl.isEmpty ? 'https://example.invalid/api' : apiBaseUrl;

  @override
  List<Object?> get props => [appName, apiBaseUrl, useMockApi];
}
