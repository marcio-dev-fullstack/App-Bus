import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  bool _obscureSenha = true;

  Future<void> _realizarLogin() async {
    final usuario = _usuarioController.text.trim();
    final senha = _senhaController.text.trim();

    if (usuario.isEmpty || senha.isEmpty) {
      _showError("Preencha todos os campos");
      return;
    }

    setState(() => _isLoading = true);

    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      
      if (connectivityResult != ConnectivityResult.none) {
        // --- CENÁRIO ONLINE: Valida no Backend (Ex: FastAPI/PostgreSQL) ---
        // Simulação de chamada de API
        await Future.delayed(const Duration(seconds: 2)); 
        
        // Aqui você chamaria seu serviço de sincronização para baixar os alunos
        final syncService = SyncService();
        await syncService.checkAndSync(); 
        
        _irParaHome();
      } else {
        // --- CENÁRIO OFFLINE: Valida no SQLite local ---
        // Aqui você faria um SELECT na sua tabela de usuários locais
        _showWarning("Modo Offline: Usando dados locais salvos.");
        _irParaHome();
      }
    } catch (e) {
      _showError("Falha na autenticação: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _irParaHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo da SEMEC / Prefeitura
              const Icon(Icons.directions_bus_rounded, size: 80, color: Color(0xFF0D47A1)),
              const SizedBox(height: 10),
              const Text(
                "BusEscolar",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              ),
              const Text("Conceição do Araguaia - PA", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 50),

              // Campo Usuário
              TextField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  labelText: "Usuário ou Matrícula",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Senha
              TextField(
                controller: _senhaController,
                obscureText: _obscureSenha,
                decoration: InputDecoration(
                  labelText: "Senha",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureSenha ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              // Botão de Entrar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _realizarLogin,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENTRAR NO SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                "v1.1.0 - Modo Híbrido Ativado",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}