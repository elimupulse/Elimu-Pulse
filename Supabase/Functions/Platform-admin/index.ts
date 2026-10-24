import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...cors, "Content-Type": "application/json" },
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return reply({ error: "Sign in required" }, 401);

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) return reply({ error: "Invalid or expired session" }, 401);
  const { data: authority, error: authorityError } = await admin
    .from("global_admins").select("user_id").eq("user_id", userData.user.id).maybeSingle();
  if (authorityError || !authority) return reply({ error: "Global administrator access required" }, 403);

  let input: Record<string, unknown>;
  try { input = await req.json(); } catch { return reply({ error: "Invalid JSON body" }, 400); }
  const action = input.action;

  if (action === "create_school") {
    const schoolName = String(input.schoolName || "").trim();
    const schoolCode = String(input.schoolCode || "").trim().toUpperCase();
    const adminName = String(input.adminName || "").trim();
    const email = String(input.email || "").trim().toLowerCase();
    const password = String(input.password || "");
    const billingCycle = String(input.billingCycle || "both");
    if (!schoolName || !schoolCode || !adminName || !email || password.length < 12)
      return reply({ error: "All fields are required; password must be at least 12 characters" }, 400);
    if (!/^[A-Z0-9][A-Z0-9_-]{2,19}$/.test(schoolCode))
      return reply({ error: "School code must be 3–20 letters, numbers, hyphens or underscores" }, 400);
    if (!["monthly", "annual", "both"].includes(billingCycle))
      return reply({ error: "Invalid billing cycle" }, 400);

    const now = new Date();
    const trialEnds = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    const { data: school, error: schoolError } = await admin.from("schools").insert({
      name: schoolName, school_code: schoolCode, is_active: true,
      trial_started_at: now.toISOString(), trial_ends_at: trialEnds.toISOString(),
      subscription_status: "trial", billing_cycle: billingCycle,
    }).select("id,name").single();
    if (schoolError) return reply({ error: schoolError.message }, 400);

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email, password, email_confirm: true,
      user_metadata: { full_name: adminName, must_change_password: true, school_id: school.id },
    });
    if (createError || !created.user) {
      await admin.from("schools").delete().eq("id", school.id);
      return reply({ error: createError?.message || "Could not create administrator account" }, 400);
    }
    const { error: membershipError } = await admin.from("school_users").insert({
      user_id: created.user.id, school_id: school.id, role: "school_admin", is_active: true,
    });
    if (membershipError) {
      await admin.auth.admin.deleteUser(created.user.id);
      await admin.from("schools").delete().eq("id", school.id);
      return reply({ error: membershipError.message }, 400);
    }
    return reply({ success: true, schoolId: school.id, adminUserId: created.user.id,
      trialStartedAt: now.toISOString(), trialEndsAt: trialEnds.toISOString() });
  }

  if (action === "set_school_active") {
    const schoolId = String(input.schoolId || "");
    if (!schoolId) return reply({ error: "School ID is required" }, 400);
    const { error } = await admin.from("schools").update({ is_active: input.isActive === true, updated_at: new Date().toISOString() }).eq("id", schoolId);
    if (error) return reply({ error: error.message }, 400);
    return reply({ success: true });
  }

  if (action === "update_subscription") {
    const schoolId = String(input.schoolId || "");
    const status = String(input.status || "");
    const billingCycle = String(input.billingCycle || "");
    if (!schoolId || !["trial", "active", "payment_due", "suspended", "expired"].includes(status) || !["monthly", "annual", "both"].includes(billingCycle))
      return reply({ error: "Invalid subscription update" }, 400);
    const { error } = await admin.from("schools").update({ subscription_status: status, billing_cycle: billingCycle, updated_at: new Date().toISOString() }).eq("id", schoolId);
    if (error) return reply({ error: error.message }, 400);
    return reply({ success: true });
  }

  return reply({ error: "Unknown platform action" }, 400);
});
