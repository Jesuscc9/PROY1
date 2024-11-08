import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'quizzes_list_screen.dart';

class TopicLearningScreen extends StatelessWidget {
  final String topicTitle;

  const TopicLearningScreen({super.key, required this.topicTitle});

  // Genera contenido detallado de aprendizaje para cada tema
  Map<String, String> _generateLearningContent(String topic) {
    switch (topic) {
      case 'Asignaciones y operaciones aritméticas':
        return {
          'content': '''
Los operadores son símbolos que permiten realizar operaciones matemáticas, lógicas y de asignación en un programa. Son una parte fundamental de la programación y se dividen en varias categorías:

- **Operadores aritméticos**: Realizan operaciones matemáticas básicas, como suma, resta, multiplicación y división.
- **Operadores de comparación**: Comparan dos valores y devuelven un valor booleano (verdadero o falso).
- **Operadores lógicos**: Permiten construir expresiones lógicas complejas combinando valores booleanos.

A continuación, se muestra un ejemplo de operadores básicos en C:
          ''',
          'code': '''
#include <stdio.h>

int main() {
    int a = 10, b = 20;
    
    // Operadores aritméticos
    int suma = a + b;
    int resta = a - b;
    
    // Operadores de comparación
    if (a > b) {
        printf("a es mayor que b\\n");
    }
    
    // Operadores lógicos
    if (a < b && b > 0) {
        printf("a es menor que b y b es positivo\\n");
    }
    
    return 0;
}
          '''
        };
      case 'Estructuras condicionales':
        return {
          'content': '''
Las estructuras condicionales permiten que el programa tome decisiones basadas en ciertas condiciones. Estas estructuras son esenciales para controlar el flujo de un programa y son la base de la lógica de control.

Tipos de estructuras condicionales en C:
          
- **if**: Ejecuta un bloque de código si se cumple una condición específica.
- **else**: Proporciona un bloque alternativo que se ejecuta si la condición en el `if` es falsa.
- **else if**: Permite evaluar múltiples condiciones en una secuencia.
- **switch**: Es útil para comparar el valor de una variable con múltiples casos posibles.

Ejemplo de estructuras condicionales en C:
          ''',
          'code': '''
#include <stdio.h>

int main() {
    int numero = 5;
    
    if (numero > 0) {
        printf("El número es positivo\\n");
    } else if (numero < 0) {
        printf("El número es negativo\\n");
    } else {
        printf("El número es cero\\n");
    }
    
    // Uso de switch
    switch (numero) {
        case 1:
            printf("El número es uno\\n");
            break;
        case 5:
            printf("El número es cinco\\n");
            break;
        default:
            printf("El número no es ni uno ni cinco\\n");
    }
    
    return 0;
}
          '''
        };
      case 'Estructuras condicionales anidadas':
        return {
          'content': '''
Las estructuras en programación permiten agrupar variables de diferentes tipos en un solo bloque de datos, lo que facilita la gestión de objetos complejos. En C, las estructuras son fundamentales para la programación orientada a datos y la organización de información.

Definir una estructura:
          
- **struct**: Es una palabra clave que permite definir una estructura en C. Dentro de `struct`, se pueden definir múltiples campos de diferentes tipos.
          
Ejemplo de estructura en C:
          ''',
          'code': '''
#include <stdio.h>

struct Persona {
    char nombre[50];
    int edad;
    float altura;
};

int main() {
    struct Persona persona1 = {"Juan", 25, 1.75};
    
    printf("Nombre: %s\\n", persona1.nombre);
    printf("Edad: %d\\n", persona1.edad);
    printf("Altura: %.2f\\n", persona1.altura);
    
    return 0;
}
          '''
        };
      case 'Arreglos':
        return {
          'content': '''
Los arrays son una estructura de datos que permite almacenar múltiples elementos del mismo tipo en una secuencia continua en memoria. En C, los arrays se utilizan para almacenar datos de forma eficiente y acceder a ellos mediante índices.

Características de los arrays:
          
- **Declaración**: Los arrays se declaran especificando el tipo y el tamaño, como en `int numeros[5];`.
- **Acceso**: Cada elemento de un array se puede acceder usando un índice, comenzando desde 0.

Ejemplo de array en C:
          ''',
          'code': '''
#include <stdio.h>

int main() {
    int numeros[5] = {10, 20, 30, 40, 50};
    
    for (int i = 0; i < 5; i++) {
        printf("Elemento en indice %d: %d\\n", i, numeros[i]);
    }
    
    return 0;
}
          '''
        };
      default:
        return {
          'content': '''
Este tema está en desarrollo y aún no se ha proporcionado información específica. Por favor, vuelve más tarde para obtener más detalles.
          ''',
          'code': '// Información no disponible'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentData = _generateLearningContent(topicTitle);
    final content = contentData['content']!;
    final codeSnippet = contentData['code']!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          topicTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006135),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ejemplo de código:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              HighlightView(
                codeSnippet,
                language: 'c',
                theme: githubTheme,
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QuizzesListScreen(topicTitle: topicTitle),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 18),
                    backgroundColor: const Color(0xFF46BC6E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text(
                    '¡Estoy listo, llévame al quiz!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
