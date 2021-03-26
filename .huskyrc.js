const tasks = (arr) => arr.join(" && ")

module.exports = {
  hooks: {
    "pre-commit": tasks(["yarn lint:check", "yarn prettier:check", "yarn test"]),
  },
}
