import { useState } from 'react'
import { useQuery } from 'react-query'
import { Link } from 'react-router-dom'
import { Skeleton } from '../../components/Skeleton'
import { supabase } from '../../services/supabase'

// SIMPLE_CONDITIONALS (222)
// ASSIGNMENT_AND_ARITHMETIC_OPERATIONS (105)
// BASIC_LOOPS (83)
// undefined (3)
// BASIC_ARRAYS (2)
// NESTED_CONDITIONALS (1)

const TOPICS_TITLES_ENUM = {
  ASSIGNMENT_AND_ARITHMETIC_OPERATIONS: 'Asignación y operaciones aritméticas',
  SIMPLE_CONDITIONALS: 'Condicionales simples',
  NESTED_CONDITIONALS: 'Condicionales anidados',
  BASIC_LOOPS: 'Loops básicos',
  BASIC_ARRAYS: 'Arreglos básicos',
  undefined: 'Sin clasificar'
}

export default function Quizzes() {
  const [quizesParams] = useState({
    from: 0,
    to: 500
  })

  const { isLoading, error, data } = useQuery(
    ['quizzes', quizesParams],
    async (params) => {
      const { from, to } = params?.queryKey[1] as { from: number; to: number }
      const { data, error } = await supabase
        .from('quizzes')
        .select('*, question:questions (*, topic:topics (*))')
        .range(from, to)
        .order('id', { ascending: true })

      if (error) throw new Error(error.message)
      return data
    }
  )

  if (isLoading) return <Skeleton />
  if (error) return <div>An error has occurred</div>

  const filteredQuizzes = Object.groupBy(data, (quiz) => {
    return quiz.question?.[0]?.topic.key
  })

  console.log({ filteredQuizzes })

  return (
    <div className='container'>
      <br />
      <h1>Pruebas</h1>
      {Object.keys(filteredQuizzes).map((topic) => (
        <details key={topic}>
          <summary htmlFor=''>
            {TOPICS_TITLES_ENUM[topic]} ({filteredQuizzes?.[topic].length})
          </summary>

          {filteredQuizzes?.[topic]?.map((quiz, i) => (
            <div key={quiz.id}>
              <div key={quiz.id}>
                <Link className='secondary' to={`/quiz/${quiz.id}`}>
                  {i + 1} - {quiz.instruction}
                  {quiz.reviewed && ' - ✅'}
                </Link>
              </div>
              <br />
            </div>
          ))}
        </details>
      ))}
    </div>
  )
}
