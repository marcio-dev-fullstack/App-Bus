/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/student/repositories/student_repository_local.dart';

class StudentEditScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentEditScreen({super.key, required this.student});

  @override
  State<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends State<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _matriculaController;
  final StudentRepositoryLocal _studentRepository = StudentRepositoryLocal();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student['nome']);
    _matriculaController = TextEditingController(
      text: widget.student['matricula'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        await _studentRepository.atualizarDadosAluno(
          widget.student['id'],
          _nameController.text,
          _matriculaController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aluno atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pop(true); // Retorna 'true' para indicar sucesso
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Aluno')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(labelText: 'Matrícula'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 32),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveStudent,
                      child: const Text('SALVAR'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
