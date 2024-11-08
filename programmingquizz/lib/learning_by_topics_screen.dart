import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'topic_learning_screen.dart'; // Asegúrate de importar la pantalla para aprender sobre el tema

class LearningByTopicsScreen extends StatefulWidget {
  const LearningByTopicsScreen({super.key});

  @override
  _LearningByTopicsScreenState createState() => _LearningByTopicsScreenState();
}

class _LearningByTopicsScreenState extends State<LearningByTopicsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<String> topics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase
          .from('topics')
          .select('title')
          .order('title', ascending: true);

      setState(() {
        topics = List<String>.from(response.map((e) => e['title']));
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar temas: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aprender por Tema',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006135),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TopicLearningScreen(topicTitle: topic),
                      ),
                    );
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
                      child: Text(
                        topic,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF006135),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
