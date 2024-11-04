import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:programmingquizz/qr_scanner_screen.dart';

class QuizzesMenuScreen extends StatefulWidget {
  const QuizzesMenuScreen({super.key});

  @override
  _QuizzesMenuScreenState createState() => _QuizzesMenuScreenState();
}

class _QuizzesMenuScreenState extends State<QuizzesMenuScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, double> topicCompletionData = {};
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

      // Filtrar quizzes con reviewed = true
      final quizzesResponse = await supabase
          .from('quizzes')
          .select('id, questions(id, topics(title))') // Aquí obtenemos el title
          .eq('reviewed', true);

      final Map<String, List<int>> quizzesByTopic = {};
      for (var quiz in quizzesResponse) {
        final topicTitle = quiz['questions'][0]['topics']['title']
            as String; // Usamos title aquí
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

      final Map<String, double> completionData = {};
      quizzesByTopic.forEach((topic, quizIds) {
        final totalQuizzes = quizIds.length;
        final completedQuizzes =
            quizIds.where((id) => completedQuizIds.contains(id)).length;
        completionData[topic] = (completedQuizzes / totalQuizzes) * 100;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Menú',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF006135),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildMenuOption(
                    icon: Icons.edit,
                    title: 'Pruebas',
                    onTap: () async {
                      await Navigator.pushNamed(context, '/quizzes-list');
                      _fetchTopicCompletionData();
                    },
                  ),
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Progreso de Completado por Tema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: topicCompletionData.length,
                    itemBuilder: (context, index) {
                      final topic = topicCompletionData.keys.elementAt(index);
                      final completionPercentage = topicCompletionData[topic]!;

                      return Padding(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    topic, // Muestra el título del tema
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF006135),
                                    ),
                                  ),
                                  Text(
                                    '${completionPercentage.toStringAsFixed(1)}%',
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
                                  value: completionPercentage / 100,
                                  backgroundColor: Colors.grey[300],
                                  color: const Color(0xFF46BC6E),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006135),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: Colors.white, size: 60),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const QrScannerScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ESCANEA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF46BC6E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildMenuOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF006135),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006135),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final supabaseClient = Supabase.instance.client;

    try {
      await supabaseClient.auth.signOut();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cerrar sesión'),
        ),
      );
    }
  }
}
