import 'package:flutter/material.dart';
import 'package:programmingquizz/quiz_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  @override
  _QuizListPageState createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, List<Map<String, dynamic>>> quizzesByTopic = {};
  final int maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    fetchQuizzes();
  }

  Future<void> fetchQuizzes() async {
    try {
      // Obtener la lista de quizzes y sus temas, incluyendo `topic_id` y `title` del tema
      final quizzesResponse = await supabase
          .from('quizzes')
          .select('*, questions(*, topics(*))')
          .eq('reviewed', true);

      // Log de depuración para ver la estructura de datos

      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        return;
      }

      // Obtener los intentos del usuario para cada quiz
      final attemptsResponse = await supabase
          .from('user_progress')
          .select('quiz_id, score')
          .eq('user_id', user.id);

      print("Attempts response: $attemptsResponse");

      // Procesar los resultados
      Map<String, List<Map<String, dynamic>>> groupedQuizzes = {};

      print("antes de entrar al for");
      for (var quiz in quizzesResponse) {
        print("Dentro del for");
        print(quiz);
        // Verificar si los datos están correctamente estructurados antes de acceder
        if (quiz['questions'] == null ||
            quiz['questions'][0]['topics'] == null ||
            quiz['questions'][0]['topic_id'] == null ||
            quiz['questions'][0]['topics']['title'] == null) {
          print("Estructura inesperada para el quiz");
          continue; // Saltar este quiz si no tiene la estructura esperada
        }

        print("antes de entrar al if");
        final topicTitle = quiz['questions'][0]['topics']['title'] as String;
        final attemptsForQuiz = attemptsResponse
            .where((attempt) => attempt['quiz_id'] == quiz['id'] as int)
            .toList();
        final attemptsCount = attemptsForQuiz.length;
        final isCompleted =
            attemptsForQuiz.any((attempt) => attempt['score'] == true);

        // Crear una lista de quizzes agrupada por tema
        if (!groupedQuizzes.containsKey(topicTitle)) {
          groupedQuizzes[topicTitle] = [];
        }
        groupedQuizzes[topicTitle]!.add({
          ...quiz,
          'attempts': attemptsCount,
          'isCompleted': isCompleted,
        });
      }

      setState(() {
        quizzesByTopic = groupedQuizzes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar quizzes: $e')),
      );
    }
  }

  Color getCardColor(int attempts, bool isCompleted) {
    if (isCompleted) {
      return Colors.green[200]!;
    } else if (attempts >= maxAttempts) {
      return Colors.red[200]!;
    } else {
      return Colors.grey[300]!;
    }
  }

  Icon getStatusIcon(int attempts, bool isCompleted) {
    if (isCompleted) {
      return Icon(Icons.check_circle, color: Colors.green[700]);
    } else if (attempts >= maxAttempts) {
      return Icon(Icons.cancel, color: Colors.red[700]);
    } else {
      return Icon(Icons.hourglass_empty, color: Colors.grey[600]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Lista de Quizzes',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: quizzesByTopic.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: quizzesByTopic.entries.map((entry) {
                final topicTitle = entry.key;
                final quizzes = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          topicTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...quizzes.map((quiz) {
                        final attempts = quiz['attempts'] as int;
                        final isCompleted = quiz['isCompleted'] as bool;
                        final cardColor = getCardColor(attempts, isCompleted);
                        final statusIcon = getStatusIcon(attempts, isCompleted);

                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: statusIcon,
                            title: Text(
                              quiz['instruction'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Intentos: $attempts / $maxAttempts',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Barra de progreso visual para intentos
                                LinearProgressIndicator(
                                  value: attempts / maxAttempts,
                                  backgroundColor: Colors.grey[300],
                                  color: isCompleted
                                      ? Colors.green[700]
                                      : (attempts >= maxAttempts
                                          ? Colors.red[700]
                                          : Colors.amber[700]),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.black54),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizPage(
                                    quizId: quiz['id'].toString(),
                                  ),
                                ),
                              );

                              await fetchQuizzes();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
