import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/smart_scan_provider.dart';

class SmartScanScreen extends StatefulWidget {
  const SmartScanScreen({super.key});

  @override
  State<SmartScanScreen> createState() => _SmartScanScreenState();
}

class _SmartScanScreenState extends State<SmartScanScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SmartScanProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Smart Scan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildIllustration(),
                const SizedBox(height: 40),
                const Text(
                  'Scan Business Card',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Capture or upload a photo of a business card to automatically extract lead information.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF79747E),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                _buildActionButtons(context, provider),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (provider.isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6750A4)),
                    SizedBox(height: 16),
                    Text(
                      'Processing image...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFEADDFF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6750A4).withValues(alpha: 0.1), width: 10),
      ),
      child: const Center(
        child: Icon(
          Icons.badge_rounded,
          size: 100,
          color: Color(0xFF6750A4),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SmartScanProvider provider) {
    return Column(
      children: [
        _buildScanButton(
          context: context,
          label: 'Take Photo',
          icon: Icons.camera_alt_rounded,
          onPressed: () => _handleScan(context, provider, ImageSource.camera),
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        _buildScanButton(
          context: context,
          label: 'Scan QR/Barcode',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: () => _openQRScanner(context),
          isPrimary: false,
        ),
        const SizedBox(height: 16),
        _buildScanButton(
          context: context,
          label: 'Upload from Gallery',
          icon: Icons.photo_library_rounded,
          onPressed: () => _handleScan(context, provider, ImageSource.gallery),
          isPrimary: false,
        ),
      ],
    );
  }

  void _openQRScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Scan QR/Barcode')),
        body: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String code = barcodes.first.rawValue ?? 'Unknown';
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Scanned: $code')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleScan(BuildContext context, SmartScanProvider provider, ImageSource source) async {
    await provider.scanBusinessCard(source);
    if (!context.mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.redAccent),
      );
    } else if (provider.scannedData != null) {
      _showScannedDataDialog(context, provider.scannedData!);
    }
  }

  void _showScannedDataDialog(BuildContext context, ScannedLeadData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScannedDataSheet(data: data),
    );
  }

  Widget _buildScanButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF6750A4)),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : const Color(0xFF6750A4),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF6750A4) : Colors.white,
          side: isPrimary ? null : const BorderSide(color: Color(0xFF6750A4)),
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ScannedDataSheet extends StatelessWidget {
  final ScannedLeadData data;

  const _ScannedDataSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scanned Information',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We extracted the following details. You can edit them in the next step.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.person_rounded, 'Name', data.name),
          _buildInfoRow(Icons.business_rounded, 'Company', data.company),
          _buildInfoRow(Icons.email_rounded, 'Email', data.email),
          _buildInfoRow(Icons.phone_rounded, 'Phone', data.phone),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/crm/create-lead', extra: {
                  'scannedData': data.toMap(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Create Lead',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDF7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6750A4), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value.isEmpty ? 'Not found' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty ? Colors.grey : const Color(0xFF1D1B20),
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
