import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/database_helper.dart';
import 'services/biometric_service.dart';
import 'screens/login_screen.dart';

void main() async {
  // Garante a inicialização das APIs nativas
  WidgetsFlutterBinding.ensureInitialized();

  // Trava em modo retrato para estabilidade da câmera no ônibus
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inicialização assíncrona de serviços globais
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Abre/Cria o SQLite

    final biometricService = BiometricService();
    await biometricService.loadModel(); // Carrega o .tflite na RAM
    
    print("BusEscolar: Inicialização concluída com sucesso.");
  } catch (e) {
    print("Erro na inicialização do sistema: $e");
  }

  runApp(const BusEscolarApp());
}

class BusEscolarApp extends StatelessWidget {
  const BusEscolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusEscolar - SEMEC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        useMaterial_design: true,
      ),
      home: const LoginScreen(),
    );
  }
}