import http from 'k6/http';

export const options = {
  scenarios: {
    open_model: {
      executor: 'constant-arrival-rate',
      rate: 100,
      timeUnit: '1s',
      duration: '10s',
      preAllocatedVUs: 10,
    },
  },
};

export default function () {
  http.get('http://127.0.0.1:3000');
}
