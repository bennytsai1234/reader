import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _scanFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final barcodeCapture = await controller.analyzeImage(path);
      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final code = barcodeCapture.barcodes.first.rawValue;
        if (code != null && mounted) {
          Navigator.pop(context, code);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未發現 QR Code')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掃碼匯入'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: '從相簿選擇',
            onPressed: _scanFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final code = barcode.rawValue;
            if (code != null) {
              Navigator.pop(context, code);
              break;
            }
          }
        },
      ),
    );
  }
}

