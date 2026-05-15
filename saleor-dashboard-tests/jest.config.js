/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: "jsdom",
  transform: {
    "^.+\\.[jt]sx?$": "babel-jest"
  },
  moduleFileExtensions: ["js", "jsx", "ts", "tsx"],
  testMatch: [
    "**/__tests__/**/*.[jt]s?(x)"
  ],
  collectCoverageFrom: ["src/**/*.{js,jsx}"]
};
