import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors_ext.dart';

/// Ítem de pestaña del nav inferior de la paciente. [isSelected] y [onTap] se
/// calculan en el `State` que lo usa (compara contra la pestaña actual y
/// dispara `setState`), para que este widget se mantenga sin estado propio.
class PatientTabItem extends StatelessWidget {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PatientTabItem({
    super.key,
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    required this.isSelected,
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
          Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? AppColors.primary : colors.textMuted,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : colors.textMuted,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
