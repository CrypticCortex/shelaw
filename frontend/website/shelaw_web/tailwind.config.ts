import { color } from "chart.js/helpers";

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        redCustom: '#A84234',
        pinkCustom: '#986388',
        lightPink: '#E298B8',
        grape: '#62245B',
        magenta: '#B50E48',
        fuchsia: '#DA30A5',
        peach: '#FFC2D7',
        wine: '#6E1226',
        gradientStart: '#AE4F63',
        gradientEnd: '#000000',
        color1: '#F9F9F9',
      },
    },
  },
  plugins: [],
};