import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false; // Variable para evitar múltiples redirecciones

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing) {
        _isProcessing = true; // Marcar como en proceso
        _handleQRCode(scanData.code);
      }
    });
  }

  void _handleQRCode(String? code) {
    try {
      if (code != null) {
        // Asumimos que el código QR contiene un enlace a un quiz en formato "app://quiz/{quizId}"
        final uri = Uri.parse(code);

        if (uri.scheme == 'app' &&
            uri.host == 'quiz' &&
            uri.pathSegments.isNotEmpty) {
          final quizId = uri.pathSegments[0];
          print('Quiz ID: $quizId');
          Navigator.pop(context); // Cerrar el escáner
          Navigator.pushNamed(context, '/quiz',
                  arguments: quizId) // Redirigir al quiz
              .then((_) {
            // Resetear el estado después de que se vuelva a la pantalla del escáner
            _isProcessing = false;
          });
        } else {
          _showInvalidQRCodeMessage();
        }
      } else {
        _isProcessing = false; // Resetear en caso de código nulo
      }
    } catch (e) {
      print(e);
      _isProcessing = false; // Resetear en caso de error
    }
  }

  void _showInvalidQRCodeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código QR inválido')),
    );
    _isProcessing = false; // Resetear después de mostrar el mensaje
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escanea el Código QR',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: const Color(0xFF006135),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
}
