import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class PreviewQuiz extends StatefulWidget {
  final int? quizId; // Nullable to allow empty state for new quizzes
  const PreviewQuiz({super.key, this.quizId});

  @override
  _PreviewQuizState createState() => _PreviewQuizState();
}

class _PreviewQuizState extends State<PreviewQuiz> {
  final SupabaseClient supabase = Supabase.instance.client;

  late TextEditingController _codeController;
  late TextEditingController _instructionController;
  late TextEditingController _correctExplanationController;
  bool isEditingCode = false;
  List<Map<String, dynamic>> options = [];
  String correctOptionKey = 'A';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.quizId == null) {
      _generateRandomQuiz();
    } else {
      _fetchQuizData(widget.quizId!);
    }
  }

  Future<void> _generateRandomQuiz() async {
    try {
      // Retrieve all non-reviewed quizzes
      final quizResponse =
          await supabase.from('quizzes').select('*').eq('reviewed', false);

      if (quizResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se encontraron quizzes no revisados')),
        );
        _initializeEmptyFields();
        return;
      }

      // Select a random quiz from the list
      final randomQuiz = quizResponse[Random().nextInt(quizResponse.length)];
      final quizId = randomQuiz['id'];

      // Set the selected quiz as reviewed
      await supabase
          .from('quizzes')
          .update({'reviewed': true}).eq('id', quizId);

      // Load the selected quiz data
      await _fetchQuizData(quizId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar con IA: $e')),
      );
      _initializeEmptyFields();
    }
  }

  Future<void> _fetchQuizData(int quizId) async {
    try {
      // Fetch quiz data
      final quizResponse = await supabase
          .from('quizzes')
          .select('id, code, instruction')
          .eq('id', quizId)
          .maybeSingle();

      // Fetch options for the quiz
      final optionsResponse = await supabase
          .from('options')
          .select('id, content, key')
          .eq('question_id', quizId);

      final List<Map<String, dynamic>> optionsData =
          List<Map<String, dynamic>>.from(optionsResponse ?? []);

      // Fetch correct option explanation from questions table
      final questionResponse = await supabase
          .from('questions')
          .select('correct_option_explanation')
          .eq('quiz_id', quizId)
          .maybeSingle();

      setState(() {
        _codeController =
            TextEditingController(text: quizResponse?['code'] ?? '');
        _instructionController =
            TextEditingController(text: quizResponse?['instruction'] ?? '');
        _correctExplanationController = TextEditingController(
          text: questionResponse?['correct_option_explanation'] ?? '',
        );
        options = optionsData;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del quiz: $e')),
      );
      _initializeEmptyFields();
    }
  }

  void _initializeEmptyFields() {
    setState(() {
      _codeController = TextEditingController(text: '');
      _instructionController = TextEditingController(text: '');
      _correctExplanationController = TextEditingController(text: '');
      options = [];
      isLoading = false;
    });
  }

  Future<void> _updateQuiz() async {
    // Ensure quizId is not null before proceeding
    if (widget.quizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz ID no puede ser nulo')),
      );
      return;
    }
    try {
      // Actualizar los datos principales del quiz
      final quizUpdateResponse = await supabase.from('quizzes').update({
        'code': _codeController.text,
        'instruction': _instructionController.text,
      }).eq('id', widget.quizId!);

      if (quizUpdateResponse.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al actualizar el quiz: ${quizUpdateResponse.error.message}')),
        );
        return;
      }

      // Actualizar la explicación correcta en la tabla questions
      final questionUpdateResponse = await supabase.from('questions').update({
        'correct_option_explanation': _correctExplanationController.text
      }).eq('quiz_id', widget.quizId!);

      if (questionUpdateResponse.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al actualizar la explicación: ${questionUpdateResponse.error.message}')),
        );
        return;
      }

      // Actualizar cada opción en la tabla options
      for (var option in options) {
        final optionUpdateResponse = await supabase
            .from('options')
            .update({'content': option['content']}).eq('id', option['id']);

        if (optionUpdateResponse.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error al actualizar opción ${option['key']}: ${optionUpdateResponse.error.message}')),
          );
          return;
        }
      }

      // Marcar el quiz como revisado
      final reviewedUpdateResponse = await supabase
          .from('quizzes')
          .update({'reviewed': true}).eq('id', widget.quizId!);

      if (reviewedUpdateResponse.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al marcar como revisado: ${reviewedUpdateResponse.error.message}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Quiz actualizado exitosamente y marcado como revisado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    }
  }

  Widget _buildCodeEditor() {
    return isEditingCode
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF46BC6E)),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                maxLines: null,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isEditingCode = false;
                  });
                },
                child: const Text("Aceptar"),
              ),
            ],
          )
        : Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HighlightView(
                  _codeController.text,
                  language: 'c',
                  theme: githubTheme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      isEditingCode = true;
                    });
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildOptionsEditor() {
    return Column(
      children: options.map((option) {
        TextEditingController optionController =
            TextEditingController(text: option['content']);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: optionController,
            decoration: InputDecoration(
              labelText: option['key'].toString().toUpperCase(),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF46BC6E)),
              ),
            ),
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              option['content'] = value;
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Previsualización del quiz",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _instructionController,
              decoration: InputDecoration(
                labelText: 'Instrucción',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF46BC6E)),
                ),
              ),
              style: const TextStyle(color: Colors.black),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            const Text(
              "Código:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildCodeEditor(),
            const SizedBox(height: 20),
            const Text(
              "Opciones:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildOptionsEditor(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateQuiz,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Aceptar",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
