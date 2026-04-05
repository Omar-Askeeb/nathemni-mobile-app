import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/navigation/app_drawer.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String? _scannedCode;
  bool _isCameraActive = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _scannedCode = code;
          _isCameraActive = false;
        });
        _controller.stop();
      }
    }
  }

  void _copyToClipboard() {
    if (_scannedCode != null) {
      Clipboard.setData(ClipboardData(text: _scannedCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الكود'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedCode = null;
      _isCameraActive = true;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود و QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isCameraActive ? Icons.flash_off : Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Camera Preview / Result Container
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isCameraActive
                    ? Stack(
                        children: [
                          MobileScanner(
                            controller: _controller,
                            onDetect: _onBarcodeDetect,
                          ),
                          // Scanner Frame Overlay
                          Center(
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 60,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'ضع الكود داخل الإطار',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      backgroundColor:
                                          Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ),
            ),
          ),

          // Result Text Area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'النتيجة',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _scannedCode ?? 'لم يتم المسح بعد...',
                              style: TextStyle(
                                fontSize: 16,
                                color: _scannedCode != null
                                    ? Colors.black
                                    : Colors.grey,
                                fontFamily: _scannedCode != null &&
                                        _isEnglishText(_scannedCode!)
                                    ? 'monospace'
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Copy Button
                if (_scannedCode != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('نسخ إلى الحافظة'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Scan Again Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _scannedCode != null ? _resetScanner : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(_scannedCode != null
                        ? 'مسح كود جديد'
                        : 'جاري المسح...'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  bool _isEnglishText(String text) {
    // Check if text contains mostly English characters/numbers
    final englishRegex = RegExp(r'[a-zA-Z0-9]');
    final matches = englishRegex.allMatches(text);
    return matches.length > text.length / 2;
  }
}
