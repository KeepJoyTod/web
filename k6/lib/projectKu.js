import http from 'k6/http';
import { check, fail } from 'k6';

const DEFAULT_BASE_URL = 'http://127.0.0.1:8080/api';
const DEFAULT_ACCOUNT = 'user@example.com';
const DEFAULT_PASSWORD = '123456';

export function getBaseUrl() {
  return (__ENV.BASE_URL || DEFAULT_BASE_URL).replace(/\/+$/, '');
}

export function getAccount() {
  return __ENV.ACCOUNT || DEFAULT_ACCOUNT;
}

export function getPassword() {
  return __ENV.PASSWORD || DEFAULT_PASSWORD;
}

export function buildOptions(defaultVus, defaultDuration) {
  const thresholds = {
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.99'],
    http_req_duration: ['p(95)<800', 'p(99)<1500'],
  };

  const stages = parseStages(__ENV.STAGES || '');
  if (stages.length > 0) {
    return { thresholds, stages };
  }

  return {
    thresholds,
    vus: Number(__ENV.VUS || defaultVus),
    duration: __ENV.DURATION || defaultDuration,
  };
}

export function authHeaders(token) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
  };
}

export function jsonHeaders(token) {
  const headers = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  return { headers };
}

export function parseJson(response) {
  try {
    return response.json();
  } catch (error) {
    return null;
  }
}

export function isBusinessSuccess(body) {
  if (!body || typeof body !== 'object') {
    return false;
  }

  if (body.code !== undefined) {
    return Number(body.code) === 200;
  }

  return body.data !== undefined;
}

export function expectOk(response, label) {
  const body = parseJson(response);
  const ok = check(response, {
    [`${label} status is 200`]: (res) => res.status === 200,
    [`${label} business success`]: () => isBusinessSuccess(body),
  });

  return { ok, body };
}

export function login(baseUrl, account, password) {
  const response = http.post(
    `${baseUrl}/v1/auth/login`,
    JSON.stringify({ account, password }),
    jsonHeaders(),
  );
  const result = expectOk(response, 'login');
  const token = result.body && result.body.data ? result.body.data.token : '';

  if (!result.ok || !token) {
    fail('Login failed. Check that seed user data is loaded and backend is healthy.');
  }

  return token;
}

export function loadSeedData(baseUrl, token) {
  const seed = {
    productIds: [],
    addressId: null,
  };

  const productsResponse = http.get(`${baseUrl}/v1/products?page=1&size=20`, jsonHeaders());
  const productsResult = expectOk(productsResponse, 'seed products');
  const products = productsResult.body && Array.isArray(productsResult.body.data)
    ? productsResult.body.data
    : [];

  seed.productIds = products
    .map((item) => item && item.id)
    .filter((id) => Number.isFinite(Number(id)))
    .map((id) => Number(id));

  if (token) {
    const addressResponse = http.get(`${baseUrl}/v1/me/addresses`, authHeaders(token));
    const addressResult = expectOk(addressResponse, 'seed addresses');
    const addresses = addressResult.body && Array.isArray(addressResult.body.data)
      ? addressResult.body.data
      : [];

    if (addresses.length > 0 && addresses[0].id !== undefined) {
      seed.addressId = Number(addresses[0].id);
    }
  }

  return seed;
}

export function filterHealthyProductIds(baseUrl, productIds, token) {
  const healthyIds = [];

  for (const productId of productIds) {
    const response = http.get(
      `${baseUrl}/v1/products/${productId}`,
      token ? authHeaders(token) : jsonHeaders(),
    );
    const body = parseJson(response);
    const ok = response.status === 200 && isBusinessSuccess(body);

    if (ok) {
      healthyIds.push(productId);
    }
  }

  return healthyIds;
}

export function pickRandom(values) {
  if (!values || values.length === 0) {
    return null;
  }

  return values[Math.floor(Math.random() * values.length)];
}

export function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function parseStages(rawStages) {
  if (!rawStages) {
    return [];
  }

  return rawStages
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => {
      const parts = item.split(':').map((part) => part.trim());
      if (parts.length !== 2) {
        fail(`Invalid STAGES entry: ${item}. Use duration:target,duration:target`);
      }

      return {
        duration: parts[0],
        target: Number(parts[1]),
      };
    });
}
