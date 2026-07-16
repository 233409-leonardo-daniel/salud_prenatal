import 'package:flutter/material.dart';

/// Tokens de color semánticos que no tienen slot en [ColorScheme] de Material
/// (textos, superficies suaves, niveles de riesgo, skeletons).
///
/// Es el reemplazo idiomático de los getters estáticos en `AppColors`: en vez
/// de leer un `static` global mutable, el valor viaja por el `BuildContext` vía
/// `Theme.of(context).extension<AppColorsExt>()`. Eso hace que cualquier widget
/// que lo consuma dependa del tema y se reconstruya solo cuando el SO cambia
/// entre claro/oscuro — sin el bug de "página congelada" que sufre `AppColors`.
///
/// Se registra con literales fijos en `AppTheme.lightTheme`/`darkTheme`, uno por
/// variante. `primary`, `background`, `cardBackground` y `error` NO viven aquí:
/// esos salen de `ColorScheme` directamente.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  final Color primaryLight;
  final Color textDark;
  final Color textMuted;

  /// Superficie para placeholders/skeletons. Se deriva mezclando un poco de
  /// [textDark] sobre la superficie de la tarjeta, igual que
  /// `AppColors.skeletonBase`, para que siempre contraste con el fondo.
  final Color skeletonBase;

  final Color riskHighBg;
  final Color riskHighText;
  final Color riskMediumBg;
  final Color riskMediumText;
  final Color riskLowBg;
  final Color riskLowText;

  const AppColorsExt({
    required this.primaryLight,
    required this.textDark,
    required this.textMuted,
    required this.skeletonBase,
    required this.riskHighBg,
    required this.riskHighText,
    required this.riskMediumBg,
    required this.riskMediumText,
    required this.riskLowBg,
    required this.riskLowText,
  });

  @override
  AppColorsExt copyWith({
    Color? primaryLight,
    Color? textDark,
    Color? textMuted,
    Color? skeletonBase,
    Color? riskHighBg,
    Color? riskHighText,
    Color? riskMediumBg,
    Color? riskMediumText,
    Color? riskLowBg,
    Color? riskLowText,
  }) {
    return AppColorsExt(
      primaryLight: primaryLight ?? this.primaryLight,
      textDark: textDark ?? this.textDark,
      textMuted: textMuted ?? this.textMuted,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      riskHighBg: riskHighBg ?? this.riskHighBg,
      riskHighText: riskHighText ?? this.riskHighText,
      riskMediumBg: riskMediumBg ?? this.riskMediumBg,
      riskMediumText: riskMediumText ?? this.riskMediumText,
      riskLowBg: riskLowBg ?? this.riskLowBg,
      riskLowText: riskLowText ?? this.riskLowText,
    );
  }

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    return AppColorsExt(
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      riskHighBg: Color.lerp(riskHighBg, other.riskHighBg, t)!,
      riskHighText: Color.lerp(riskHighText, other.riskHighText, t)!,
      riskMediumBg: Color.lerp(riskMediumBg, other.riskMediumBg, t)!,
      riskMediumText: Color.lerp(riskMediumText, other.riskMediumText, t)!,
      riskLowBg: Color.lerp(riskLowBg, other.riskLowBg, t)!,
      riskLowText: Color.lerp(riskLowText, other.riskLowText, t)!,
    );
  }
}
