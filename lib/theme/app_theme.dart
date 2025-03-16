import 'package:flutter/material.dart';

class AppTheme {
  // 颜色常量
  static const Color mainColor = Color(0xFFFFFFFF);
  static const Color mainColorLight = Color(0xFFF8F8F8);
  static const Color mainColorShadow = Color(0xCCFFFFFF);
  static const Color mainColorDisabled = Color(0xFFF0F0F0);

  static const Color auxiliaryColor1 = Color(0xFF333333);
  static const Color auxiliaryColor1Light = Color(0xFF666666);
  static const Color auxiliaryColor1Dark = Color(0xFF1A1A1A);
  static const Color auxiliaryColor1Transparent = Color(0x80333333);
  static const Color auxiliaryColor1Shadow = Color(0x1A333333);

  static const Color auxiliaryColor2 = Color(0xFFE0E0E0);
  static const Color auxiliaryColor2Dark = Color(0xFFCCCCCC);
  static const Color auxiliaryColor2Light = Color(0xFFF5F5F5);
  static const Color auxiliaryColor2Transparent = Color(0x80E0E0E0);

  static const Color emphasizeColor = Color(0xFF003366);
  static const Color emphasizeColorLight = Color(0xFF004080);
  static const Color emphasizeColorDark = Color(0xFF002244);
  static const Color emphasizeColorTransparent = Color(0x33003366);
  static const Color emphasizeColorDisabled = Color(0xFF6688AA);

  static const Color errorColor = Color(0xFFD32F2F);
  static const Color errorColorTransparent = Color(0x33D32F2F);
  static const Color successColor = Color(0xFF28A745);
  static const Color successColorTransparent = Color(0x3328A745);
  static const Color warningColor = Color(0xFFF0AD4E);
  static const Color warningColorTransparent = Color(0x33F0AD4E);

  // 文本主题
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: auxiliaryColor1Dark,
    ),
    displayMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: auxiliaryColor1Dark,
    ),
    displaySmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: auxiliaryColor1Dark,
    ),
    headlineMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: auxiliaryColor1Dark,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      color: auxiliaryColor1,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: auxiliaryColor1,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: auxiliaryColor1Light,
    ),
  );

  // 按钮主题
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.disabled)) {
        return emphasizeColorDisabled;
      }
      if (states.contains(MaterialState.pressed)) {
        return emphasizeColorDark;
      }
      return emphasizeColor;
    }),
    foregroundColor: MaterialStateProperty.all(mainColor),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevation: MaterialStateProperty.resolveWith<double>((states) {
      if (states.contains(MaterialState.pressed)) {
        return 0;
      }
      return 1;
    }),
  );

  static ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.pressed)) {
        return auxiliaryColor2Dark;
      }
      return mainColor;
    }),
    foregroundColor: MaterialStateProperty.all(emphasizeColor),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: emphasizeColor),
      ),
    ),
    elevation: MaterialStateProperty.resolveWith<double>((states) {
      if (states.contains(MaterialState.pressed)) {
        return 0;
      }
      return 0;
    }),
  );

  // 输入框装饰
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: mainColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: auxiliaryColor2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: auxiliaryColor2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: emphasizeColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: errorColor),
    ),
    hintStyle: const TextStyle(color: auxiliaryColor1Transparent),
  );

  // 卡片主题
  static CardTheme cardTheme = CardTheme(
    color: mainColor,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: auxiliaryColor2),
    ),
    margin: const EdgeInsets.all(8),
  );

  // 标签页主题
  static TabBarTheme tabBarTheme = const TabBarTheme(
    labelColor: emphasizeColor,
    unselectedLabelColor: auxiliaryColor1Light,
    indicatorSize: TabBarIndicatorSize.tab,
    labelStyle: TextStyle(fontWeight: FontWeight.bold),
  );

  // 应用栏主题
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: mainColor,
    foregroundColor: auxiliaryColor1Dark,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: auxiliaryColor1Dark,
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    iconTheme: IconThemeData(color: auxiliaryColor1),
  );

  // 浮动按钮主题
  static FloatingActionButtonThemeData floatingActionButtonTheme = 
      FloatingActionButtonThemeData(
    backgroundColor: emphasizeColor,
    foregroundColor: mainColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // 滑块主题
  static SliderThemeData sliderTheme = SliderThemeData(
    activeTrackColor: emphasizeColor,
    inactiveTrackColor: auxiliaryColor2,
    thumbColor: emphasizeColor,
    overlayColor: emphasizeColorTransparent,
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
  );

  // 复选框主题
  static CheckboxThemeData checkboxTheme = CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return emphasizeColor;
      }
      return mainColor;
    }),
    checkColor: MaterialStateProperty.all(mainColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
    ),
    side: const BorderSide(color: auxiliaryColor2Dark),
  );

  // 主题数据
  static ThemeData lightTheme = ThemeData(
    primaryColor: emphasizeColor,
    scaffoldBackgroundColor: mainColorLight,
    colorScheme: const ColorScheme.light(
      primary: emphasizeColor,
      secondary: emphasizeColorLight,
      error: errorColor,
      background: mainColorLight,
      surface: mainColor,
    ),
    textTheme: textTheme,
    buttonTheme: ButtonThemeData(
      buttonColor: emphasizeColor,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: secondaryButtonStyle,
    ),
    inputDecorationTheme: inputDecorationTheme,
    cardTheme: cardTheme,
    tabBarTheme: tabBarTheme,
    appBarTheme: appBarTheme,
    floatingActionButtonTheme: floatingActionButtonTheme,
    sliderTheme: sliderTheme,
    checkboxTheme: checkboxTheme,
    dividerTheme: const DividerThemeData(
      color: auxiliaryColor2,
      thickness: 1,
      space: 1,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: mainColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: mainColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    fontFamily: 'Source Han Sans',
  );
} 