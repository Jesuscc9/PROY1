import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quizzes_list_screen.dart'; // Asegúrate de importar la pantalla de quizzes específicos

class QuizzesByTopicScreen extends StatefulWidget {
  const QuizzesByTopicScreen({super.key});

  @override
  _QuizzesByTopicScreenState createState() => _QuizzesByTopicScreenState();
}

class _QuizzesByTopicScreenState extends State<QuizzesByTopicScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, Map<String, int>> topicCompletionData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopicCompletionData();
  }

  Future<void> _fetchTopicCompletionData() async {
    setState(() {
      isLoading = true;
    });

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
          .select('id, questions(id, topics(title))')
          .eq('reviewed', true);

      final Map<String, List<int>> quizzesByTopic = {};
      for (var quiz in quizzesResponse) {
        final topicTitle = quiz['questions'][0]['topics']['title'] as String;
        if (!quizzesByTopic.containsKey(topicTitle)) {
          quizzesByTopic[topicTitle] = [];
        }
        quizzesByTopic[topicTitle]!.add(quiz['id'] as int);
      }

      final progressResponse = await supabase
          .from('user_progress')
          .select('quiz_id')
          .eq('user_id', user.id)
          .eq('score', true);

      final completedQuizIds =
          progressResponse.map((e) => e['quiz_id']).toSet();

      final Map<String, Map<String, int>> completionData = {};
      quizzesByTopic.forEach((topic, quizIds) {
        final totalQuizzes = quizIds.length;
        final completedQuizzes =
            quizIds.where((id) => completedQuizIds.contains(id)).length;
        completionData[topic] = {
          'completed': completedQuizzes,
          'total': totalQuizzes,
        };
      });

      setState(() {
        topicCompletionData = completionData;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de completado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progreso por tema',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006135),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              itemCount: topicCompletionData.length,
              itemBuilder: (context, index) {
                final topic = topicCompletionData.keys.elementAt(index);
                final completedQuizzes =
                    topicCompletionData[topic]!['completed']!;
                final totalQuizzes = topicCompletionData[topic]!['total']!;

                return GestureDetector(
                  onTap: () async {
                    // Navegar a la pantalla de quizzes específicos y esperar hasta que regrese
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QuizzesListScreen(topicTitle: topic),
                      ),
                    );

                    // Volver a llamar a _fetchTopicCompletionData al regresar
                    _fetchTopicCompletionData();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                topic,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF006135),
                                ),
                              ),
                              Text(
                                '$completedQuizzes/$totalQuizzes',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF46BC6E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: completedQuizzes / totalQuizzes,
                              backgroundColor: Colors.grey[300],
                              color: const Color(0xFF46BC6E),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
