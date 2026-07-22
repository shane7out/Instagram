import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/app/**/*.{ts,tsx}',
    './src/components/**/*.{ts,tsx}',
    './src/lib/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Deep charcoal / obsidian base for a luxury numismatic feel
        ink: {
          950: '#0a0a0b',
          900: '#111114',
          800: '#1a1a1f',
          700: '#26262d',
          600: '#3a3a44',
        },
        // Refined metallic gold accent
        gold: {
          50: '#fbf7ec',
          100: '#f5ecd0',
          200: '#ebd9a0',
          300: '#dfc169',
          400: '#d4af37', // classic coin gold
          500: '#c39a2e',
          600: '#a37c25',
          700: '#7d5e1f',
        },
        // Aged silver / platinum
        silver: {
          100: '#f4f5f7',
          200: '#e3e5e9',
          300: '#c7cbd2',
          400: '#a3a9b4',
        },
      },
      fontFamily: {
        serif: ['var(--font-serif)', 'Georgia', 'serif'],
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        coin: '0 10px 40px -12px rgba(0,0,0,0.55)',
        'gold-glow': '0 0 0 1px rgba(212,175,55,0.35), 0 12px 40px -12px rgba(212,175,55,0.25)',
      },
      backgroundImage: {
        'gold-sheen':
          'linear-gradient(135deg, #f5ecd0 0%, #d4af37 45%, #a37c25 55%, #dfc169 100%)',
      },
    },
  },
  plugins: [],
};

export default config;
