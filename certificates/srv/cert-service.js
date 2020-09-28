const cds = require("@sap/cds");

module.exports = async function () {
  const db = await cds.connect.to("db"); // connect to database service
  const { Orders, Certificates } = db.entities; // get reflected definitions

  this.before("*", (req) => {
    console.log("[USER]", req.user);
  });

  // filter owned certificates
  this.on("READ", "Orders", async (req) => {
    return await db.run(req.query.where({ createdBy: req.user.id }));
  });

  this.on("orderCertificate", async (req) => {
    const { certificate_ID, amount } = req.data;
    const transaction = await db.tx(req);
    await transaction.run(INSERT({ certificate_ID, amount }).into(Orders));
    const affectedRows = await transaction.run(
      UPDATE(Certificates, certificate_ID)
        .with({ instock: { "-=": amount } })
        .where({ instock: { ">=": amount } })
    );
    if (affectedRows < 1) {
      // if ordered amount of certificates is not in stock
      req.reject(409, "Sold out, sorry. Try another amount.");
    }
    await transaction.commit();
  });
};
