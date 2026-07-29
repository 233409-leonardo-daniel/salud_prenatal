import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Vista de relleno para secciones del dashboard aún no implementadas.
class PlaceholderView extends StatelessWidget {
  final String description;

  const PlaceholderView({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'En Construcción',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
