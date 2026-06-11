import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../../../core/storage/secure_session_storage.dart';

final appSettingsControllerProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>(
      (ref) => AppSettingsController(ref.watch(secureSessionStorageProvider)),
    );

class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'en',
    this.notificationsEnabled = true,
    this.isLoaded = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: _themeModeFromName(json['themeMode'] as String?),
      languageCode: json['languageCode'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      isLoaded: true,
    );
  }

  final ThemeMode themeMode;
  final String languageCode;
  final bool notificationsEnabled;
  final bool isLoaded;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? notificationsEnabled,
    bool? isLoaded,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'languageCode': languageCode,
    'notificationsEnabled': notificationsEnabled,
  };

  @override
  List<Object?> get props => [
    themeMode,
    languageCode,
    notificationsEnabled,
    isLoaded,
  ];

  static ThemeMode _themeModeFromName(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController(this._storage) : super(const AppSettings()) {
    _load();
  }

  final SecureSessionStorage _storage;

  Future<void> setThemeMode(ThemeMode value) {
    state = state.copyWith(themeMode: value, isLoaded: true);
    return _save();
  }

  Future<void> setLanguageCode(String value) {
    state = state.copyWith(languageCode: value, isLoaded: true);
    return _save();
  }

  Future<void> setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value, isLoaded: true);
    return _save();
  }

  Future<void> clearLocalPreferences() async {
    state = const AppSettings(isLoaded: true);
    await _save();
  }

  Future<void> _load() async {
    final json = await _storage.readAppSettingsJson();
    if (json == null || json.isEmpty) {
      state = state.copyWith(isLoaded: true);
      return;
    }
    try {
      state = AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Exception {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _save() async {
    await _storage.writeAppSettingsJson(jsonEncode(state.toJson()));
  }
}
