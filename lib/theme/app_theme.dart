import 'package:flutter/material.dart';

class AppTheme {
  // -------------------------
  //       LIGHT THEME
  // -------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white, // White background for the app
      
      colorScheme: const ColorScheme.light(
        primary: Colors.blue, // Change this to your app's main brand color
        surface: Colors.white,
        onSurface: Colors.black, // Default text/icon color on backgrounds
      ),
      
      // Default text styling
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),

      // AppBar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Makes the back button and title black
        elevation: 0, // Removes the shadow
      ),

      // Default Button styling (Example for ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Button background color
          foregroundColor: Colors.white, // Button text color
        ),
      ),
    );
  }

  // -------------------------
  //       DARK THEME
  // -------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black, // Black background for the app
      
      colorScheme: const ColorScheme.dark(
        primary: Colors.blue, // Keep brand color or change it for dark mode
        surface: Colors.black,
        onSurface: Colors.white, // Default text/icon color on backgrounds
      ),
      
      // Default text styling
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),

      // AppBar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // Makes the back button and title white
        elevation: 0,
      ),

      // Default Button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, 
          foregroundColor: Colors.white, 
        ),
      ),
    );
  }
}