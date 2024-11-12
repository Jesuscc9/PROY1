import { createClient } from 'jsr:@supabase/supabase-js@2'

// Variables de entorno
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");


const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE);

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  try {
    const {
      quiz_id,
      code,
      instruction,
      correct_option_key,
      topic_id,
      options
    } = await req.json();



    // Iniciar la transacción
    const { data: quizData, error: quizError } = await supabase
      .from("quizzes")
      .update({
        code: code,
        instruction: instruction,
        reviewed: true,
        reviewed_at: new Date().toISOString(),
      })
      .eq("id", quiz_id)
      .select();

    
    if (quizError) throw quizError;

    // Obtener el question_id asociado con el quiz
    const { data: questionData, error: questionSelectError } = await supabase
      .from("questions")
      .select("id")
      .eq("quiz_id", quiz_id)
      .single();

    console.log(questionData);

    if (questionSelectError) throw questionSelectError;

    const question_id = questionData.id;

    // Actualizar la tabla questions
    const { error: questionError } = await supabase
      .from("questions")
      .update({
        correct_option_key: correct_option_key,
        topic_id: topic_id,
      })
      .eq("id", question_id);

    if (questionError) throw questionError;

    // Eliminar las opciones antiguas
    const { error: deleteOptionsError } = await supabase
      .from("options")
      .delete()
      .eq("question_id", question_id);

    if (deleteOptionsError) throw deleteOptionsError;

    // Insertar las nuevas opciones
    const formattedOptions = options.map((option) => ({
      question_id: question_id,
      key: option.key,
      content: option.content,
    }));

    const { error: insertOptionsError } = await supabase
      .from("options")
      .insert(formattedOptions);

    if (insertOptionsError) throw insertOptionsError;

    return new Response(
      JSON.stringify({ message: "Data updated successfully" }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
