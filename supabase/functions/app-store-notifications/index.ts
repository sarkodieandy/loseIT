import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-webhook-token',
};

type SubscriptionStatus = 'active' | 'inactive' | 'expired' | 'revoked';

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function env(name: string): string {
  const value = Deno.env.get(name);
  if (value == null || value.trim().length === 0) {
    throw new Error(`Missing required env var: ${name}`);
  }
  return value.trim();
}

function optionalEnv(name: string): string | null {
  const value = Deno.env.get(name);
  if (value == null || value.trim().length === 0) return null;
  return value.trim();
}

function toStringValue(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  return trimmed;
}

function toIntValue(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value.trim(), 10);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return null;
}

function toBoolValue(value: unknown): boolean | null {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const lower = value.trim().toLowerCase();
    if (lower === 'true' || lower === '1') return true;
    if (lower === 'false' || lower === '0') return false;
  }
  return null;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (typeof value !== 'object' || value == null || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function base64UrlDecode(input: string): string {
  let normalized = input.replaceAll('-', '+').replaceAll('_', '/');
  const padding = normalized.length % 4;
  if (padding > 0) {
    normalized = `${normalized}${'='.repeat(4 - padding)}`;
  }
  const decoded = atob(normalized);
  const bytes = Uint8Array.from(decoded, (char) => char.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

function decodeJwsPayload(signedToken: string): Record<string, unknown> {
  const parts = signedToken.split('.');
  if (parts.length !== 3) {
    throw new Error('Invalid signed payload format.');
  }
  const payloadRaw = base64UrlDecode(parts[1]);
  const parsed = JSON.parse(payloadRaw);
  const payload = asRecord(parsed);
  if (payload == null) {
    throw new Error('Signed payload body is invalid.');
  }
  return payload;
}

function isoFromMs(ms: number | null): string | null {
  if (ms == null || !Number.isFinite(ms)) return null;
  try {
    return new Date(ms).toISOString();
  } catch (_) {
    return null;
  }
}

function aliasFromUserId(userId: string): string {
  const compact = userId.replaceAll('-', '').toUpperCase();
  const suffix = compact.length > 6
    ? compact.slice(compact.length - 6)
    : compact.padStart(6, '0');
  return `Alias-${suffix}`;
}

function firstInt(values: unknown[]): number | null {
  for (const value of values) {
    const parsed = toIntValue(value);
    if (parsed != null) return parsed;
  }
  return null;
}

function loadAllowedProductIds(): Set<string> {
  const allowedProductsEnv = Deno.env.get('APPLE_PREMIUM_PRODUCT_IDS') ??
    'discipline_premium_monthly,discipline_premium_yearly';
  return new Set(
    allowedProductsEnv
      .split(',')
      .map((item) => item.trim())
      .filter((item) => item.length > 0),
  );
}

function deriveStatus(
  notificationType: string,
  expiresMs: number | null,
  revokedMs: number | null,
  nowMs: number,
): SubscriptionStatus {
  const upperType = notificationType.toUpperCase();
  if (revokedMs != null || upperType === 'REVOKE' || upperType === 'REFUND') {
    return 'revoked';
  }
  if (expiresMs != null) {
    return expiresMs > nowMs ? 'active' : 'expired';
  }
  if (upperType === 'SUBSCRIBED' ||
      upperType === 'DID_RENEW' ||
      upperType === 'DID_RECOVER' ||
      upperType === 'RENEWAL_EXTENDED' ||
      upperType === 'RENEWAL_EXTENSION') {
    return 'active';
  }
  if (upperType === 'EXPIRED' || upperType === 'GRACE_PERIOD_EXPIRED') {
    return 'expired';
  }
  return 'inactive';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json(405, { error: 'Method not allowed.' });
  }

  try {
    const supabaseUrl = env('SUPABASE_URL');
    const supabaseServiceRoleKey = env('SUPABASE_SERVICE_ROLE_KEY');
    const webhookToken = optionalEnv('APPLE_NOTIFICATION_WEBHOOK_TOKEN');
    const allowedProductIds = loadAllowedProductIds();
    if (allowedProductIds.size === 0) {
      return json(500, { error: 'APPLE_PREMIUM_PRODUCT_IDS is empty.' });
    }

    if (webhookToken != null) {
      const urlToken = toStringValue(new URL(req.url).searchParams.get('token'));
      const headerToken = toStringValue(req.headers.get('x-webhook-token'));
      const providedToken = headerToken ?? urlToken;
      if (providedToken != webhookToken) {
        return json(401, { error: 'Unauthorized webhook request.' });
      }
    }

    let body: Record<string, unknown>;
    try {
      body = await req.json() as Record<string, unknown>;
    } catch (_) {
      return json(400, { error: 'Invalid JSON payload.' });
    }

    const signedPayload = toStringValue(body.signedPayload);
    if (signedPayload == null) {
      return json(400, { error: 'signedPayload is required.' });
    }

    const payload = decodeJwsPayload(signedPayload);
    const notificationUuid = toStringValue(payload.notificationUUID);
    const notificationType = toStringValue(payload.notificationType) ?? 'UNKNOWN';
    const notificationSubtype = toStringValue(payload.subtype);
    if (notificationUuid == null) {
      return json(400, { error: 'notificationUUID missing in payload.' });
    }

    const payloadData = asRecord(payload.data);
    const signedTransactionInfo = toStringValue(payloadData?.signedTransactionInfo);
    const signedRenewalInfo = toStringValue(payloadData?.signedRenewalInfo);
    const transactionInfo = signedTransactionInfo == null
      ? null
      : decodeJwsPayload(signedTransactionInfo);
    const renewalInfo = signedRenewalInfo == null
      ? null
      : decodeJwsPayload(signedRenewalInfo);

    const productId = toStringValue(transactionInfo?.productId) ??
      toStringValue(renewalInfo?.autoRenewProductId) ??
      toStringValue(renewalInfo?.productId);
    const originalTransactionId = toStringValue(transactionInfo?.originalTransactionId) ??
      toStringValue(renewalInfo?.originalTransactionId);
    const transactionId = toStringValue(transactionInfo?.transactionId);
    const environment = toStringValue(payloadData?.environment) ??
      toStringValue(payload.environment) ??
      toStringValue(transactionInfo?.environment);

    const expiresMs = firstInt([
      transactionInfo?.expiresDate,
      transactionInfo?.expiresDateMs,
      transactionInfo?.expires_date_ms,
      renewalInfo?.gracePeriodExpiresDate,
      renewalInfo?.gracePeriodExpiresDateMs,
    ]);
    const revokedMs = firstInt([
      transactionInfo?.revocationDate,
      transactionInfo?.revocationDateMs,
      transactionInfo?.cancellationDate,
      transactionInfo?.cancellationDateMs,
    ]);
    const autoRenewStatus = toBoolValue(
      renewalInfo?.autoRenewStatus ?? renewalInfo?.auto_renew_status,
    );

    const nowMs = Date.now();
    const statusFromEvent = deriveStatus(notificationType, expiresMs, revokedMs, nowMs);
    const isPremiumProduct = productId != null && allowedProductIds.has(productId);
    const isPremium = isPremiumProduct && statusFromEvent === 'active';
    const normalizedStatus: SubscriptionStatus = isPremiumProduct ? statusFromEvent : 'inactive';

    const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey);
    const rawInsert = await serviceClient.from('subscription_webhook_events').insert({
      provider: 'app_store',
      notification_uuid: notificationUuid,
      notification_type: notificationType,
      notification_subtype: notificationSubtype,
      signed_payload: signedPayload,
      environment,
      original_transaction_id: originalTransactionId,
      transaction_id: transactionId,
      product_id: productId,
      status: normalizedStatus,
      is_active: isPremium,
      expires_at: isoFromMs(expiresMs),
      auto_renew_status: autoRenewStatus,
      raw_payload: payload,
    });
    if (rawInsert.error != null) {
      if (rawInsert.error.code === '23505') {
        return json(200, {
          accepted: true,
          duplicate: true,
          notificationUuid,
        });
      }
      return json(500, { error: rawInsert.error.message });
    }

    let userId: string | null = null;
    if (originalTransactionId != null) {
      const lookup = await serviceClient
        .from('user_subscriptions')
        .select('user_id')
        .eq('platform', 'ios')
        .eq('original_transaction_id', originalTransactionId)
        .maybeSingle();
      if (lookup.error != null) {
        return json(500, { error: lookup.error.message });
      }
      userId = toStringValue(lookup.data?.user_id);
    }

    if (userId == null && transactionId != null) {
      const lookup = await serviceClient
        .from('user_subscriptions')
        .select('user_id')
        .eq('platform', 'ios')
        .eq('latest_transaction_id', transactionId)
        .maybeSingle();
      if (lookup.error != null) {
        return json(500, { error: lookup.error.message });
      }
      userId = toStringValue(lookup.data?.user_id);
    }

    if (userId != null) {
      const profileLookup = await serviceClient
        .from('profiles')
        .select('alias')
        .eq('id', userId)
        .maybeSingle();
      if (profileLookup.error != null) {
        return json(500, { error: profileLookup.error.message });
      }
      const alias = toStringValue(profileLookup.data?.alias) ?? aliasFromUserId(userId);

      const subscriptionUpsert = await serviceClient.from('user_subscriptions').upsert(
        {
          user_id: userId,
          platform: 'ios',
          provider: 'app_store',
          product_id: productId,
          original_transaction_id: originalTransactionId,
          latest_transaction_id: transactionId,
          environment,
          status: normalizedStatus,
          is_active: isPremium,
          expires_at: isoFromMs(expiresMs),
          auto_renew_status: autoRenewStatus,
          last_verified_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,platform' },
      );
      if (subscriptionUpsert.error != null) {
        return json(500, { error: subscriptionUpsert.error.message });
      }

      const profileUpsert = await serviceClient.from('profiles').upsert(
        {
          id: userId,
          alias,
          is_premium: isPremium,
        },
        { onConflict: 'id' },
      );
      if (profileUpsert.error != null) {
        return json(500, { error: profileUpsert.error.message });
      }

      const eventInsert = await serviceClient.from('subscription_events').insert({
        user_id: userId,
        platform: 'ios',
        provider: 'app_store',
        product_id: productId,
        original_transaction_id: originalTransactionId,
        transaction_id: transactionId,
        event_type: `notification:${notificationType}`,
        status: normalizedStatus,
        is_active: isPremium,
        environment,
        expires_at: isoFromMs(expiresMs),
        payload: {
          notification_type: notificationType,
          notification_subtype: notificationSubtype,
          notification_uuid: notificationUuid,
        },
      });
      if (eventInsert.error != null) {
        return json(500, { error: eventInsert.error.message });
      }
    }

    const processedUpdate = await serviceClient
      .from('subscription_webhook_events')
      .update({
        user_id: userId,
        status: normalizedStatus,
        is_active: isPremium,
        expires_at: isoFromMs(expiresMs),
        auto_renew_status: autoRenewStatus,
        processed_at: new Date().toISOString(),
      })
      .eq('notification_uuid', notificationUuid);
    if (processedUpdate.error != null) {
      return json(500, { error: processedUpdate.error.message });
    }

    return json(200, {
      accepted: true,
      duplicate: false,
      notificationUuid,
      userLinked: userId != null,
      status: normalizedStatus,
      isPremium,
      productId,
      expiresAt: isoFromMs(expiresMs),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error.';
    return json(500, { error: message });
  }
});
