const plugin = require("tailwindcss/plugin")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/cafe_web.ex",
    "../lib/cafe_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#fff7ed",
          600: "#d97706",
          700: "#b45309"
        }
      }
    }
  },
  plugins: [
    require("@tailwindcss/forms"),
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"]))
  ]
}
