/* ── Estado global (Sprint 17) ── */
const TOKEN_KEY = 'kripta_token';
const USER_KEY = 'kripta_user';

const State = {
  get token() {
    return localStorage.getItem(TOKEN_KEY);
  },
  set token(value) {
    if (value) localStorage.setItem(TOKEN_KEY, value);
    else localStorage.removeItem(TOKEN_KEY);
  },
  get user() {
    try {
      return JSON.parse(localStorage.getItem(USER_KEY));
    } catch (e) {
      return null;
    }
  },
  set user(value) {
    if (value) localStorage.setItem(USER_KEY, JSON.stringify(value));
    else localStorage.removeItem(USER_KEY);
  },
  currentSubject: null,
  currentUnit: null,
};

function getState() {
  return State;
}