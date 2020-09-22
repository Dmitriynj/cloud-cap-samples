const { v4: uuidv4 } = require("uuid");

module.exports = function () {
  this.before("CREATE", "Media", (req) => {
    return {
      ...req.data,
      ID: uuidv4(),
    };
  });
};
