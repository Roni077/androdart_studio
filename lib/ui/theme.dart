import 'package:flutter/material.dart';

class AndrodartTheme {
  AndrodartTheme._();

  // Colors
  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color accentColor = Color(0xFF00E5FF);
  static const Color backgroundColor = Color(0xFF1E1E2E);
  static const Color surfaceColor = Color(0xFF282838);
  static const Color cardColor = Color(0xFF313142);
  static const Color errorColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);

  // Text colors
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF757575);

  // Syntax highlighting
  static const Color syntaxKeyword = Color(0xFFC792EA);
  static const Color syntaxString = Color(0xFFC3E88D);
  static const Color syntaxNumber = Color(0xFFF78C6C);
  static const Color syntaxComment = Color(0xFF546E7A);
  static const Color syntaxFunction = Color(0xFF82AAFF);
  static const Color syntaxClass = Color(0xFFFFCB6B);
  static const Color syntaxVariable = Color(0xFFEEFFFF);

  // Tab bar
  static const Color tabActive = primaryColor;
  static const Color tabInactive = textMuted;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: textMuted,
            fontSize: 12,
          );
        }),
      ),
      dividerColor: Colors.grey[800],
      iconTheme: const IconThemeData(color: textSecondary),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textMuted),
        labelLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
