import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

type AppleReceiptResponse = {
  status?: number;
  environment?: string;
  latest_receipt_info?: Array<Record<string, unknown>>;
  pending_renewal_info?: Array<Record<string, unknown>>;
};

type SubscriptionCandidate = {
  productId: string;
  transactionId: string | null;
  originalTransactionId: string | null;
  expiresMs: number | null;
  cancellationMs: number | null;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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

function parseCandidates(raw: unknown): SubscriptionCandidate[] {
  if (!Array.isArray(raw)) return [];

  return raw.map((item) => {
    const row = item as Record<string, unknown>;
    return {
      productId: toStringValue(row.product_id) ?? '',
      transactionId: toStringValue(row.transaction_id),
      originalTransactionId: toStringValue(row.original_transaction_id),
      expiresMs: toIntValue(row.expires_date_ms),
      cancellationMs: toIntValue(row.cancellation_date_ms),
    };
  }).filter((item) => item.productId.length > 0);
}

function bestCandidate(
  candidates: SubscriptionCandidate[],
  allowedProductIds: Set<string>,
  requestedProductId: string | null,
): SubscriptionCandidate | null {
  let filtered = candidates.filter((item) => allowedProductIds.has(item.productId));
  if (requestedProductId != null) {
    filtered = filtered.filter((item) => item.productId === requestedProductId);
  }
  if (filtered.length === 0) return null;

  filtered.sort((a, b) => (b.expiresMs ?? 0) - (a.expiresMs ?? 0));
  return filtered[0];
}

function deriveStatus(candidate: SubscriptionCandidate | null, nowMs: number): string {
  if (candidate == null) return 'inactive';
  if (candidate.cancellationMs != null) return 'revoked';
  if ((candidate.expiresMs ?? 0) > nowMs) return 'active';
  return 'expired';
}

function isActiveSubscription(candidate: SubscriptionCandidate | null, nowMs: number): boolean {
  if (candidate == null) return false;
  if (candidate.cancellationMs != null) return false;
  return (candidate.expiresMs ?? 0) > nowMs;
}

async function verifyReceiptWithApple(
  receiptData: string,
  sharedSecret: string,
) {
  const payload = {
    'receipt-data': receiptData,
    password: sharedSecret,
    'exclude-old-transactions': true,
  };

  async function request(endpoint: string): Promise<AppleReceiptResponse> {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (!response.ok) {
      throw new Error(`Apple verification HTTP ${response.status}.`);
    }
    const body = await response.json();
    return body as AppleReceiptResponse;
  }

  let data = await request('https://buy.itunes.apple.com/verifyReceipt');
  if (data.status === 21007) {
    data = await request('https://sandbox.itunes.apple.com/verifyReceipt');
  }

  return data;
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
    const supabaseAnonKey = env('SUPABASE_ANON_KEY');
    const supabaseServiceRoleKey = env('SUPABASE_SERVICE_ROLE_KEY');
    const appleSharedSecret = env('APPLE_IAP_SHARED_SECRET');

    const authHeader = req.headers.get('Authorization');
    if (authHeader == null || authHeader.trim().length === 0) {
      return json(401, { error: 'Missing authorization header.' });
    }

    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const userResult = await authClient.auth.getUser();
    const user = userResult.data.user;
    if (userResult.error != null || user == null) {
      return json(401, { error: 'Unauthorized user.' });
    }

    let body: Record<string, unknown>;
    try {
      body = await req.json() as Record<string, unknown>;
    } catch (_) {
      return json(400, { error: 'Invalid JSON payload.' });
    }

    const receiptData = toStringValue(body.verificationData);
    if (receiptData == null) {
      return json(400, { error: 'verificationData is required.' });
    }

    const productId = toStringValue(body.productId);
    const transactionId = toStringValue(body.transactionId);

    const allowedProductsEnv = Deno.env.get('APPLE_PREMIUM_PRODUCT_IDS') ??
      'discipline_premium_monthly,discipline_premium_yearly';
    const allowedProductIds = new Set(
      allowedProductsEnv
        .split(',')
        .map((item) => item.trim())
        .filter((item) => item.length > 0),
    );
    if (allowedProductIds.size === 0) {
      return json(500, { error: 'APPLE_PREMIUM_PRODUCT_IDS is empty.' });
    }

    const appleData = await verifyReceiptWithApple(receiptData, appleSharedSecret);
    const verifyStatus = Number(appleData.status ?? -1);
    if (verifyStatus !== 0) {
      return json(400, {
        error: `Apple verification failed with status ${verifyStatus}.`,
        status: verifyStatus,
      });
    }

    const candidates = parseCandidates(appleData.latest_receipt_info);
    const selected = bestCandidate(candidates, allowedProductIds, productId);
    const nowMs = Date.now();
    const status = deriveStatus(selected, nowMs);
    const isPremium = isActiveSubscription(selected, nowMs);

    let autoRenewStatus: boolean | null = null;
    if (Array.isArray(appleData.pending_renewal_info) && selected != null) {
      const matchedRenewal = appleData.pending_renewal_info.find((item) => {
        const row = item as Record<string, unknown>;
        const renewalOriginal = toStringValue(row.original_transaction_id);
        const renewalProduct = toStringValue(row.product_id);
        if (selected.originalTransactionId != null &&
            renewalOriginal == selected.originalTransactionId) {
          return true;
        }
        return renewalProduct == selected.productId;
      });
      if (matchedRenewal != null) {
        const row = matchedRenewal as Record<string, unknown>;
        autoRenewStatus = toBoolValue(row.auto_renew_status);
      }
    }

    const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey);

    const existingProfile = await serviceClient
      .from('profiles')
      .select('alias')
      .eq('id', user.id)
      .maybeSingle();
    if (existingProfile.error != null) {
      return json(500, { error: existingProfile.error.message });
    }

    const profileAlias = toStringValue(existingProfile.data?.alias) ??
      aliasFromUserId(user.id);

    const profileUpsert = await serviceClient.from('profiles').upsert(
      {
        id: user.id,
        alias: profileAlias,
        is_premium: isPremium,
      },
      { onConflict: 'id' },
    );
    if (profileUpsert.error != null) {
      return json(500, { error: profileUpsert.error.message });
    }

    const subscriptionsUpsert = await serviceClient.from('user_subscriptions').upsert(
      {
        user_id: user.id,
        platform: 'ios',
        provider: 'app_store',
        product_id: selected?.productId ?? productId,
        original_transaction_id: selected?.originalTransactionId,
        latest_transaction_id: selected?.transactionId ?? transactionId,
        environment: toStringValue(appleData.environment) ?? null,
        status,
        is_active: isPremium,
        expires_at: isoFromMs(selected?.expiresMs ?? null),
        auto_renew_status: autoRenewStatus,
        last_verified_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id,platform' },
    );
    if (subscriptionsUpsert.error != null) {
      return json(500, { error: subscriptionsUpsert.error.message });
    }

    const eventInsert = await serviceClient.from('subscription_events').insert({
      user_id: user.id,
      platform: 'ios',
      provider: 'app_store',
      product_id: selected?.productId ?? productId,
      original_transaction_id: selected?.originalTransactionId,
      transaction_id: selected?.transactionId ?? transactionId,
      event_type: 'verify',
      status,
      is_active: isPremium,
      environment: toStringValue(appleData.environment) ?? null,
      expires_at: isoFromMs(selected?.expiresMs ?? null),
      payload: {
        verify_status: verifyStatus,
      },
    });
    if (eventInsert.error != null) {
      return json(500, { error: eventInsert.error.message });
    }

    return json(200, {
      isPremium,
      status,
      productId: selected?.productId ?? productId,
      expiresAt: isoFromMs(selected?.expiresMs ?? null),
      environment: toStringValue(appleData.environment),
      transactionId: selected?.transactionId ?? transactionId,
      originalTransactionId: selected?.originalTransactionId,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error.';
    return json(500, { error: message });
  }
});
