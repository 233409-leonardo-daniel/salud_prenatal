import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/medical_record_response.dart';

/// Banner de predicción de riesgo (IA) mostrado en el dashboard de la
/// paciente, con color/ícono según el nivel de riesgo detectado.
class RiskPredictionBanner extends StatelessWidget {
  final RiskPrediction prediction;

  const RiskPredictionBanner({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final clusterName = prediction.diagnosis ?? 'Riesgo indeterminado';
    final lower = clusterName.toLowerCase();
    final isHigh = lower.contains('alto') || lower.contains('crítico') || lower.contains('critico');
    final isMedium = lower.contains('medio') || lower.contains('moderado');

    final Color bgColor = isHigh
        ? AppColors.riskHighBg
        : (isMedium ? AppColors.riskMediumBg : AppColors.riskLowBg);
    final Color textColor = isHigh
        ? AppColors.riskHighText
        : (isMedium ? AppColors.riskMediumText : AppColors.riskLowText);
    final Color iconColor = isHigh
        ? Colors.red
        : (isMedium ? Colors.orange : Colors.teal);
    final IconData icon = isHigh
        ? Icons.warning_amber_rounded
        : (isMedium ? Icons.info_outline : Icons.check_circle_outline);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Predicción de Riesgo IA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    if (prediction.riskCluster != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'C${prediction.riskCluster}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  clusterName,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
