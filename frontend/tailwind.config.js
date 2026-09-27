/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        navy: {
          900: '#07111F',
          800: '#0D1B2E',
          700: '#14253E',
          600: '#1D3252',
        },
        cyan: {
          400: '#22E8E8',
          500: '#00D4D4',
          600: '#00B4B4',
        },
        brand: {
          blue: '#1E88E5',
          cyan: '#00D4D4',
          navy: '#07111F',
          success: '#22C55E',
          warning: '#F59E0B',
          danger: '#EF4444',
          bg: '#F8FAFC',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        'glass': '0 8px 32px 0 rgba(7, 17, 31, 0.37)',
        'cyan-glow': '0 0 20px -3px rgba(0, 212, 212, 0.35)',
      }
    },
  },
  plugins: [],
}
