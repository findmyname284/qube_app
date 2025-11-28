import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qube/widgets/qubebar.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  String? lastCode;
  bool _processing = false;
  bool _cameraActive = true;
  bool _showRetry = false;

  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    _startScanTimer();
  }

  void _startScanTimer() async {
    await Future.delayed(const Duration(minutes: 1));

    if (!mounted) return;

    if (!_processing && _cameraActive) {
      setState(() {
        _cameraActive = false;
        _showRetry = true;
      });
      await controller.stop();
    }
  }

  void _restartScan() async {
    setState(() {
      _cameraActive = true;
      _showRetry = false;
      lastCode = null;
    });

    await controller.start();
    _startScanTimer();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing || !_cameraActive) return;
    _processing = true;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      _processing = false;
      return;
    }

    final value = barcodes.first.rawValue ?? '';

    if (!mounted) return;

    setState(() {
      lastCode = value;
      _cameraActive = false;
    });

    await controller.stop();

    // Имитация отправки запроса на сервер
    await _sendQrToServer(value);

    if (!mounted) return;

    _processing = false;
  }

  Future<void> _sendQrToServer(String qrValue) async {
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => AlertDialog(
    //     backgroundColor: const Color(0xFF1E1F2E),
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    //     content: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         const CircularProgressIndicator(color: Color(0xFF6C5CE7)),
    //         const SizedBox(height: 16),
    //         Text(
    //           'Обработка QR-кода...',
    //           style: const TextStyle(color: Colors.white),
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    // // Имитация запроса к серверу
    // await Future.delayed(const Duration(seconds: 2));

    // if (!mounted) return;
    // Navigator.of(context).pop();

    // Показываем результат
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'QR-код обработан',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(qrValue, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartScan();
            },
            child: const Text(
              'Сканировать ещё',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: QubeAppBar(
        title: 'Сканирование QR',
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Камера
          if (_cameraActive)
            MobileScanner(controller: controller, onDetect: _onDetect),

          // Затемнение по краям
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Рамка сканера
          _buildScannerFrame(),

          // Сообщение
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: const Column(
              children: [
                Text(
                  'Наведите камеру на QR-код',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'QR-код будет сканирован автоматически',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Кнопка повтора
          if (_showRetry)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'QR-код не найден',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFA363D9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _restartScan,
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Повторить',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Индикатор загрузки при обработке
          if (_processing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                    SizedBox(height: 16),
                    Text(
                      'Обработка QR-кода...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerFrame() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Левый верхний угол
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 4),
                    left: BorderSide(color: Colors.white, width: 4),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // Правый верхний угол
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 4),
                    right: BorderSide(color: Colors.white, width: 4),
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // Левый нижний угол
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 4),
                    left: BorderSide(color: Colors.white, width: 4),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // Правый нижний угол
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 4),
                    right: BorderSide(color: Colors.white, width: 4),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
