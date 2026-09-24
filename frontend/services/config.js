/* ── Configuração de ambiente (Sprint 20) ── */
const ENV = 'dev';

const CONFIG = {
  dev: {
    API_URL: 'http://localhost:8080/api',
  },
  prod: {
    API_URL: 'https://api.kripta.app/api',
  },
};

const API_URL = CONFIG[ENV].API_URL;

const APP_NAME = 'KRIPTA';