import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors_ext.dart';

/// Ítem del nav inferior de la paciente que dispara una acción (p. ej. abrir
/// la Bitácora en otra ruta) en vez de cambiar de pestaña. Mismo layout y
/// estilo "no seleccionado" que los tabs normales.
class PatientNavAction extends StatelessWidget {
  final IconData outlineIcon;
  final String label;
  final VoidCallback onTap;

  const PatientNavAction({
    super.key,
    required this.outlineIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExt>()!;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(outlineIcon, color: colors.textMuted, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
