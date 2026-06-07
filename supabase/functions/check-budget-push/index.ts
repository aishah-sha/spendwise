import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.23.0"

serve(async (req) => {
  // Gracefully handle CORS preflight configurations 
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Capture the newly created transaction metadata routed from the database trigger
    const { record } = await req.json()
    if (!record || record.type !== 'expense') {
      return new Response('Skipping: Item is not an expense record.', { status: 200 })
    }

    const userId = record.user_id

    // 1. Fetch current active budget profile allocation limits
    const { data: budget, error: budgetErr } = await supabase
      .from('budgets')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle()

    if (budgetErr || !budget) {
      return new Response('Execution terminated: No allocated profile budget found.', { status: 200 })
    }

    // 2. Compute aggregate sum of all monthly expense transactions 
    const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()
    
    const { data: expenses, error: expErr } = await supabase
      .from('transactions')
      .select('amount')
      .eq('user_id', userId)
      .eq('type', 'expense')
      .gte('date', startOfMonth)

    if (expErr || !expenses) {
      return new Response('Execution error: Unable to aggregate account data.', { status: 500 })
    }

    const totalSpent = expenses.reduce((acc, curr) => acc + curr.amount, 0)

    // 3. Evaluate threshold constraints against target goals
    if (totalSpent >= budget.monthly_limit) {
      
      // Extract specific dynamic hardware device token address keys mapped to the profile
      const { data: deviceToken } = await supabase
        .from('user_tokens')
        .eq('user_id', userId)
        .maybeSingle()

      if (deviceToken && deviceToken.fcm_token) {
        // 4. Submit payload directly downstream to Firebase API Architecture
        await sendFcmNotification(deviceToken.fcm_token, {
          title: "🚨 Budget Limit Exceeded!",
          body: `SpendWise Alert: You have crossed your target limit! Spent: RM ${totalSpent.toFixed(2)}`
        })
      }
    }

    return new Response(JSON.stringify({ success: true, totalSpent }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

// Secure helper engine targeting Google FCM endpoint definitions
async function sendFcmNotification(fcmToken: string, payload: { title: string, body: string }) {
  // ⚠️ CHANGE THIS: Paste your exact Firebase Project ID string here 
  const FIREBASE_PROJECT_ID = "spendwise-c3116" 
  
  const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`
  
  // Retrieve short-lived OAuth2 authorization string from secure cloud environment vaults
  const accessToken = Deno.env.get('FIREBASE_ACCESS_TOKEN')

  await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: {
          title: payload.title,
          body: payload.body
        },
        android: {
          priority: "high",
          notification: { sound: "default" }
        },
        apns: {
          payload: {
            aps: { sound: "default", contentAvailable: true }
          }
        }
      }
    })
  })
}