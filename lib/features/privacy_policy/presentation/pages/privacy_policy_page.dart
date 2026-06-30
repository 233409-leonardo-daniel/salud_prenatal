import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme.dart';
import '../providers/privacy_policy_provider.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final String? userEmail;

  const PrivacyPolicyPage({super.key, this.userEmail});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _acceptedPrivacy = false;
  bool _acceptedSensitiveData = false;
  final ScrollController _scrollController = ScrollController();

  bool get _canContinue => _acceptedPrivacy && _acceptedSensitiveData;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onAcceptAndContinue() async {
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      final provider = context.read<PrivacyPolicyProvider>();
      await provider.saveAcceptedPolicies(
        userEmail: widget.userEmail!,
        acceptedPrivacy: _acceptedPrivacy,
        acceptedSensitiveData: _acceptedSensitiveData,
      );
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
            Text(
              'Aviso de Privacidad',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Policy text area
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('AVISO DE PRIVACIDAD INTEGRAL', Icons.privacy_tip_outlined),
                    SizedBox(height: 8),
                    _buildBodyText(
                      'Maximiliano Diaz Clemente (persona física), en adelante "Salud Prenatal" o "el Responsable", con domicilio en Av Sauce #198, 29010 Albania Baja. Tuxtla Gutiérrez, Chiapas, es el responsable del uso y protección de sus datos personales.',
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('1. ¿Para qué fines utilizaremos sus datos personales?'),
                    SizedBox(height: 8),
                    _buildBodyText('Los datos que recabamos se utilizarán para las siguientes finalidades principales:'),
                    SizedBox(height: 8),
                    _buildBullet('Creación, estudio, análisis, actualización y conservación de su expediente clínico.'),
                    _buildBullet('Llevar un control y seguimiento de su embarazo, incluyendo semanas de gestación y cálculo de riesgo prenatal.'),
                    _buildBullet('Registro y gestión de consultas médicas, notas clínicas, objetivos y planes de tratamiento.'),
                    _buildBullet('Creación y administración de su cuenta de usuario dentro de la aplicación móvil.'),
                    _buildBullet('Agendamiento y gestión de citas médicas.'),
                    SizedBox(height: 12),
                    _buildBodyText('Finalidades secundarias (puede oponerse enviando un correo a fitnesspro.soporte@gmail.com):'),
                    SizedBox(height: 8),
                    _buildBullet('Fines estadísticos, de investigación y análisis interno para la mejora de la aplicación (datos anonimizados).'),
                    _buildBullet('Envío de notificaciones relacionadas con actualizaciones o información general de salud materno-fetal.'),
                    SizedBox(height: 20),

                    _buildSectionTitle('2. ¿Qué datos personales utilizaremos?'),
                    SizedBox(height: 8),
                    _buildBullet('Datos de identificación y contacto: nombre completo, apellidos, correo electrónico, fecha de nacimiento y edad.'),
                    SizedBox(height: 12),
                    _buildSensitiveDataBox(),
                    SizedBox(height: 20),

                    _buildSectionTitle('3. ¿Con quién compartimos su información?'),
                    SizedBox(height: 8),
                    _buildBodyText(
                      'Sus datos personales NO son compartidos con ninguna empresa, organización o persona distinta a nosotros, salvo en cumplimiento de obligaciones legales ante autoridades sanitarias o judiciales competentes, o en situaciones de riesgo inminente para su vida o salud.',
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('4. Derechos ARCO'),
                    SizedBox(height: 8),
                    _buildBodyText(
                      'Usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse al uso de sus datos personales. Para ejercer estos derechos envíe su solicitud a fitnesspro.soporte@gmail.com con su nombre, identificación oficial y descripción de su petición. Daremos respuesta en un plazo máximo de 20 días hábiles.',
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('5. Revocación del consentimiento'),
                    SizedBox(height: 8),
                    _buildBodyText(
                      'Puede revocar su consentimiento enviando un correo a fitnesspro.soporte@gmail.com. Considere que en ciertos casos, por obligación legal (NOM-004-SSA3-2012), podremos seguir conservando sus datos. La revocación puede implicar que no podamos seguir prestándole los servicios.',
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('6. Cambios al aviso de privacidad'),
                    SizedBox(height: 8),
                    _buildBodyText(
                      'Este aviso puede modificarse. Le informaremos a través de la propia aplicación o mediante notificaciones al iniciar sesión.',
                    ),
                    SizedBox(height: 20),

                    _buildDateChip('Última actualización: 21 de junio de 2026'),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Consent checkboxes + button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCheckboxTile(
                  value: _acceptedPrivacy,
                  onChanged: (val) => setState(() => _acceptedPrivacy = val ?? false),
                  label: 'He leído el aviso de privacidad y acepto el tratamiento de mis datos personales para las finalidades descritas.',
                ),
                SizedBox(height: 12),
                _buildCheckboxTile(
                  value: _acceptedSensitiveData,
                  onChanged: (val) => setState(() => _acceptedSensitiveData = val ?? false),
                  label: 'Otorgo mi consentimiento expreso para el tratamiento de mis datos personales sensibles (datos de salud y embarazo).',
                  isImportant: true,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue ? _onAcceptAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: _canContinue ? Colors.white : AppColors.textMuted,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Acepto y Continúo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _canContinue ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textDark,
        height: 1.6,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitiveDataBox() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
              SizedBox(width: 8),
              Text(
                'Datos Personales Sensibles',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildBullet('Historial Ginecobstétrico: embarazos previos, partos, cesáreas y abortos.'),
          _buildBullet('Antecedentes patológicos: hipertensión, diabetes, preeclampsia, enfermedad renal crónica, entre otros.'),
          _buildBullet('Antecedentes familiares de hipertensión y enfermedades cardíacas.'),
          _buildBullet('Datos actuales del embarazo: semanas de gestación, tipo de sangre, riesgo calculado.'),
          _buildBullet('Datos de consulta médica: notas de evolución, síntomas, signos vitales y plan de tratamiento.'),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    bool isImportant = false,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? (isImportant
                  ? const Color(0xFFFFF0F6)
                  : AppColors.primary.withOpacity(0.05))
              : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  height: 1.5,
                  fontWeight: isImportant ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
