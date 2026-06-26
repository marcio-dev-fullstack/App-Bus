/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/auth/controllers/auth_controller.dart';
import 'package:front_end/features/shell/screens/app_shell.dart';
import 'package:front_end/locator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    // Obtém uma instância do controller do nosso localizador de serviços.
    _authController = locator<AuthController>();
    // Adiciona um listener para reagir às mudanças de estado do controller.
    _authController.addListener(_onAuthChange);
  }

  void _onAuthChange() {
    // Se o usuário estiver autenticado, navega para a tela principal.
    if (_authController.isAuthenticated) {
      // Usamos `pushReplacement` para que o usuário não possa voltar para a tela de login.
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    }

    // Garante que a UI seja reconstruída para refletir o estado de `isLoading`.
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _login() async {
    // Valida o formulário antes de prosseguir.
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await _authController.login(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      // Se o login falhar, exibe uma mensagem de erro.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no login: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChange);
    _authController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login do Monitor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Usuário ou E-mail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 32),
              _authController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('ENTRAR'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
