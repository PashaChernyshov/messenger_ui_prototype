import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_design/features/settings/domain/message_display_settings.dart';

abstract interface class UiSettingsRepository {
  Future<double> loadFontSize();
  Future<void> saveFontSize(double value);
  Future<MessageDisplaySettings> loadMessageDisplaySettings();
  Future<void> saveMessageDisplaySettings(MessageDisplaySettings value);
  Future<String?> loadSelectedMicrophoneId();
  Future<void> saveSelectedMicrophoneId(String? value);
  Future<Set<String>> loadFavoriteReactions();
  Future<void> saveFavoriteReactions(Set<String> value);
}

class SharedPrefsUiSettingsRepository implements UiSettingsRepository {
  static const defaultFavoriteReactions = {'👍', '❤️', '✅', '🔥', '👏'};

  static const _fontSizeKey = 'ui_font_size_v1';
  static const _messageFontSizeKey = 'message_font_size_v1';
  static const _chatDensityKey = 'chat_density_v1';
  static const _showMessageTimeKey = 'show_message_time_v1';
  static const _showTechnicalIdsKey = 'show_technical_ids_v1';
  static const _selectedMicrophoneIdKey = 'selected_microphone_id_v1';
  static const _favoriteReactionsKey = 'favorite_reactions_v1';

  @override
  Future<double> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 14;
  }

  @override
  Future<void> saveFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }

  @override
  Future<MessageDisplaySettings> loadMessageDisplaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final densityName = prefs.getString(_chatDensityKey);
    return MessageDisplaySettings(
      messageFontSize: prefs.getDouble(_messageFontSizeKey) ??
          MessageDisplaySettings.defaults.messageFontSize,
      density: ChatDensity.values.firstWhere(
        (density) => density.name == densityName,
        orElse: () => MessageDisplaySettings.defaults.density,
      ),
      showMessageTime: prefs.getBool(_showMessageTimeKey) ??
          MessageDisplaySettings.defaults.showMessageTime,
      showTechnicalIds: prefs.getBool(_showTechnicalIdsKey) ??
          MessageDisplaySettings.defaults.showTechnicalIds,
    );
  }

  @override
  Future<void> saveMessageDisplaySettings(MessageDisplaySettings value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_messageFontSizeKey, value.messageFontSize);
    await prefs.setString(_chatDensityKey, value.density.name);
    await prefs.setBool(_showMessageTimeKey, value.showMessageTime);
    await prefs.setBool(_showTechnicalIdsKey, value.showTechnicalIds);
  }

  @override
  Future<String?> loadSelectedMicrophoneId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedMicrophoneIdKey);
  }

  @override
  Future<void> saveSelectedMicrophoneId(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_selectedMicrophoneIdKey);
      return;
    }
    await prefs.setString(_selectedMicrophoneIdKey, value);
  }

  @override
  Future<Set<String>> loadFavoriteReactions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_favoriteReactionsKey);
    if (saved == null || saved.isEmpty) return defaultFavoriteReactions;
    return saved.where((item) => item.trim().isNotEmpty).toSet();
  }

  @override
  Future<void> saveFavoriteReactions(Set<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteReactionsKey, value.toList());
  }
}

