/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/shell/screens/app_shell.dart';
import 'package:front_end/features/sync/controllers/sync_controller.dart';
import 'package:front_end/locator.dart';

class InitialSyncScreen extends StatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  State<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends State<InitialSyncScreen> {
  late final SyncController _syncController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _syncController = locator<SyncController>();
    _syncController.addListener(_onSyncStateChanged);
    _startSync();
  }

  void _onSyncStateChanged() {
    // Reconstrói a UI para refletir a nova mensagem ou estado de carregamento.
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startSync() async {
    setState(() {
      _hasError = false;
    });

    try {
      await _syncController.baixarDadosIniciais();
      // Se a sincronização for bem-sucedida e o widget ainda estiver montado, navega para a tela principal.
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      }
    } catch (e) {
      // Se ocorrer um erro, o controller já terá a mensagem de erro.
      // Apenas atualizamos a UI para exibir o botão de tentar novamente.
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_syncController.isSyncing) const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _syncController.syncMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_hasError) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _startSync,
                  icon: const Icon(Icons.refresh),
                  label: const Text('TENTAR NOVAMENTE'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _syncController.removeListener(_onSyncStateChanged);
    _syncController.dispose(); // Como é uma Factory, descartamos aqui.
    super.dispose();
  }
}
