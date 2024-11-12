import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

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
  bool isEditingCode = false;
  List<Map<String, dynamic>> options = [];
  String correctOptionKey = 'A';
  bool isLoading = true;
  int? quizId; // Variable para almacenar el quizId, sea pasado o generado
  int? topicId; // Variable para almacenar el topicId
  String? topicTitle;

  @override
  void initState() {
    super.initState();
    quizId = widget.quizId; // Asignar el quizId si se pasó
    if (quizId == null) {
      _generateRandomQuiz();
    } else {
      _fetchQuizData(quizId!);
    }
  }

  Future<void> _generateRandomQuiz() async {
    setState(() {
      isLoading = true; // Mostrar el indicador de carga
    });
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
      quizId = randomQuiz['id']; // Almacena el quizId generado aleatoriamente
      print("Generated quiz ID: $quizId");

      // Check if random quiz has a question
      final questionResponse = await supabase
          .from('questions')
          .select('id')
          .eq('quiz_id', quizId as Object)
          .limit(1)
          .maybeSingle();

      if (questionResponse?['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El quiz seleccionado no tiene una pregunta')),
        );
        _initializeEmptyFields();
        return;
      }

      // Check if random quiz has 4 options
      final optionsResponse = await supabase
          .from('options')
          .select('id, content, key')
          .eq('question_id', questionResponse?['id']);

      if (optionsResponse.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El quiz seleccionado no tiene 4 opciones')),
        );
        _initializeEmptyFields();
        return;
      }

      // Load the selected quiz data
      await _fetchQuizData(quizId!);
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

      // Fetch correct option explanation from questions table
      final questionResponse = await supabase
          .from('questions')
          .select('id, correct_option_explanation, topic_id, topics (*)')
          .eq('quiz_id', quizId)
          .limit(1)
          .maybeSingle();

      topicTitle = questionResponse?['topics']['title'];

      // Fetch options for the quiz
      final optionsResponse = await supabase
          .from('options')
          .select('id, content, key')
          .eq('question_id', questionResponse?['id']);

      final List<Map<String, dynamic>> optionsData =
          List<Map<String, dynamic>>.from(optionsResponse ?? []);

      topicId = questionResponse?['topic_id'];

      setState(() {
        _codeController =
            TextEditingController(text: quizResponse?['code'] ?? '');
        _instructionController =
            TextEditingController(text: quizResponse?['instruction'] ?? '');
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
      options = [];
      isLoading = false;
    });
  }

  Future<void> _updateQuiz() async {
    // Asegúrate de que quizId no sea nulo antes de proceder
    if (quizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz ID no puede ser nulo')),
      );
      return;
    }

    try {
      final payload = {
        "quiz_id": quizId,
        "code": _codeController.text,
        "instruction": _instructionController.text,
        "correct_code": _codeController.text,
        "correct_option_key": correctOptionKey,
        "topic_id": topicId,
        "options": options
            .map((option) =>
                {"key": option['key'], "content": option['content']})
            .toList(),
      };

      final data = await supabase.functions
          .invoke('updateQuizData', body: payload, method: HttpMethod.post);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz agregado exitosamente.')),
      );
      Navigator.of(context)
          .pushReplacementNamed('/menu'); // Redirigir a MenuPage
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
            const SizedBox(height: 10),
            Text(
              "Tema: ${topicTitle ?? 'No asignado'}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
            Column(
              children: [
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateRandomQuiz,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Generar otra vez",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
