import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _emailError = 'Ingresa un correo electrónico válido';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        _passwordError = 'Ingresa una contraseña';
      } else if (password.length < 6) {
        _passwordError = 'La contraseña debe tener al menos 6 caracteres';
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _signIn() async {
    _validateEmail();
    _validatePassword();

    if (_emailError != null || _passwordError != null) {
      return; // Detener si hay errores
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.session != null) {
        Navigator.pushReplacementNamed(context, '/menu');
      } else {
        setState(() {
          _errorMessage = 'Error al iniciar sesión';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains('Email not confirmed')) {
          _errorMessage = 'Correo electrónico no confirmado.';
        } else if (e.message.contains('Invalid login credentials')) {
          _errorMessage = 'Contraseña o correo incorrectos.';
        } else if (e.message.contains('missing email or phone')) {
          _errorMessage = 'Ingresa tu correo electrónico y contraseña';
        } else if (e.message.contains('missing password')) {
          _errorMessage = 'Ingresa una contraseña';
        } else {
          _errorMessage = e.message;
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () async {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D00),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  onChanged: (value) => _validateEmail(),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Correo Electrónico',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Color(0xFF004D00)),
                    ),
                    errorText: _emailError,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 18.0),
                  ),
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  onChanged: (value) => _validatePassword(),
                  cursorColor: Colors.black,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Color(0xFF004D00)),
                    ),
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 18.0),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 10),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_errorMessage == null) const SizedBox(height: 36),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 18),
                      backgroundColor: const Color(0xFF46BC6E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text(
                      _isLoading ? 'Cargando...' : 'Iniciar Sesión',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      '¿No tienes cuenta? Regístrate aquí',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
