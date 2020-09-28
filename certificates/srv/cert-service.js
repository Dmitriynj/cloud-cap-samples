const cds = require("@sap/cds");

module.exports = async function () {
  const db = await cds.connect.to("db"); // connect to database service
  const { Orders, Certificates } = db.entities; // get reflected definitions

  this.before("*", (req) => {
    console.log(
      "[USER]:",
      req.user.id,
      " [LEVEL]: ",
      req.user.attr.level,
      "[ROLE]",
      req.user.is("user") ? "user" : "other"
    );
  });

  // user can read only his orders
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

  // user can cancel only his order
  this.on("cancelOrder", async (req) => {
    const { ID } = req.data;
    const order = await db.run(
      SELECT.one(Orders).where({
        ID,
      })
    );

    if (order && order.createdBy !== req.user.id) {
      req.reject(403);
    } else if (!order) {
      req.reject(400, "No such order");
    }

    return await db.run(
      DELETE.from(Orders).where({
        ID,
      })
    );
  });
};
