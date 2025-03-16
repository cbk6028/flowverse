import 'package:flutter/material.dart';


class AppTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: lightColorScheme,
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: darkColorScheme,
  );
}

/// Light [ColorScheme] made with FlexColorScheme v8.1.1.
/// Requires Flutter 3.22.0 or later.
const ColorScheme lightColorScheme = ColorScheme(
  // 设置亮度为明亮
  brightness: Brightness.light,
  // 主要颜色，用于主要按钮和控件
  primary: Color(0xFF6750A4),
  // 主要颜色上面的文本颜色
  onPrimary: Color(0xFFFFFFFF),
  // 主要颜色容器的背景颜色
  primaryContainer: Color(0xFFEADDFF),
  // 主要颜色容器上面的文本颜色
  onPrimaryContainer: Color(0xFF000000),
  // 固定主要颜色，用于主要按钮和控件的固定背景
  primaryFixed: Color(0xFFDDD8EC),
  // 固定主要颜色的变暗版本，用于主要按钮和控件的固定背景的变暗版本
  primaryFixedDim: Color(0xFFBCB2D9),
  // 固定主要颜色上面的文本颜色
  onPrimaryFixed: Color(0xFF2B2245),
  // 固定主要颜色上面的文本颜色变体，用于提供更多的文本颜色选择
  onPrimaryFixedVariant: Color(0xFF332851),
  // 次要颜色，用于次要按钮和控件
  secondary: Color(0xFF625B71),
  // 次要颜色上面的文本颜色
  onSecondary: Color(0xFFFFFFFF),
  // 次要颜色容器的背景颜色
  secondaryContainer: Color(0xFFE8DEF8),
  // 次要颜色容器上面的文本颜色
  onSecondaryContainer: Color(0xFF000000),
  // 固定次要颜色，用于次要按钮和控件的固定背景
  secondaryFixed: Color(0xFFDCDBE1),
  // 固定次要颜色的变暗版本，用于次要按钮和控件的固定背景的变暗版本
  secondaryFixedDim: Color(0xFFBDBAC4),
  // 固定次要颜色上面的文本颜色
  onSecondaryFixed: Color(0xFF242229),
  // 固定次要颜色上面的文本颜色变体，用于提供更多的文本颜色选择
  onSecondaryFixedVariant: Color(0xFF2D2933),
  // 第三颜色，用于第三级按钮和控件
  tertiary: Color(0xFF7D5260),
  // 第三颜色上面的文本颜色
  onTertiary: Color(0xFFFFFFFF),
  // 第三颜色容器的背景颜色
  tertiaryContainer: Color(0xFFFFD8E4),
  // 第三颜色容器上面的文本颜色
  onTertiaryContainer: Color(0xFF000000),
  // 固定第三颜色，用于第三级按钮和控件的固定背景
  tertiaryFixed: Color(0xFFE5D8DC),
  // 固定第三颜色的变暗版本，用于第三级按钮和控件的固定背景的变暗版本
  tertiaryFixedDim: Color(0xFFC9B4BC),
  // 固定第三颜色上面的文本颜色
  onTertiaryFixed: Color(0xFF2E1F24),
  // 固定第三颜色上面的文本颜色变体，用于提供更多的文本颜色选择
  onTertiaryFixedVariant: Color(0xFF39262C),
  // 错误颜色，用于错误信息和警告
  error: Color(0xFFBA1A1A),
  // 错误颜色上面的文本颜色
  onError: Color(0xFFFFFFFF),
  // 错误颜色容器的背景颜色
  errorContainer: Color(0xFFFFDAD6),
  // 错误颜色容器上面的文本颜色
  onErrorContainer: Color(0xFF000000),
  // 表面颜色，用于背景和卡片
  surface: Color(0xFFFCFCFC),
  // 表面颜色上面的文本颜色
  onSurface: Color(0xFF111111),
  // 表面颜色变暗版本，用于背景和卡片的变暗版本
  surfaceDim: Color(0xFFE0E0E0),
  // 表面颜色变亮版本，用于背景和卡片的变亮版本
  surfaceBright: Color(0xFFFDFDFD),
  // 表面颜色容器最低版本，用于背景和卡片的最低版本
  surfaceContainerLowest: Color(0xFFFFFFFF),
  // 表面颜色容器低版本，用于背景和卡片的低版本
  surfaceContainerLow: Color(0xFFF8F8F8),
  // 表面颜色容器，用于背景和卡片
  surfaceContainer: Color(0xFFF3F3F3),
  // 表面颜色容器高版本，用于背景和卡片的高版本
  surfaceContainerHigh: Color(0xFFEDEDED),
  // 表面颜色容器最高版本，用于背景和卡片的最高版本
  surfaceContainerHighest: Color(0xFFE7E7E7),
  // 表面颜色变体，用于提供更多的表面颜色选择
  onSurfaceVariant: Color(0xFF393939),
  // 轮廓颜色，用于控件的轮廓
  outline: Color(0xFF919191),
  // 轮廓颜色变体，用于提供更多的轮廓颜色选择
  outlineVariant: Color(0xFFD1D1D1),
  // 阴影颜色，用于控件的阴影
  shadow: Color(0xFF000000),
  // 遮罩颜色，用于控件的遮罩
  scrim: Color(0xFF000000),
  // 反转表面颜色，用于反转表面的背景和卡片
  inverseSurface: Color(0xFF2A2A2A),
  // 反转表面颜色上面的文本颜色
  onInverseSurface: Color(0xFFF1F1F1),
  // 反转主要颜色，用于反转主要按钮和控件的背景
  inversePrimary: Color(0xFFF0E9FF),
  // 表面色调，用于调整表面的颜色
  surfaceTint: Color(0xFF6750A4),
);

/// Dark [ColorScheme] made with FlexColorScheme v8.1.1.
/// Requires Flutter 3.22.0 or later.
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFD0BCFF),
  onPrimary: Color(0xFF000000),
  primaryContainer: Color(0xFF4F378B),
  onPrimaryContainer: Color(0xFFFFFFFF),
  primaryFixed: Color(0xFFDDD8EC),
  primaryFixedDim: Color(0xFFBCB2D9),
  onPrimaryFixed: Color(0xFF2B2245),
  onPrimaryFixedVariant: Color(0xFF332851),
  secondary: Color(0xFFCCC2DC),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFF4A4458),
  onSecondaryContainer: Color(0xFFFFFFFF),
  secondaryFixed: Color(0xFFDCDBE1),
  secondaryFixedDim: Color(0xFFBDBAC4),
  onSecondaryFixed: Color(0xFF242229),
  onSecondaryFixedVariant: Color(0xFF2D2933),
  tertiary: Color(0xFFEFB8C8),
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF633B48),
  onTertiaryContainer: Color(0xFFFFFFFF),
  tertiaryFixed: Color(0xFFE5D8DC),
  tertiaryFixedDim: Color(0xFFC9B4BC),
  onTertiaryFixed: Color(0xFF2E1F24),
  onTertiaryFixedVariant: Color(0xFF39262C),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF000000),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFFFFF),
  surface: Color(0xFF080808),
  onSurface: Color(0xFFF1F1F1),
  surfaceDim: Color(0xFF060606),
  surfaceBright: Color(0xFF2C2C2C),
  surfaceContainerLowest: Color(0xFF010101),
  surfaceContainerLow: Color(0xFF0E0E0E),
  surfaceContainer: Color(0xFF151515),
  surfaceContainerHigh: Color(0xFF1D1D1D),
  surfaceContainerHighest: Color(0xFF282828),
  onSurfaceVariant: Color(0xFFCACACA),
  outline: Color(0xFF777777),
  outlineVariant: Color(0xFF414141),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE8E8E8),
  onInverseSurface: Color(0xFF2A2A2A),
  inversePrimary: Color(0xFF5D556B),
  surfaceTint: Color(0xFFD0BCFF),
);
