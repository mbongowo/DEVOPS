import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Generates realistic browse -> add-to-cart traffic against Robot Shop so there
// is live telemetry to observe. Point BASE_URL at the ingress/port-forward.
//   k6 run -e BASE_URL=http://localhost:8080 load/k6-loadtest.js

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const errors = new Rate('failed_requests');

export const options = {
  scenarios: {
    browse: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '2m', target: 10 },
        { duration: '30s', target: 0 },
      ],
    },
  },
  thresholds: {
    failed_requests: ['rate<0.05'],
    http_req_duration: ['p(95)<1000'],
  },
};

const CATALOGUE = ['Watson', 'HAL', 'R2D2', 'Wall-E', 'Sonny'];

export default function () {
  const home = http.get(`${BASE_URL}/`);
  check(home, { 'home 200': (r) => r.status === 200 }) || errors.add(1);

  const products = http.get(`${BASE_URL}/api/catalogue/products`);
  check(products, { 'catalogue 200': (r) => r.status === 200 }) || errors.add(1);

  const sku = CATALOGUE[Math.floor(Math.random() * CATALOGUE.length)];
  const cart = http.get(`${BASE_URL}/api/cart/add/anonymous/${sku}/1`);
  check(cart, { 'cart add ok': (r) => r.status === 200 || r.status === 404 }) || errors.add(1);

  sleep(Math.random() * 2 + 1);
}
