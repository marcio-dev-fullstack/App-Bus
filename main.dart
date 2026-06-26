/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/auth/controllers/auth_controller.dart';
import 'package:front_end/features/auth/screens/login_screen.dart';
import 'package:front_end/features/auth/screens/splash_screen.dart';
import 'package:front_end/features/shell/screens/app_shell.dart';
import 'package:front_end/locator.dart';
import 'package:front_end/core/theme/app_theme.dart';

void main({Function? setupDependencies}) {
  // Garante que os bindings do Flutter foram inicializados antes de rodar o app.
  // É útil se você precisar executar código assíncrono antes de runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Se uma função de configuração for fornecida (pelos testes), execute-a.
  // Caso contrário, execute a configuração padrão de produção.
  if (setupDependencies != null) {
    setupDependencies();
  } else {
    setupLocator();
  }

  runApp(const AppBus());
}

class AppBus extends StatefulWidget {
  const AppBus({super.key});

  @override
  State<AppBus> createState() => _AppBusState();
}

class _AppBusState extends State<AppBus> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = locator<AuthController>();
    // Adiciona um listener para reconstruir a UI quando o estado de auth mudar.
    _authController.addListener(_onAuthStateChanged);
    // Inicia a verificação de auto-login.
    _authController.tryAutoLogin();
  }

  void _onAuthStateChanged() {
    setState(() {
      // Apenas reconstrói o widget para que o `build` possa reavaliar o estado.
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App-Bus',
      theme: AppTheme.lightTheme, // Aplica o tema customizado
      home: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    // Enquanto o `tryAutoLogin` está em execução, exibe a tela de splash.
    if (_authController.isLoading) {
      return const SplashScreen();
    }
    // Após a verificação, se o usuário estiver autenticado, mostra a AppShell.
    // Caso contrário, mostra a LoginScreen.
    return _authController.isAuthenticated
        ? const AppShell()
        : const LoginScreen();
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
