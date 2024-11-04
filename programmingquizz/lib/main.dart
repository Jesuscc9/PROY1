import 'package:flutter/material.dart';
import 'package:programmingquizz/confirm_mail_screen.dart';
import 'package:programmingquizz/quizzes_list_screen.dart';
import 'package:programmingquizz/quizzes_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:programmingquizz/login_screen.dart'; // Asegúrate de tener esta pantalla creada e importada
import 'package:programmingquizz/register_screen.dart'; // Asegúrate de tener esta pantalla creada e importada
import 'package:programmingquizz/quiz_page.dart'; // Asegúrate de tener esta pantalla creada e importada
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase
  await Supabase.initialize(
    url:
        'https://vfcivewnqefnkyicklcn.supabase.co', // Reemplaza con tu URL de Supabase
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmY2l2ZXducWVmbmt5aWNrbGNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYzMzk5MzIsImV4cCI6MjA0MTkxNTkzMn0.TomJW4YjfyqtnushHZsxuPvvCtGdsb1a5IkN7rQlEoI', // Reemplaza con tu anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIME App',
      theme: ThemeData(
        primaryColor: const Color(0xFF006135), // Color primario FIME
        scaffoldBackgroundColor: const Color(0xFFF4F4F4), // Color de fondo
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFF006135)), // Texto contrastante
        ),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: const Color(0xFFFFBF00)),
      ),
      home: const AuthRedirect(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/menu': (context) => const QuizzesMenuScreen(),
        '/confirm-mail': (context) => const ConfirmMailScreen(),
        '/quizzes-list': (context) => const QuizListPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/quiz') {
          // Extraer el parámetro `quizId` de settings.arguments
          final quizId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => QuizPage(quizId: quizId ?? 'Default ID'),
          );
        }
        // Si la ruta no es '/quiz', redirigir al home
        return MaterialPageRoute(
          builder: (context) => const QuizzesMenuScreen(),
        );
      },
    );
  }
}

// Este widget redirige según el estado de autenticación
class AuthRedirect extends StatelessWidget {
  const AuthRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Si el usuario ya está logueado, redirige a QuizzPage
      return const QuizzesMenuScreen();
    } else {
      // Si no está logueado, redirige al login
      return const MainPage();
    }
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4F4F4),
              Color(0xFF003D00),
            ], // Degradado FIME
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.4, 0.8],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Aquí se agregará el logo de FIME
              Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/logo.gif', // Ruta de la imagen en los assets
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'FIMEQUIZZ', // Título grande
                  style: TextStyle(
                    fontSize: 46,
                    color: Color(0xFF006633),
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Facultad de Ingeniería Mecánica y Eléctrica',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '"VIVE LA FIME!"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontStyle: FontStyle.italic, // Lema en cursiva
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF46BC6E),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen()), // Redirige al login
                  );
                },
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF006135),
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const RegisterScreen()), // Redirige al registro
                  );
                },
                child: const Text(
                  'Registrarse',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              // TextButton(
              //   onPressed: () async {
              //     const url = 'https://www.fime.uanl.mx/';
              //     if (await canLaunchUrl(url as Uri)) {
              //       await launchUrl(url as Uri);
              //     } else {
              //       throw 'No se puede abrir el enlace $url';
              //     }
              //   },
              //   child: const Text(
              //     'Conoce más sobre FIME',
              //     style: TextStyle(
              //       fontSize: 16,
              //       color: Colors.white,
              //       decoration: TextDecoration.underline,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
