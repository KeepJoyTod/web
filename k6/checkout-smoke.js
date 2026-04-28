import http from 'k6/http';
import { sleep } from 'k6';
import {
  authHeaders,
  buildOptions,
  expectOk,
  getAccount,
  getBaseUrl,
  getPassword,
  loadSeedData,
  login,
  pickRandom,
} from './lib/projectKu.js';

export const options = buildOptions(1, '1m');

export function setup() {
  const baseUrl = getBaseUrl();
  const token = login(baseUrl, getAccount(), getPassword());
  const seed = loadSeedData(baseUrl, token);

  if (!seed.addressId) {
    throw new Error('No address found for the seed user. Create one before running checkout smoke.');
  }

  if (!seed.productIds.length) {
    throw new Error('No products found. Load seed product data before running checkout smoke.');
  }

  return {
    baseUrl,
    token,
    seed,
  };
}

export default function (data) {
  const baseUrl = data.baseUrl;
  const token = data.token;
  const productId = pickRandom(data.seed.productIds);

  const addCartResponse = http.post(
    `${baseUrl}/v1/cart/items`,
    JSON.stringify({
      productId,
      quantity: 1,
    }),
    authHeaders(token),
  );
  expectOk(addCartResponse, 'add cart item');

  const cartResponse = http.get(`${baseUrl}/v1/cart`, authHeaders(token));
  expectOk(cartResponse, 'get cart');

  const checkoutResponse = http.post(
    `${baseUrl}/v1/orders/checkout`,
    JSON.stringify({
      addressId: data.seed.addressId,
      couponCode: '',
    }),
    authHeaders(token),
  );
  expectOk(checkoutResponse, 'checkout');

  sleep(Number(__ENV.THINK_TIME || 1));
}
