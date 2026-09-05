/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './pages/**/*.html',
    './components/**/*.html',
  ],
  theme: {
    extend: {
      colors: {
        indigo: {
          DEFAULT: '#3D3DB4',
          light: '#EEEEF9',
        },
        teal: {
          DEFAULT: '#4ECDC4',
          light: '#E6F9F8',
        },
        lilac: {
          DEFAULT: '#A78BFA',
          light: '#F0EBFF',
        },
        orange: {
          DEFAULT: '#FF6B35',
          light: '#FFF0EB',
        },
        crimson: {
          DEFAULT: '#C0392B',
          light: '#FDECEA',
        },
        surface: {
          DEFAULT: '#FFFFFF',
          2: '#F0F1F8',
        },
        bg: '#F6F7FB',
        border: '#E2E4F0',
        'text-hi': '#1A1A2E',
        'text-mid': '#6B6F8E',
        'text-low': '#A8ABBD',
      },
      fontFamily: {
        display: ['Nunito', 'sans-serif'],
        body: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        lg: '20px',
        md: '14px',
        sm: '10px',
      },
      screens: {
        'sm': '375px',
        'md': '640px',
        'lg': '1024px',
        'xl': '1440px',
      },
    },
  },
  plugins: [],
}
