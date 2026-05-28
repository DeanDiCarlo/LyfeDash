import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.4";

type ProcessMemoryRequest = {
  mediaAssetId: string;
};

serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return Response.json({ error: "Supabase environment is not configured." }, { status: 500 });
  }

  const { mediaAssetId } = await request.json() as ProcessMemoryRequest;
  if (!mediaAssetId) {
    return Response.json({ error: "mediaAssetId is required." }, { status: 400 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: media, error: mediaError } = await supabase
    .from("media_assets")
    .select("id,user_id,day_id,kind,storage_path,thumbnail_storage_path")
    .eq("id", mediaAssetId)
    .single();

  if (mediaError || !media) {
    return Response.json({ error: mediaError?.message ?? "Media asset not found." }, { status: 404 });
  }

  await supabase
    .from("media_assets")
    .update({ ai_state: "processing" })
    .eq("id", mediaAssetId);

  // TODO: Call the configured multimodal provider here.
  // The intended first provider is Gemini for image/video captioning and embeddings.
  const placeholderCaption = `Unprocessed ${media.kind} memory.`;
  const placeholderTags = ["memory"];

  const { error: artifactError } = await supabase
    .from("ai_artifacts")
    .insert({
      user_id: media.user_id,
      day_id: media.day_id,
      media_asset_id: media.id,
      provider: "placeholder",
      model: "pending-provider",
      caption: placeholderCaption,
      tags: placeholderTags,
      processing_state: "queued"
    });

  if (artifactError) {
    await supabase
      .from("media_assets")
      .update({ ai_state: "failed" })
      .eq("id", mediaAssetId);

    return Response.json({ error: artifactError.message }, { status: 500 });
  }

  await supabase
    .from("media_assets")
    .update({ ai_state: "queued" })
    .eq("id", mediaAssetId);

  return Response.json({ ok: true });
});

