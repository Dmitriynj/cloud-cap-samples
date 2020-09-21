const { v4: uuidv4 } = require("uuid");

module.exports = async function () {
  const db = await cds.connect.to("db"); // connect to database service
  const { Media } = db.entities;

  this.on("CREATE", "Media", (req, next) => {
    req.data.ID = uuidv4();
    return next();
  });

  this.on("READ", "Media", async (req, next) => {
    const [ID] = req.params;
    if (ID) {
      const media = await SELECT.from(Media, { ID });
      req._.res.writeHead(200, {
        "Content-Type": media.mediaType,
      });
      const stream = db.stream("media").from(Media, { ID });
      stream.pipe(req._.res);
    } else {
      return next();
    }
  });
};
