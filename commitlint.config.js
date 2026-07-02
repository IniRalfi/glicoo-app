/**
 * Purpose:
 * Commit lint rules definition for conventional commits.
 *
 * Used By:
 * husky hooks, CI
 *
 * Depends On:
 * @commitlint/config-conventional
 *
 * Impact:
 * validation on git commit messages.
 */

module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-enum": [
      2,
      "always",
      ["mobile", "backend", "web", "db", "api", "ai", "sensor", "auth", "docs", "config"],
    ],
  },
};
