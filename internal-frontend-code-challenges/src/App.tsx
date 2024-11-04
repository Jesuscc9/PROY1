import { QueryClient, QueryClientProvider } from 'react-query'
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom'
import './App.css'
import '@picocss/pico/css/pico.jade.min.css'
import Quizzes from './Pages/Quizzes/Quizzes'
import QuizDetail from './Pages/Quizzes/QuizDetail'

const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <Routes>
          <Route path='/' element={<Quizzes />} />
          <Route path='/quiz/:id' element={<QuizDetail />} />
        </Routes>
      </Router>
    </QueryClientProvider>
  )
}

export default App
