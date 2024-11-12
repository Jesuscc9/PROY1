import 'package:flutter/material.dart';
import 'package:programmingquizz/quiz_page.dart';
import 'package:programmingquizz/preview_quiz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizzesListScreen extends StatefulWidget {
  final String topicTitle;

  const QuizzesListScreen({super.key, required this.topicTitle});

  @override
  _QuizzesListScreenState createState() => _QuizzesListScreenState();
}

class _QuizzesListScreenState extends State<QuizzesListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> quizzes = [];
  final int maxAttempts = 3;
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchQuizzesForTopic();
  }

  Future<void> _fetchUserInfo() async {
    final user = supabase.auth.currentUser;
    if (user != null && user.email == 'adminfimequiz@gmail.com') {
      setState(() {
        isAdmin = true;
      });
    }
  }

  Future<void> _fetchQuizzesForTopic() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        return;
      }

      final quizzesResponse = await supabase
          .from('quizzes')
          .select('id, code, instruction, correct_code, questions(topic_id)')
          .eq('reviewed', true);

      final List<Map<String, dynamic>> quizzesForTopic = [];
      for (var quiz in quizzesResponse) {
        final topic = quiz['questions'][0]['topic_id'];
        final topicResponse = await supabase
            .from('topics')
            .select('title')
            .eq('id', topic)
            .single();

        if (topicResponse['title'] == widget.topicTitle) {
          quizzesForTopic.add(quiz);
        }
      }

      final attemptsResponse = await supabase
          .from('user_progress')
          .select('quiz_id, score')
          .eq('user_id', user.id);

      final completedQuizIds = attemptsResponse
          .where((attempt) => attempt['score'] == true)
          .map((attempt) => attempt['quiz_id'])
          .toSet();

      final updatedQuizzes = quizzesForTopic.map((quiz) {
        final attemptsCount = attemptsResponse
            .where((attempt) => attempt['quiz_id'] == quiz['id'])
            .length;
        final isCompleted = completedQuizIds.contains(quiz['id']);

        return {
          ...quiz,
          'attempts': attemptsCount,
          'isCompleted': isCompleted,
        };
      }).toList();

      if (mounted) {
        setState(() {
          quizzes = updatedQuizzes;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar quizzes: $e')),
        );
      }
    }
  }

  Icon getStatusIcon(int attempts, bool isCompleted) {
    if (isAdmin) {
      return const Icon(Icons.edit, color: Color(0xFF006135));
    } else if (isCompleted) {
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
        title: Text(
          widget.topicTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                final attempts = quiz['attempts'] as int;
                final isCompleted = quiz['isCompleted'] as bool;
                final statusIcon = getStatusIcon(attempts, isCompleted);

                return Card(
                  color: Colors
                      .white, // Conservamos el fondo blanco predeterminado
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: statusIcon,
                    title: Text(
                      quiz['instruction'] ?? 'Título no disponible',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isAdmin && !isCompleted && attempts < maxAttempts)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Intentos restantes: ${maxAttempts - attempts}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        if (!isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: LinearProgressIndicator(
                              value: attempts / maxAttempts,
                              backgroundColor: Colors.grey[300],
                              color: isCompleted
                                  ? Colors.green[700]
                                  : (attempts >= maxAttempts
                                      ? Colors.red[700]
                                      : Colors.amber[700]),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.black54),
                    onTap: () async {
                      if (isAdmin) {
                        // Navegar a la pantalla de edición para el administrador
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PreviewQuiz(quizId: quiz['id']),
                          ),
                        );
                      } else {
                        // Navegar a la página de quiz normal para usuarios no administradores
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizPage(
                              quizId: quiz['id'].toString(),
                            ),
                          ),
                        );
                      }

                      if (mounted) {
                        _fetchQuizzesForTopic();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
