const cds = require("@sap/cds");
class DummyUser extends cds.User {
  is() {
    return "user";
  }
  attr() {
    return {
      level: 0,
    };
  }
}

module.exports = (req, res, next) => {
  const { authorization: authHeader } = req.headers;
  const token = authHeader && authHeader.split(" ")[1];
  if (token === null) {
    return res.sendStatus(401);
  }

  if (token !== "somesecurestring") {
    return res.sendStatus(403);
  }

  req.user = new DummyUser("dummy");
  next();
};
