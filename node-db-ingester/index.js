// Cargar las variables del archivo .env usando import
import 'dotenv/config' // Usamos dotenv para cargar las variables de entorno

// ASSIGNMENT_AND_ARITHMETIC_OPERATIONS, SIMPLE_CONDITIONALS, NESTED_CONDITIONALS, BASIC_LOOPS, BASIC_ARRAYS
const TOPICS_IDS_ENUM = {
  ASSIGNMENT_AND_ARITHMETIC_OPERATIONS: 1,
  SIMPLE_CONDITIONALS: 2,
  NESTED_CONDITIONALS: 3,
  BASIC_LOOPS: 4,
  BASIC_ARRAYS: 5
}

// Importar las bibliotecas necesarias
import { createClient } from '@supabase/supabase-js'

// Acceder a las variables de entorno desde .env
const SUPABASE_URL = process.env.SUPABASE_URL
const SUPABASE_SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE

// Crear cliente de Supabase usando las variables de entorno
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE)

// Función para hacer el fetch y guardar en las tablas
async function fetchAndSaveData() {
  try {
    // Hacer el fetch al endpoint
    const response = await fetch(
      'https://code-challenges-generator-api.jesus-cervantes0801.workers.dev/'
    )
    const data = await response.json()

    // Mostrar los datos para verificar (opcional)
    console.log('Datos recibidos:', data)

    // Primero insertar el quiz en la tabla quizzes
    const { data: quizData, error: quizError } = await supabase
      .from('quizzes')
      .insert([
        {
          code: data.code, // El código C devuelto por la API
          instruction: data.instruction, // La instrucción del JSON
          correct_code: data.correct_code // El código correcto del JSON
        }
      ])
      .select()

    if (quizError) {
      throw quizError
    }

    const quizId = quizData[0].id // Obtener el ID del quiz insertado

    console.log({ topic_id: TOPICS_IDS_ENUM[data.topic] })

    // Insertar la pregunta en la tabla questions
    const { data: questionData, error: questionError } = await supabase
      .from('questions')
      .insert([
        {
          quiz_id: quizId, // ID del quiz insertado
          correct_option_key: data.question.correct_option_key, // ID de la opción correcta
          correct_option_explanation: data.correct_option_explanation, // Explicación de la opción correcta.
          topic_id: TOPICS_IDS_ENUM[data.topic] // Tema de la pregunta
        }
      ])
      .select()

    if (questionError) {
      throw questionError
    }

    const questionId = questionData[0].id // Obtener el ID de la pregunta insertada

    // Insertar opciones en la tabla options
    const options = data.question.options.map((option) => ({
      question_id: questionId, // ID de la pregunta insertada
      key: option.key, // Clave de la opción (ej. 'a', 'b', 'c', 'd')
      content: option.content // Contenido de la opción
    }))

    const { error: optionsError } = await supabase
      .from('options')
      .insert(options)

    if (optionsError) {
      throw optionsError
    }

    console.log('Datos guardados correctamente en las tablas.')
  } catch (error) {
    console.error('Error al guardar los datos:', error.message)
  }

  fetchAndSaveData()
}

// Ejecutar la función para realizar el fetch y guardar los datos
fetchAndSaveData()
