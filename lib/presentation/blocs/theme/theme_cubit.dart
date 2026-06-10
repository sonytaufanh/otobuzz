import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/theme_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final ThemeService _themeService;

  ThemeCubit(this._themeService) : super(ThemeMode.system);

  Future<void> loadTheme() async {
    final mode = await _themeService.getThemeMode();
    emit(mode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _themeService.setThemeMode(mode);
    emit(mode);
  }
}
