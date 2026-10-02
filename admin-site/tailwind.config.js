/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#10B981',
          dark: '#059669',
          light: '#D1FAE5',
        },
        secondary: '#2563EB',
        warning: '#F59E0B',
      }
    },
  },
  plugins: [],
}

