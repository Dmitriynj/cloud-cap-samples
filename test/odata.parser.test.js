const { GET, POST, expect } = require("../test").run("chinook");
const fs = require("fs");
const path = require("path");
const cds = require("@sap/cds/lib");
const { parser } = require("../chinook/parser/parser");

// process.env = {
//   ...process.env,
//   ACCESS_TOKEN_SECRET: "secret",
//   REFRESH_TOKEN_SECRET: "refresh-secret",
// };

const CURRENT_CUSTOMER_DATA = {
  ID: 2,
  email: "leonekohler@surfeu.de",
  password: "some",
  roles: ["customer"],
};
const DEFAULT_AXIOS_CONFIG = {
  headers: { "content-type": "application/json" },
};

let customerAccessToken;
let customerLoginResponse;

let currentParserRes;
let newParserRes;
// const $dispatch = cds.Service.prototype.dispatch;
// cds.Service.prototype.dispatch = function (req, ...etc) {
//   if (req.query && req._.req) {
//     currentParserRes = req.query;
//   }
//   return $dispatch.call(this, req, ...etc);
// };

// cds.on("served", async ({ db, messaging, ...servedServices }) => {
//   // add logging current user before any request
//   for (let i in servedServices) {
//     servedServices[i].prepend((srv) => {
//       srv.on("*", async (req, next) => {
//         if (req.query && req._.req) {
//           currentParserRes = req.query;
//         }

//         const result = await next();

//         return result;
//       });
//     });
//   }
// });

const logParserResult = (result, testName) => {
  fs.writeFileSync(
    path.join(__dirname, `/../chinook/parser/log/${testName}.log.json`),
    JSON.stringify(result)
  );
};

const updateCurParserResult = () => {
  const data = fs.readFileSync(
    path.join(__dirname, `/../chinook/parser/log/log.json`)
  );
  currentParserRes = JSON.parse(data);
};

describe("$filter", () => {
  // logger can be omitted
  // afterEach(function () {
  //   logParserResult(newParserRes, `${this.currentTest.title}-new`);
  //   logParserResult(currentParserRes, `${this.currentTest.title}-cur`);
  // });

  describe("comparing expressions", () => {
    it("should support 'eq' with decimal", async () => {
      const url = "Tracks?$filter=unitPrice eq 0.99";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'ne' with decimal", async () => {
      const url = "Tracks?$filter=unitPrice ne 0.99";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal([
        "(",
        ...newParserRes.SELECT.where,
        "or",
        {
          ref: ["unitPrice"],
        },
        "is null",
        ")",
      ]);
    });

    it("should support 'eq' with string", async () => {
      const url = "Tracks?$filter=name eq 'Restless and Wild'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'ne' with string", async () => {
      const url = "Tracks?$filter=name ne 'Restless and Wild'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal([
        "(",
        ...newParserRes.SELECT.where,
        "or",
        {
          ref: ["name"],
        },
        "is null",
        ")",
      ]);
    });

    it("should support 'gt'", async () => {
      const url = "Tracks?$filter=unitPrice gt 1.00";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'ge'", async () => {
      const url = "Tracks?$filter=unitPrice ge 1.00";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'lt'", async () => {
      const url = "Tracks?$filter=unitPrice lt 1.00";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'le'", async () => {
      const url = "Tracks?$filter=unitPrice le 1.00";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });
  });

  describe("logical expressions", () => {
    it("should support 'and'", async () => {
      const url =
        "Tracks?$filter=unitPrice le 1.00 and name eq 'Restless and Wild'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'or'", async () => {
      const url =
        "Tracks?$filter=unitPrice le 1.00 or name eq 'Restless and Wild'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal([
        "(",
        ...newParserRes.SELECT.where,
        ")",
      ]);
    });

    it("should support 'not'", async () => {
      const url = "Tracks?$select=ID&$filter=not contains(name,'sun')";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect([
        "not",
        { ref: ["name"] },
        "like",
        { func: "concat", args: ["'%'", { val: "sun" }, "'%'"] },
        "escape",
        "'^'",
      ]).to.deep.equal(newParserRes.SELECT.where);
    });

    it("should support group expr", async () => {
      const url =
        "Tracks?$filter=(unitPrice le 1.00 and length(name) eq 12) or name eq 'Restless and Wild'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect([
        "(",
        { ref: ["unitPrice"] },
        "<=",
        { val: 1 },
        "and",
        { func: "length", args: [{ ref: ["name"] }] },
        "=",
        { val: 12 },
        ")",
        "or",
        { ref: ["name"] },
        "=",
        { val: "Restless and Wild" },
      ]).to.deep.equal(newParserRes.SELECT.where);
    });
  });

  describe("function expressions", () => {
    before("login user", async () => {
      customerLoginResponse = await POST(
        "/users/login",
        {
          email: CURRENT_CUSTOMER_DATA.email,
          password: CURRENT_CUSTOMER_DATA.password,
        },
        DEFAULT_AXIOS_CONFIG
      );
      customerAccessToken = customerLoginResponse.data.accessToken;
    });

    it("should support contains", async () => {
      const url = "Tracks?$filter=contains(name,'sun')";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support startswith", async () => {
      const url = "Tracks?$filter=startswith(name,'sun')";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support endswith", async () => {
      const url = "Tracks?$filter=endswith(name,'sun')";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support length", async () => {
      const url = "Tracks?$filter=length(name) eq 10";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support indexof", async () => {
      const url = "Tracks?$filter=indexof(name,'Restless and Wild') eq 4";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support substring", async () => {
      const url = "Tracks?$filter=substring(name,1) eq 'some'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support tolower", async () => {
      const url = "Tracks?$filter=tolower(name) eq 'some'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support toupper", async () => {
      const url = "Tracks?$filter=toupper(name) eq 'some'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support trim", async () => {
      const url = "Tracks?$filter=trim(name) eq 'some'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support concat", async () => {
      const url =
        "Tracks?$filter=concat(concat(concat('track name: ',name),' and composer: '),composer) eq 'track name: Amazing and composer: Steven Tyler, Richie Supa'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support concat", async () => {
      const url =
        "Tracks?$filter=concat(concat(concat('track name: ',name),' and composer: '),composer) eq 'track name: Amazing and composer: Steven Tyler, Richie Supa'";
      await GET(`/browse-tracks/${url}`);
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support day", async () => {
      const url = "Invoices?$filter=day(invoiceDate) eq 1";
      await GET(`/browse-invoices/${url}`, {
        headers: {
          authorization: "Basic " + customerAccessToken,
        },
      });
      updateCurParserResult();

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });
  });
});
