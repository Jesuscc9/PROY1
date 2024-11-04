import { Link, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from 'react-query'
import { useState, useEffect } from 'react'
import { Skeleton } from '../../components/Skeleton'
import { supabase } from '../../services/supabase'
import { ToastContainer, toast } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'

const TOPICS_TITLES_ENUM = {
  ASSIGNMENT_AND_ARITHMETIC_OPERATIONS: 'Asignación y operaciones aritméticas',
  SIMPLE_CONDITIONALS: 'Condicionales simples',
  NESTED_CONDITIONALS: 'Condicionales anidados',
  BASIC_LOOPS: 'Loops básicos',
  BASIC_ARRAYS: 'Arreglos básicos'
}

export default function QuizDetail() {
  const { id } = useParams()
  const queryClient = useQueryClient()

  const { isLoading, error, data } = useQuery(['quiz', id], async () => {
    const { data, error } = await supabase
      .from('quizzes')
      .select('*, questions(*, options(*), topic:topics(*))')
      .eq('id', id)
      .single()

    if (error) {
      throw new Error(error.message)
    }

    return data
  })

  const [formData, setFormData] = useState({
    instruction: '',
    code: '',
    correctOptionExplanation: '',
    correctOptionKey: '',
    options: [],
    reviewed: false
  })

  const [initialData, setInitialData] = useState(null)

  useEffect(() => {
    if (data) {
      const sortedOptions =
        data.questions?.[0]?.options
          .map((opt) => ({
            id: opt.id,
            key: opt.key,
            content: opt.content
          }))
          .sort((a, b) => a.id - b.id) || []

      const initialFormData = {
        instruction: data.instruction || '',
        code: data.code || '',
        correctOptionExplanation:
          data.questions?.[0]?.correct_option_explanation || '',
        correctOptionKey: data.questions?.[0]?.correct_option_key || '',
        options: sortedOptions,
        reviewed: data.reviewed
      }

      setFormData(initialFormData)
      setInitialData(initialFormData)
    }
  }, [data])

  const updateMutation = useMutation(
    async (updatedData) => {
      const updates = {}

      // Actualizar datos en la tabla 'quizzes'
      if (updatedData.instruction !== initialData.instruction) {
        updates.instruction = updatedData.instruction
      }
      if (updatedData.code !== initialData.code) {
        updates.code = updatedData.code
      }
      if (updatedData.reviewed !== initialData.reviewed) {
        updates.reviewed = updatedData.reviewed
      }

      if (Object.keys(updates).length > 0) {
        const { error } = await supabase
          .from('quizzes')
          .update(updates)
          .eq('id', id)

        if (error) {
          throw new Error(error.message)
        }
      }

      // Actualizar correct_option_key y correct_option_explanation en la tabla 'questions'
      const questionId = data.questions[0].id // ID de la primera pregunta
      const questionUpdates = {}

      if (updatedData.correctOptionKey !== initialData.correctOptionKey) {
        questionUpdates.correct_option_key = updatedData.correctOptionKey
      }
      if (
        updatedData.correctOptionExplanation !==
        initialData.correctOptionExplanation
      ) {
        questionUpdates.correct_option_explanation =
          updatedData.correctOptionExplanation
      }

      if (Object.keys(questionUpdates).length > 0) {
        const { error } = await supabase
          .from('questions')
          .update(questionUpdates)
          .eq('id', questionId)

        if (error) {
          throw new Error(error.message)
        }
      }

      // Actualizar las opciones en la tabla 'options'
      for (const option of updatedData.options) {
        const initialOption = initialData.options.find(
          (opt) => opt.id === option.id
        )
        if (option.content !== initialOption.content) {
          const optionUpdate = await supabase
            .from('options')
            .update({ content: option.content })
            .eq('id', option.id)

          if (optionUpdate.error) {
            throw new Error(optionUpdate.error.message)
          }
        }
      }
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['quiz', id])
        toast.success('Actualización exitosa')
      },
      onError: (error) => {
        toast.error(`Error al actualizar: ${error.message}`)
      }
    }
  )

  const handleChange = (e) => {
    const { name, value } = e.target

    if (name === 'reviewed') {
      setFormData((prevData) => ({
        ...prevData,
        [name]: !prevData.reviewed
      }))
      return
    } else {
      setFormData((prevData) => ({
        ...prevData,
        [name]: value
      }))
    }
  }

  const handleOptionChange = (id, value) => {
    setFormData((prevData) => ({
      ...prevData,
      options: prevData.options.map((opt) =>
        opt.id === id ? { ...opt, content: value } : opt
      )
    }))
  }

  const isFormModified =
    JSON.stringify(formData) !== JSON.stringify(initialData)

  const handleSave = () => {
    if (isFormModified) {
      console.log({ formData })
      updateMutation.mutate(formData)
    }
  }

  const handleKeyDown = (e) => {
    // Permitir salto de línea en el textarea
    if (e.key === 'Enter' && isFormModified) {
      if (e.target.tagName === 'TEXTAREA') {
        return // No prevenir la acción en el textarea
      }
      e.preventDefault() // Prevenir envío en otros campos
      handleSave()
    }
  }

  if (isLoading) return <Skeleton />
  if (error) return <div>An error has occurred</div>

  return (
    <div className='container'>
      <br />
      <div>
        <Link to='/'>Regresar</Link>
      </div>
      <br />
      <h6 style={{ marginBottom: 4 }}>#{data.id}</h6>
      <fieldset>
        <label>
          <input
            name='reviewed'
            type='checkbox'
            role='switch'
            checked={formData.reviewed}
            onChange={handleChange}
          />
          Revisado
        </label>
      </fieldset>

      <h4>Tema: {TOPICS_TITLES_ENUM[data.questions[0].topic.key]}</h4>
      <label>Instrucción:</label>
      <input
        type='text'
        name='instruction'
        value={formData.instruction}
        onChange={handleChange}
        onKeyDown={handleKeyDown}
        placeholder='Instrucción'
        style={{ width: '100%', marginBottom: '8px' }}
      />

      <div style={{ display: 'flex', columnGap: '1rem' }}>
        <div
          style={{
            width: '50%'
          }}
        >
          <label>Código:</label>
          <textarea
            name='code'
            value={formData.code}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
            placeholder='Código'
            style={{ width: '100%', height: '350px', marginBottom: '8px' }}
          />
        </div>

        <div
          style={{
            width: '50%'
          }}
        >
          <label>Opciones:</label>
          {formData.options.map((option) => {
            const isCorrect = option.key === formData.correctOptionKey
            return (
              <div key={option.id} style={{ marginBottom: '8px' }}>
                <input
                  type='text'
                  value={option.content}
                  onChange={(e) =>
                    handleOptionChange(option.id, e.target.value)
                  }
                  onKeyDown={handleKeyDown}
                  style={{
                    width: '100%',
                    border: isCorrect ? '2px solid green' : '1px solid gray',
                    padding: '8px'
                  }}
                />
              </div>
            )
          })}
        </div>
      </div>

      <div style={{ display: 'flex', columnGap: '1rem' }}>
        <div style={{ width: '50%' }}>
          <label>Explicación de la opción correcta:</label>
          <textarea
            name='correctOptionExplanation'
            value={formData.correctOptionExplanation}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
            placeholder='Explicación de la opción correcta'
            style={{ width: '100%', height: '100px', marginBottom: '8px' }}
          />
        </div>
        <div
          style={{
            width: '50%'
          }}
        >
          <label>Inciso correcto:</label>
          <input
            type='text'
            name='correctOptionKey'
            value={formData.correctOptionKey}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
            placeholder='Inciso correcto'
            style={{ width: '100%', marginBottom: '8px' }}
          />
        </div>
      </div>

      <button
        onClick={handleSave}
        className='primary'
        style={{ width: '100%' }}
        disabled={!isFormModified || updateMutation.isLoading}
      >
        {updateMutation.isLoading ? 'Guardando...' : 'Guardar cambios'}
      </button>

      <ToastContainer position='top-right' autoClose={5000} />
    </div>
  )
}
