import { createClient } from 'jsr:@supabase/supabase-js@2'

// Variables de entorno
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");


// const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE);

// SUPABASE_URL=https://vfcivewnqefnkyicklcn.supabase.co
// SUPABASE_SERVICE_ROLE=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmY2l2ZXducWVmbmt5aWNrbGNuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNjMzOTkzMiwiZXhwIjoyMDQxOTE1OTMyfQ.OvK7L63AST3dDYC8yKtO1fJVfEW4BD7mD37nFBnkVs0


const supabase = createClient('https://vfcivewnqefnkyicklcn.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmY2l2ZXducWVmbmt5aWNrbGNuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNjMzOTkzMiwiZXhwIjoyMDQxOTE1OTMyfQ.OvK7L63AST3dDYC8yKtO1fJVfEW4BD7mD37nFBnkVs0');

Deno.serve(async (req) => {
  if (req.method !== "GET") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  try {

    const stats = {}


    const { data, error } = await supabase
      .from("user_progress")
      .select("*, quiz:quizzes ( *, question:questions ( *, topic:topics ( * ) ) )");

    data.forEach((e) => {
      console.log({e})

      stats[e.quiz.question[0].topic.key] = stats[e.quiz.question[0].topic.key] || { total: 0, correct: 0, incorrect: 0, correctPercentage: 0, incorrectPercentage: 0 }

      stats[e.quiz.question[0].topic.key].total += 1
      stats[e.quiz.question[0].topic.key].correct += e.score ? 1 : 0
      stats[e.quiz.question[0].topic.key].incorrect += e.score ? 0 : 1
    })

    Object.keys(stats).forEach((key) => {
      stats[key].correctPercentage = (stats[key].correct / stats[key].total) * 100
      stats[key].incorrectPercentage = (stats[key].incorrect / stats[key].total) * 100
    })

    console.log({stats})


    if (error) {
      throw new Error(error.message);
    }

    const transformedStatsToArray = Object.keys(stats).map((key) => ({
      key: key,
      ...stats[key],
    }));

    return new Response(
      JSON.stringify(transformedStatsToArray),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
