const { GET, expect } = require("../../test").run("chinook");
const fs = require("fs");
const path = require("path");
const cds = require("@sap/cds/lib");
const { parser } = require("./parser");

let currentParserRes;
let newParserRes;
const $dispatch = cds.Service.prototype.dispatch;
cds.Service.prototype.dispatch = function (req, ...etc) {
  if (req.query && req._.req) {
    currentParserRes = req.query;
  }
  return $dispatch.call(this, req, ...etc);
};

const logParserResult = (result, testName) => {
  fs.writeFileSync(
    path.join(__dirname, `/log/${testName}.log.json`),
    JSON.stringify(result)
  );
};

describe("$filter", () => {
  // logger can be omitted
  afterEach(function () {
    logParserResult(newParserRes, `${this.currentTest.title}-new`);
    logParserResult(currentParserRes, `${this.currentTest.title}-cur`);
  });

  describe("comparing expressions", () => {
    it("should support 'eq' with decimal", async () => {
      const url = "Tracks?$filter=unitPrice eq 0.99";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'ne' with decimal", async () => {
      const url = "Tracks?$filter=unitPrice ne 0.99";
      await GET(`/browse-tracks/${url}`);

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

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'ne' with string", async () => {
      const url = "Tracks?$filter=name ne 'Restless and Wild'";
      await GET(`/browse-tracks/${url}`);

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

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'ge'", async () => {
      const url = "Tracks?$filter=unitPrice ge 1.00";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'lt'", async () => {
      const url = "Tracks?$filter=unitPrice lt 1.00";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'le'", async () => {
      const url = "Tracks?$filter=unitPrice le 1.00";
      await GET(`/browse-tracks/${url}`);

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

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support 'or'", async () => {
      const url =
        "Tracks?$filter=unitPrice le 1.00 or name eq 'Restless and Wild'";
      await GET(`/browse-tracks/${url}`);

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
    it("should support contains", async () => {
      const url = "Tracks?$filter=contains(name,'sun')";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support startswith", async () => {
      const url = "Tracks?$filter=startswith(name,'sun')";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support endswith", async () => {
      const url = "Tracks?$filter=endswith(name,'sun')";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support length", async () => {
      const url = "Tracks?$filter=length(name) eq 10";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support indexof", async () => {
      const url = "Tracks?$filter=indexof(name,'Restless and Wild') eq 4";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support substring", async () => {
      const url = "Tracks?$filter=substring(name,1) eq 'some'";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support tolower", async () => {
      const url = "Tracks?$filter=tolower(name) eq 'some'";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support toupper", async () => {
      const url = "Tracks?$filter=toupper(name) eq 'some'";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });

    it("should support trim", async () => {
      const url = "Tracks?$filter=trim(name) eq 'some'";
      await GET(`/browse-tracks/${url}`);

      newParserRes = parser.parse(url);

      expect(currentParserRes.SELECT.where).to.deep.equal(
        newParserRes.SELECT.where
      );
    });
  });
});
