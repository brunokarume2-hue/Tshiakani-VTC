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
          orange: '#FF6B00',
          green: '#2D5016',
          gray: '#F5F5F5'
        }
      }
    },
  },
  plugins: [],
}

