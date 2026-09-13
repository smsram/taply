import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class QRToolScreen extends StatefulWidget {
  const QRToolScreen({super.key});

  @override
  State<QRToolScreen> createState() => _QRToolScreenState();
}

class _QRToolScreenState extends State<QRToolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _qrTextController = TextEditingController(
    text: 'https://taply.app',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scanner'),
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Generator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildScannerTab(context), _buildGeneratorTab(context)],
      ),
    );
  }

  Widget _buildScannerTab(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            'Align the QR code within the frame to scan',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.black38
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 96,
                    color: Colors.blueGrey,
                  ),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Phase 2 Native Camera API',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.showSnackBar(
                    'Select from gallery ready for Phase 2',
                  ),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('From Gallery'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.showSnackBar(
                    'Simulating scan: https://taply.app',
                  ),
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Simulate Scan'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratorTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        TextField(
          controller: _qrTextController,
          decoration: const InputDecoration(
            labelText: 'Text or URL',
            hintText: 'Enter link or text to generate QR...',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 160,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _qrTextController.text.isEmpty
                      ? 'https://taply.app'
                      : _qrTextController.text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: () =>
              context.showSnackBar('QR Code saved to photos preview'),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Save QR Code Image'),
        ),
      ],
    );
  }
}
