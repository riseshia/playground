import http from 'k6/http';

export const options = {
  // vus: 32,
  // duration: '10s',
  scenarios: {
    open_model: {
      executor: 'constant-arrival-rate',
      rate: 100,
      timeUnit: '1s',
      duration: '10s',
      preAllocatedVUs: 100,
    },
  },
};

export default function () {
  http.get('http://127.0.0.1:3000');
}
