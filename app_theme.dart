/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';

/// Centraliza as definições de tema para o aplicativo, garantindo uma
/// identidade visual consistente.
class AppTheme {
  // Define a cor primária que será a base para a paleta de cores.
  static const Color _primaryColor = Color(
    0xFF0D47A1,
  ); // Um azul escuro e profissional

  /// Tema claro padrão para o aplicativo.
  static final ThemeData lightTheme = ThemeData(
    // Habilita o uso do Material 3 para um visual mais moderno.
    useMaterial3: true,

    // Gera uma paleta de cores completa a partir da cor primária.
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),

    // Estilo padrão para todas as AppBars.
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white, // Cor do título e dos ícones
    ),

    // Estilo padrão para todos os ElevatedButtons.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white, // Cor do texto e dos ícones
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // Estilo padrão para todos os campos de texto (TextFormField).
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
    ),
  );
}
