import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class QRCodeLoginPage extends StatefulWidget {
  const QRCodeLoginPage({super.key});

  @override
  State<QRCodeLoginPage> createState() => _QRCodeLoginPageState();
}

class _QRCodeLoginPageState extends State<QRCodeLoginPage> {
  bool _isScanning = false;

  // Processo de login via QR code
  Future<void> _handleQRCodeScanned(String qrCodeData) async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Usar o método do AuthController para login com QR code
      final authController = Get.find<AuthController>();
      final success = await authController.signInWithQRCode(qrCodeData);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar QR code: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login com QR Code'), elevation: 0),
      body: Obx(() {
          final authController = Get.find<AuthController>();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Instrução
                  const Text(
                    'Aponte a câmera para o QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O QR Code pode ser encontrado na sua carteira digital ou gerado pelo administrador do sistema',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Erro
                  if (authController.error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 20),
                      color: Colors.red.shade100,
                      child: Text(
                        authController.error!,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Área do QR code scanner (simulado)
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        authController.isLoading || _isScanning
                            ? const Center(child: CircularProgressIndicator())
                            : Stack(
                              alignment: Alignment.center,
                              children: [
                                // Aqui você usaria um widget de scanner de QR code real
                                // como qr_code_scanner ou mobile_scanner
                                const Icon(
                                  Icons.qr_code_scanner,
                                  size: 100,
                                  color: Colors.black38,
                                ),

                                // Botão para simular um scan
                                Positioned(
                                  bottom: 10,
                                  child: ElevatedButton(
                                    onPressed:
                                        () => _handleQRCodeScanned(
                                          'codigo_simulado',
                                        ),
                                    child: const Text('Simular Scan'),
                                  ),
                                ),
                              ],
                            ),
                  ),

                  const SizedBox(height: 40),

                  // Informações adicionais
                  const Text(
                    'Certifique-se de que o QR Code esteja bem iluminado e dentro do quadro',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }),
    );
  }
}
