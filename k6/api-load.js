import http from 'k6/http';
import { sleep } from 'k6';
import {
  authHeaders,
  buildOptions,
  expectOk,
  filterHealthyProductIds,
  getAccount,
  getBaseUrl,
  getPassword,
  jsonHeaders,
  loadSeedData,
  login,
  pickRandom,
  randomInt,
} from './lib/projectKu.js';

export const options = buildOptions(20, '3m');

export function setup() {
  const baseUrl = getBaseUrl();
  let token = '';

  if ((__ENV.ENABLE_AUTH || 'true').toLowerCase() !== 'false') {
    token = login(baseUrl, getAccount(), getPassword());
  }

  const seed = loadSeedData(baseUrl, token);
  seed.productIds = filterHealthyProductIds(baseUrl, seed.productIds, token);

  return {
    baseUrl,
    token,
    seed,
  };
}

export default function (data) {
  const baseUrl = data.baseUrl;
  const token = data.token;

  const categoryRequestOptions = token ? authHeaders(token) : jsonHeaders();
  const categoriesResponse = http.get(`${baseUrl}/v1/categories`, categoryRequestOptions);
  expectOk(categoriesResponse, 'get categories');

  const page = randomInt(1, 3);
  const size = randomInt(8, 12);
  const productsResponse = http.get(`${baseUrl}/v1/products?page=${page}&size=${size}`, jsonHeaders());
  const productsResult = expectOk(productsResponse, 'get products');
  const products = productsResult.body && Array.isArray(productsResult.body.data)
    ? productsResult.body.data
    : [];
  const detailId = pickRandom(data.seed.productIds);

  if (detailId !== null) {
    const detailResponse = http.get(`${baseUrl}/v1/products/${detailId}`, jsonHeaders());
    expectOk(detailResponse, 'get product detail');
  }

  if (token && Math.random() < 0.35) {
    const meResponse = http.get(`${baseUrl}/v1/me`, authHeaders(token));
    expectOk(meResponse, 'get current user');
  }

  if (token && Math.random() < 0.15) {
    const ordersResponse = http.get(`${baseUrl}/v1/orders?page=1&size=5`, authHeaders(token));
    expectOk(ordersResponse, 'get orders');
  }

  sleep(Number(__ENV.THINK_TIME || 1));
}
