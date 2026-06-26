/// ## Arquiteto de Solução e Desenvolvedor Líder
///
import 'dart:async';

/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/student/repositories/student_repository_local.dart';
import 'package:front_end/features/student/screens/student_edit_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

/// Enum para definir as opções de ordenação.
enum SortOption { nome, matricula }

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentRepositoryLocal _studentRepository = StudentRepositoryLocal();
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> _students = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  // Estado para a busca e ordenação
  SortOption _currentSort = SortOption.nome;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  // Variável estática para persistir o termo de busca entre aberturas da tela.
  static String _lastSearchTerm = '';
  // Variável estática para persistir a posição do scroll.
  static double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // Restaura o último termo de busca e o estado da UI.
    _searchController.text = _lastSearchTerm;
    if (_lastSearchTerm.isNotEmpty) {
      _isSearching = true;
    }

    _searchController.addListener(() {
      // Cancela o timer anterior se ele estiver ativo.
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      // Inicia um novo timer. A busca só será executada após 500ms
      // de inatividade do usuário.
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _loadStudents();
        // Salva o termo de busca enquanto o usuário digita.
        _lastSearchTerm = _searchController.text;
      });
    });

    _loadStudents().then((_) {
      // Após o carregamento inicial, restaura a posição do scroll.
      if (_scrollController.hasClients && _lastScrollOffset > 0) {
        _scrollController.jumpTo(_lastScrollOffset);
      }
    });
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final orderBy = _currentSort == SortOption.nome
        ? 'nome ASC'
        : 'matricula ASC';
    final newStudents = await _studentRepository.obterTodosAlunos(
      orderBy: orderBy,
      searchTerm: _searchController.text,
    );

    if (mounted) {
      // Lógica de Diff para animar a lista
      final oldList = List.of(_students);

      // 1. Animar remoções
      for (int i = oldList.length - 1; i >= 0; i--) {
        final student = oldList[i];
        if (!newStudents.any((s) => s['id'] == student['id'])) {
          _students.removeAt(i);
          _animatedListKey.currentState?.removeItem(
            i,
            (context, animation) =>
                _buildAnimatedItem(student, animation, isRemoving: true),
          );
        }
      }

      // 2. Animar inserções
      for (int i = 0; i < newStudents.length; i++) {
        final student = newStudents[i];
        if (!oldList.any((s) => s['id'] == student['id'])) {
          _students.insert(i, student);
          _animatedListKey.currentState?.insertItem(i);
        }
      }

      // Garante que a ordenação esteja correta após as animações
      _students
        ..clear()
        ..addAll(newStudents);

      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEditScreen(Map<String, dynamic> student) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StudentEditScreen(student: student)),
    );

    // Se a tela de edição retornou 'true', atualiza a lista.
    if (result == true) {
      _loadStudents();
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    Map<String, dynamic> student,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // O usuário deve tocar em um botão
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Você tem certeza que deseja deletar o aluno?'),
                Text(
                  '${student['nome']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Deletar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await _studentRepository.deletarAluno(student['id']);
                Navigator.of(context).pop(); // Fecha o diálogo
                _loadStudents(); // Atualiza a lista
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nome ou matrícula...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : Text('Alunos (${_students.length})'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                // Limpa a busca ao fechar a barra de pesquisa
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          // Esconde o botão de ordenar quando estiver buscando
          if (!_isSearching)
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              onSelected: (SortOption result) {
                if (_currentSort != result) {
                  setState(() {
                    _currentSort = result;
                    _loadStudents();
                  });
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<SortOption>>[
                    const PopupMenuItem<SortOption>(
                      value: SortOption.nome,
                      child: Text('Ordenar por Nome'),
                    ),
                    const PopupMenuItem<SortOption>(
                      value: SortOption.matricula,
                      child: Text('Ordenar por Matrícula'),
                    ),
                  ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildStudentList(),
    );
  }

  Widget _buildStudentList() {
    if (_students.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Nenhum aluno cadastrado.'
              : 'Nenhum aluno encontrado.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: AnimatedList(
        controller: _scrollController,
        key: _animatedListKey,
        initialItemCount: _students.length,
        itemBuilder: (context, index, animation) {
          // Verifica se o índice é válido para evitar erros durante a animação de remoção
          if (index >= _students.length) return const SizedBox.shrink();
          final student = _students[index];
          return _buildAnimatedItem(student, animation);
        },
      ),
    );
  }

  Widget _buildAnimatedItem(
    Map<String, dynamic> student,
    Animation<double> animation, {
    bool isRemoving = false,
  }) {
    final hasFaceVector = student['vetor_facial'] != null;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isRemoving ? -1 : 1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListTile(
            onTap: () => _navigateToEditScreen(student),
            onLongPress: () => _showDeleteConfirmationDialog(student),
            leading: CircleAvatar(child: Text(student['nome']?[0] ?? '?')),
            title: Text(student['nome'] ?? 'Nome não informado'),
            subtitle: Text('Matrícula: ${student['matricula'] ?? 'N/A'}'),
            trailing: hasFaceVector
                ? const Icon(Icons.face_retouching_natural, color: Colors.green)
                : const Icon(Icons.face, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Salva o último termo de busca ao sair da tela.
    _lastSearchTerm = _searchController.text;
    // Salva a última posição do scroll.
    _lastScrollOffset = _scrollController.offset;
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
