import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _errorMessage;

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  void _validateUsername() {
    setState(() {
      final username = _usernameController.text.trim();
      if (username.length < 3) {
        _usernameError =
            'El nombre de usuario debe tener al menos 3 caracteres';
      } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        _usernameError =
            'El nombre de usuario solo puede contener letras, números y guiones bajos';
      } else {
        _usernameError = null;
      }
    });
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      final domainWhitelist = [
        'gmail.com',
        'yahoo.com',
        'outlook.com',
        'hotmail.com',
        'icloud.com',
        'uanl.edu.mx',
      ];

      const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
      final emailRegExp = RegExp(emailPattern);
      final domain = email.split('@').length > 1 ? email.split('@')[1] : '';

      if (email.isEmpty) {
        _emailError = 'Ingresa un correo electrónico válido';
      } else if (!emailRegExp.hasMatch(email)) {
        _emailError = 'El formato de correo es incorrecto';
      } else if (!domainWhitelist.contains(domain)) {
        _emailError = 'Este dominio no es permitido';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePasswords() {
    setState(() {
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      _passwordError = password.length < 6
          ? 'La contraseña debe tener al menos 6 caracteres'
          : null;
      _confirmPasswordError =
          password != confirmPassword ? 'Las contraseñas no coinciden' : null;
    });
  }

  Future<void> _register() async {
    _validateUsername();
    _validateEmail();
    _validatePasswords();

    if (_usernameError != null ||
        _passwordError != null ||
        _emailError != null ||
        _confirmPasswordError != null) {
      return; // Detener si hay errores
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabaseClient.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(),
        },
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registro exitoso. Revisa tu correo para verificar tu cuenta.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _isLoading = false;
        });

        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushReplacementNamed(context, '/confirm-mail');
      } else {
        setState(() {
          _errorMessage = 'Error al registrar usuario';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Center(
                  child: Text(
                    'Regístrate',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D00),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Correo electrónico',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextField(
                  controller: _emailController,
                  onChanged: (value) => _validateEmail(),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'ejemplo@dominio.com',
                    hintStyle: const TextStyle(color: Colors.grey),
                    errorText: _emailError,
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 18.0),
                  ),
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nombre de usuario',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextField(
                  controller: _usernameController,
                  onChanged: (value) => _validateUsername(),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Usuario123',
                    hintStyle: const TextStyle(color: Colors.grey),
                    errorText: _usernameError,
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 18.0),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  onChanged: (value) => _validatePasswords(),
                  cursorColor: Colors.black,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: '******',
                    hintStyle: const TextStyle(color: Colors.grey),
                    errorText: _passwordError,
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
                const SizedBox(height: 20),
                const Text(
                  'Confirmar contraseña',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextField(
                  controller: _confirmPasswordController,
                  onChanged: (value) => _validatePasswords(),
                  cursorColor: Colors.black,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '******',
                    hintStyle: const TextStyle(color: Colors.grey),
                    errorText: _confirmPasswordError,
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 18.0),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                const SizedBox(height: 36),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 18),
                        backgroundColor: const Color(0xFF46BC6E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    child: Text(
                      _isLoading ? 'Cargando...' : 'Registrar',
                      style: const TextStyle(color: Colors.white),
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
