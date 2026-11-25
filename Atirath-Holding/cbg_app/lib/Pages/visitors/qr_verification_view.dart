import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rbac_service.dart';
import '../../widgets/module_ui_widgets.dart';

class QrVerificationView extends StatefulWidget {
  final ScreenPermission screenPerm;
  final ValueChanged<String> onNavigate;

  const QrVerificationView({super.key, required this.screenPerm, required this.onNavigate});

  @override
  State<QrVerificationView> createState() => _QrVerificationViewState();
}

class _QrVerificationViewState extends State<QrVerificationView> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _subscribed = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ModuleTag(text: 'ROADMAP • RELEASE v2.4', bgColor: Color(0xFFFEF3C7), textColor: Color(0xFFB45309)),
              const SizedBox(height: 10),
              Text('Contactless QR & Biometric Kiosk Verification',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                'Automated boom-barrier unlock, encrypted QR e-Pass scanning, and ATEX intrinsic-safe kiosk integration.',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFCBD5E1), height: 1.45),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 72, color: Color(0xFF38BDF8)),
                    const SizedBox(height: 8),
                    Text('ATEX Optical Kiosk Scanner Pending Hardware Pairing',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Planned v2.4 Capabilities', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _capTile(Icons.qr_code_scanner, 'Dynamic Encrypted QR Pass', 'Rotating 60-second cryptographic QR tokens preventing badge cloning.'),
        _capTile(Icons.door_sliding_outlined, 'Turnstile & Boom Barrier Sync', 'Instant Modbus/TCP relay trigger upon safety clearance & host approval.'),
        _capTile(Icons.face_retouching_natural, 'Face-Match Kiosk Liveness', 'Touchless anti-spoofing facial check matched against Govt ID.'),
        _capTile(Icons.offline_bolt_outlined, 'Offline Gate Cache', 'Local edge synchronization during plant WAN downtime.'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Get Notified When QR Hardware Goes Live', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_subscribed)
                Text('Notification registered for ${_emailCtrl.text.trim()}!', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF059669)))
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: moduleInputDecoration('Security / Plant Admin Email'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_emailCtrl.text.trim().isNotEmpty) {
                          setState(() => _subscribed = true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                      child: const Text('Notify Me'),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => widget.onNavigate('dashboard'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Visitor Operations Center'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _capTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
