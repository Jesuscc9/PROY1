import 'package:flutter/material.dart';
import 'package:programmingquizz/login_screen.dart';

class ConfirmMailScreen extends StatelessWidget {
  const ConfirmMailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4F4F4),
              Color(0xFF003D00),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.4, 0.8],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/logo.gif', // Ruta de la imagen en los assets
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Confirma tu Correo',
                  style: TextStyle(
                    fontSize: 36,
                    color: Color(0xFF006633),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Te hemos enviado un enlace de confirmación a tu correo electrónico. '
                  'Revisa tu bandeja de entrada y no olvides checar también la carpeta de spam.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
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
                  'Ir a Iniciar Sesión',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
