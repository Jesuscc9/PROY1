import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vfcivewnqefnkyicklcn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmY2l2ZXducWVmbmt5aWNrbGNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYzMzk5MzIsImV4cCI6MjA0MTkxNTkzMn0.TomJW4YjfyqtnushHZsxuPvvCtGdsb1a5IkN7rQlEoI',
  );

  print('Supabase initialized');
}

class QuizPage extends StatefulWidget {
  final String? quizId;
  const QuizPage({super.key, required this.quizId});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  String code = '';
  String questionTitle = '';
  String correctOptionKey = '';
  String? selectedOptionKey;
  List<Map<String, dynamic>> options = [];
  bool isQuizCompleted = false;
  int attempts = 0;
  final int maxAttempts = 3;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.quizId != null) {
      fetchQuestionAndQuiz(widget.quizId!);
    } else {
      showErrorDialog("ID de quiz no proporcionado.");
    }
  }

  Future<void> fetchQuestionAndQuiz(String quizId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        showErrorDialog("No se encontró el usuario autenticado.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Contar el número de intentos previos
      final attemptsResponse = await supabase
          .from('user_progress')
          .select()
          .eq('user_id', user.id)
          .eq('quiz_id', quizId);

      setState(() {
        attempts = attemptsResponse.length;
        isQuizCompleted =
            attemptsResponse.any((record) => record['score'] == true);
      });

      if (attempts >= maxAttempts || isQuizCompleted) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch de pregunta y opciones
      final questionResponse = await supabase
          .from('questions')
          .select('id, quiz_id, correct_option_key, special')
          .eq('quiz_id', quizId)
          .limit(1)
          .single();

      setState(() {
        correctOptionKey = questionResponse['correct_option_key'];
      });

      final quizResponse = await supabase
          .from('quizzes')
          .select('id, code, instruction')
          .eq('id', quizId)
          .limit(1)
          .single();

      setState(() {
        code = quizResponse['code'];
        questionTitle = quizResponse['instruction'];
      });

      final optionsResponse = await supabase
          .from('options')
          .select('id, content, key')
          .eq('question_id', questionResponse['id']);

      setState(() {
        options = List<Map<String, dynamic>>.from(optionsResponse);
        isLoading = false;
      });
    } catch (e) {
      showErrorDialog("Error al obtener los datos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateProgress(bool isCorrect) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        showErrorDialog("No se encontró el usuario autenticado.");
        return;
      }

      // Insertar el nuevo intento en la base de datos
      await supabase.from('user_progress').insert({
        'user_id': user.id,
        'quiz_id': widget.quizId,
        'completed_at':
            isCorrect ? DateTime.now().toUtc().toIso8601String() : null,
        'score': isCorrect,
      });

      // Si la respuesta es correcta, muestra solo el diálogo de éxito y no regresa automáticamente
      if (isCorrect) {
        setState(() {
          isQuizCompleted = true;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("¡Respuesta Correcta!"),
              content: const Text("¡Bien hecho! Has completado el quiz."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Cierra el diálogo sin regresar a la lista
                  },
                  child: const Text("Aceptar"),
                ),
              ],
            );
          },
        );
      } else {
        // Incrementa los intentos en el estado local
        setState(() {
          attempts += 1;
        });

        // Si el usuario alcanza el límite de intentos, muestra un mensaje y regresa a la lista
        if (attempts >= maxAttempts) {
          setState(() {
            isQuizCompleted = true;
          });
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Intentos Agotados"),
                content: const Text(
                    "Lo siento, has alcanzado el límite de intentos incorrectos."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el diálogo
                      Navigator.of(context).pop(
                          true); // Regresa a la lista de quizzes con actualización
                    },
                    child: const Text("Aceptar"),
                  ),
                ],
              );
            },
          );
        } else {
          // Muestra un diálogo de respuesta incorrecta con los intentos restantes
          showResultDialog(isCorrect, maxAttempts - attempts);
        }
      }
    } catch (e) {
      showErrorDialog("Error al actualizar el progreso: $e");
    }
  }

  void showResultDialog(bool isCorrect, int remainingAttempts) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(isCorrect ? "¡Respuesta Correcta!" : "Respuesta Incorrecta"),
          content: Text(isCorrect
              ? "¡Bien hecho! Has seleccionado la respuesta correcta."
              : "Lo siento, la respuesta es incorrecta. Te quedan $remainingAttempts intento(s)."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Cargando Quiz"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (isQuizCompleted) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Resultado del Quiz"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isQuizCompleted && attempts < maxAttempts
                    ? "¡Felicidades! Has completado el quiz correctamente."
                    : "Has alcanzado el límite de intentos incorrectos.",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(true); // Regresa a la lista de quizzes y actualiza
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text(
                  "Ir a la lista de quizzes",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Prueba ${widget.quizId ?? "ID no válido"}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        // Solución: envuelve el contenido en SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pregunta:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              questionTitle.isEmpty ? 'Cargando pregunta...' : questionTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HighlightView(
                  code,
                  language: 'c',
                  theme: githubTheme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...options.map((option) => GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedOptionKey = option['key'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedOptionKey == option['key']
                          ? Colors.green.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: option['key'],
                          groupValue: selectedOptionKey,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            setState(() {
                              selectedOptionKey = value;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            option['content'],
                            style: TextStyle(
                              color: Colors.indigo[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedOptionKey == null || isQuizCompleted
                    ? null
                    : () {
                        bool isCorrect = selectedOptionKey == correctOptionKey;
                        if (!isQuizCompleted && attempts < maxAttempts) {
                          updateProgress(isCorrect);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Continuar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
