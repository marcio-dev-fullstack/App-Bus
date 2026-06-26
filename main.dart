/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/auth/controllers/auth_controller.dart';
import 'package:front_end/features/auth/screens/login_screen.dart';
import 'package:front_end/features/shell/screens/app_shell.dart';
import 'package:front_end/locator.dart';
import 'package:front_end/core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main({Function? setupDependencies}) async {
  // Garante que os bindings do Flutter foram inicializados antes de rodar o app.
  // É útil se você precisar executar código assíncrono antes de runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variáveis de ambiente do arquivo .env
  await dotenv.load(fileName: ".env");

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
    // A splash screen nativa será exibida automaticamente enquanto o app carrega.
    // Quando o `tryAutoLogin` terminar, o `isLoading` se tornará falso e o listener
    // reconstruirá a UI, mostrando a tela correta.
    // Se o usuário estiver autenticado, mostra a AppShell. Caso contrário, mostra a LoginScreen.
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
