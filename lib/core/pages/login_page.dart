import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/orientation_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Desbloquear orientações ao entrar na página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OrientationController>().unlockOrientation();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isMobile = screenSize.width < 600;

    // Calcula dimensões responsivas
    final maxWidth = isPortrait ? screenSize.width : screenSize.height;
    final spacing = maxWidth * (isMobile ? 0.04 : 0.03);
    final buttonHeight = maxWidth * (isMobile ? 0.12 : 0.08);
    final fontSize = maxWidth * (isMobile ? 0.04 : 0.03);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: maxWidth * 0.08,
                  vertical: spacing * 2,
                ),
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: _buildLoginForm(
                      maxWidth: maxWidth,
                      fontSize: fontSize,
                      spacing: spacing,
                      buttonHeight: buttonHeight,
                      isPortrait: isPortrait,
                      isMobile: isMobile,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm({
    required double maxWidth,
    required double fontSize,
    required double spacing,
    required double buttonHeight,
    required bool isPortrait,
    required bool isMobile,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.menu_book,
            size: fontSize * 3,
            color: const Color(0xFF1976D2),
          ),
          SizedBox(height: spacing),
          Text(
            'LudiTeca',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize * 1.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1976D2),
            ),
          ),
          SizedBox(height: spacing * 2),
          _buildResponsiveTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            fontSize: fontSize,
            spacing: spacing,
          ),
          SizedBox(height: spacing),
          _buildResponsiveTextField(
            controller: _passwordController,
            label: 'Senha',
            icon: Icons.lock,
            isPassword: true,
            fontSize: fontSize,
            spacing: spacing,
          ),
          SizedBox(height: spacing),
          _buildLoginButton(height: buttonHeight, fontSize: fontSize),
          SizedBox(height: spacing),
          _buildDivider(),
          SizedBox(height: spacing),
          _buildQRCodeButton(height: buttonHeight, fontSize: fontSize),
          SizedBox(height: spacing),
          _buildRegisterLink(fontSize: fontSize),
        ],
      ),
    );
  }

  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    required double fontSize,
    required double spacing,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: spacing * 0.5),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: fontSize * 1.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.all(spacing),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo é obrigatório';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton({required double height, required double fontSize}) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            try {
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();

              // Mostrar indicador de carregamento
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        const Center(child: CircularProgressIndicator()),
              );

              // Tentar fazer login
              final success = await _authController.signIn(email, password);

              // Fechar o indicador de carregamento
              if (!mounted) return;
              Navigator.of(context).pop();

              if (success) {
                // Navegar para a página inicial usando GetX
                Get.offAllNamed('/home');
              } else {
                // Mostrar mensagem de erro
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _authController.error ?? 'Erro ao fazer login',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              // Fechar o indicador de carregamento em caso de erro
              if (!mounted) return;
              Navigator.of(context).pop();

              // Mostrar mensagem de erro
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao fazer login: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Entrar',
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('ou', style: TextStyle(color: Colors.grey[600])),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildQRCodeButton({
    required double height,
    required double fontSize,
  }) {
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/qr-code-login');
        },
        icon: const Icon(Icons.qr_code),
        label: Text('Entrar com QR Code', style: TextStyle(fontSize: fontSize)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1976D2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildRegisterLink({required double fontSize}) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/register');
      },
      child: Text(
        'Não tem uma conta? Cadastre-se',
        style: TextStyle(
          fontSize: fontSize * 0.9,
          color: const Color(0xFF1976D2),
        ),
      ),
    );
  }
}
