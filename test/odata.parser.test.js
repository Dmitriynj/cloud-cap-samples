const fs = require("fs");
const path = require("path");
const { GET, POST, expect } = require("../test").run("chinook");
const { parser } = require("../chinook/parser/parser");

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

let currentParserRes;
let newParserRes;

const updateCurParserResult = () => {
  const data = fs.readFileSync(
    path.join(__dirname, `/../chinook/parser/log.json`)
  );
  currentParserRes = JSON.parse(data);
};

describe("$filter", () => {
  before("login user", async () => {
    const customerLoginResponse = await POST(
      "/users/login",
      {
        email: CURRENT_CUSTOMER_DATA.email,
        password: CURRENT_CUSTOMER_DATA.password,
      },
      DEFAULT_AXIOS_CONFIG
    );
    customerAccessToken = customerLoginResponse.data.accessToken;
  });

  after(() => {
    fs.unlinkSync(path.join(__dirname, `/../chinook/parser/log.json`));
  });

  const compWithCurParserRes = async (service, url) => {
    await GET(`/${service}/${url}`, {
      headers: {
        authorization: "Basic " + customerAccessToken,
      },
    });
    updateCurParserResult();

    newParserRes = parser.parse(url);

    expect(currentParserRes.SELECT.where).to.deep.equal(
      newParserRes.SELECT.where
    );
  };

  describe("comparing expressions", () => {
    it("should support 'eq' with decimal", async () => {
      const url = "Tracks?$filter=unitPrice eq 0.99";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should throw error when using 'eq' with decimal", async () => {
      const url = "Tracks?$filter=unitPrice eq 0.9.9";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "&", end of input, or space but "." found.`
        );
      }
    });

    it("should support 'ne' with decimal", async () => {
      const url = "Tracks?$filter=unitPrice ne 0.99";

      newParserRes = parser.parse(url);

      // new parser doesn't add 'is null'
      expect([
        {
          ref: ["unitPrice"],
        },
        "!=",
        {
          val: 0.99,
        },
      ]).to.deep.equal(newParserRes.SELECT.where);
    });

    it("should throw error there is double space before 'ne'", async () => {
      const url = "Tracks?$filter=unitPrice  ne 0.99";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "eq", "ge", "gt", "le", "lt", or "ne" but " " found.`
        );
      }
    });

    it("should support 'eq' with string", async () => {
      const url = "Tracks?$filter=name eq 'Restless and Wild'";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should throw error when using single quotation mark in string literal", async () => {
      const url = "Tracks?$filter=name eq 'Restles's and Wild'";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "&", end of input, or space but "s" found.`
        );
      }
    });

    it("should support 'ne' with string which contains quotation mark", async () => {
      const url = "Tracks?$filter=name ne 'Restles''s and Wild'";

      newParserRes = parser.parse(url);

      // new parser doesn't add 'is null'
      expect([
        {
          ref: ["name"],
        },
        "!=",
        {
          val: "Restles's and Wild",
        },
      ]).to.deep.equal(newParserRes.SELECT.where);
    });

    it("should throw error when there is no space before string literal", async () => {
      const url = "Tracks?$filter=name eq'Restles and Wild'";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(`Expected space but "'" found.`);
      }
    });

    it("should support 'gt'", async () => {
      const url = "Tracks?$filter=unitPrice gt 1.00";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should throw error when using 'gt' with string", async () => {
      const url = "Tracks?$filter=name gt 'Restle and Wild'";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "indexof", "length", "round", Edm.Decimal, Edm.Double, Edm.Int16, Edm.Int64, Edm.Single, Emd.Int32, or field name but "'" found.`
        );
      }
    });

    it("should support 'ge'", async () => {
      const url = "Tracks?$filter=unitPrice ge 1.00";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'lt'", async () => {
      const url = "Tracks?$filter=unitPrice lt 1.00";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'le'", async () => {
      const url = "Tracks?$filter=unitPrice le 1.00";
      await compWithCurParserRes("browse-tracks", url);
    });
  });

  describe("logical expressions", () => {
    it("should support 'and'", async () => {
      const url =
        "Tracks?$filter=unitPrice le 1.00 and name eq 'Restless and Wild'";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should throw an error when 'and' used with single expr", async () => {
      const url = "Tracks?$filter=unitPrice le 1.00 and";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected space but end of input found.`
        );
      }
    });

    it("should support 'or'", async () => {
      const url =
        "Tracks?$filter=unitPrice le 1.00 or name eq 'Restless and Wild'";

      newParserRes = parser.parse(url);

      // new parser does not adds extra brackets around expression
      expect([
        {
          ref: ["unitPrice"],
        },
        "<=",
        {
          val: 1,
        },
        "or",
        {
          ref: ["name"],
        },
        "=",
        {
          val: "Restless and Wild",
        },
      ]).to.deep.equal(newParserRes.SELECT.where);
    });

    it("should throw an error when using 'or' with only one expression", async () => {
      const url = "Tracks?$filter=or unitPrice le 1.00";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "eq", "ge", "gt", "le", "lt", or "ne" but "u" found.`
        );
      }
    });

    it("should support 'not'", async () => {
      const url = "Tracks?$select=ID&$filter=not contains(name,'sun')";

      newParserRes = parser.parse(url);

      // new parser adds 'not' operator to where clause before expr. each time.
      // current parser doing this [ {...}, 'not like', {...}, 'escape', ...]
      expect([
        "not",
        { ref: ["name"] },
        "like",
        { func: "concat", args: ["'%'", { val: "sun" }, "'%'"] },
        "escape",
        "'^'",
      ]).to.deep.equal(newParserRes.SELECT.where);
    });

    it("should throw an error when using 'not' without bool expression", async () => {
      const url = "Tracks?$select=ID&$filter=not unitPrice le 1.00";

      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "(", "contains", "endswith", "eq", "ge", "gt", "le", "lt", "ne", or "startswith" but "u" found.`
        );
      }
    });

    it("should support group expr", async () => {
      const url =
        "Tracks?$filter=(unitPrice le 1.00 and length(name) eq 12) or name eq 'Restless and Wild'";

      newParserRes = parser.parse(url);

      // new parser implementation is not optimize
      // expressions priority by removing unnecessary
      // brackets
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
    it("should support 'contains'", async () => {
      const url = "Tracks?$filter=contains(name,'sun')";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'contains' with tolower(...) func as a first arg", async () => {
      const url = "Tracks?$filter=contains(tolower(name),'sun')";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'contains' with str literal as a first arg and toupper(...) func as second", async () => {
      const url = "Tracks?$filter=contains('some',toupper('somesome'))";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should throw an error when using 'contains' with int32 arg", async () => {
      const url = "Tracks?$filter=contains('some',123)";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "concat", "substring", "tolower", "toupper", "trim", Edm.String, or field name but "1" found.`
        );
      }
    });

    it("should support 'startswith'", async () => {
      const url = "Tracks?$filter=startswith(name,'sun')";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'endswith'", async () => {
      const url = "Tracks?$filter=endswith(name,'sun')";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'length'", async () => {
      const url = "Tracks?$filter=length(name) eq 10";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should throw an error when comparing 'length' res with string literal", async () => {
      const url = "Tracks?$filter=length(name) eq 'some string'";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "indexof", "length", "round", Edm.Decimal, Edm.Double, Edm.Int16, Edm.Int64, Edm.Single, Emd.Int32, or field name but "'" found.`
        );
      }
    });

    it("should support 'indexof'", async () => {
      const url = "Tracks?$filter=indexof(name,'Restless and Wild') eq 4";

      newParserRes = parser.parse(url);

      // current parser increase numeric argument value.
      // but new parser will not
      expect([
        {
          func: "locate",
          args: [
            {
              ref: ["name"],
            },
            {
              val: "Restless and Wild",
            },
          ],
        },
        "=",
        {
          val: 4,
        },
      ]).to.deep.equal(newParserRes.SELECT.where);
    });

    it("should support 'substring'", async () => {
      const url = "Tracks?$filter=substring(name,1) eq 'some'";

      newParserRes = parser.parse(url);

      expect([
        {
          func: "substring",
          args: [
            {
              ref: ["name"],
            },
            {
              val: 1,
            },
          ],
        },
        "=",
        {
          val: "some",
        },
      ]).to.deep.equal(newParserRes.SELECT.where);
    });

    it("should support 'tolower'", async () => {
      const url = "Tracks?$filter=tolower(name) eq 'some'";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'toupper'", async () => {
      const url = "Tracks?$filter=toupper(name) eq 'some'";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'trim'", async () => {
      const url = "Tracks?$filter=trim(name) eq 'some'";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'concat'", async () => {
      const url =
        "Tracks?$filter=concat(concat(concat('track name: ',name),' and composer: '),composer) eq 'track name: Amazing and composer: Steven Tyler, Richie Supa'";
      await compWithCurParserRes("browse-tracks", url);
    });

    it("should support 'day'", async () => {
      const url = "Invoices?$filter=day(invoiceDate) eq 01";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should support 'hour'", async () => {
      const url = "Invoices?$filter=hour(invoiceDate) eq 09";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should throw error when using 'hour' with invalid value", async () => {
      const url = "Invoices?$filter=hour(invoiceDate) eq 24";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "0", "1", "2", or "3" but "4" found.`
        );
      }
    });

    it("should support 'minute'", async () => {
      const url = "Invoices?$filter=minute(invoiceDate) eq 09";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should throw an error when using 'minute' with invalid value", async () => {
      const url = "Invoices?$filter=minute(invoiceDate) eq 60";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "0", "1", "2", "3", "4", "5", or "minute" but "6" found.`
        );
      }
    });

    it("should support 'month'", async () => {
      const url = "Invoices?$filter=month(invoiceDate) eq 12";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should throw error when using 'month' with invalid value", async () => {
      const url = "Invoices?$filter=month(invoiceDate) eq 14";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "0", "1", or "2" but "4" found.`
        );
      }
    });

    it("should support 'second'", async () => {
      const url = "Invoices?$filter=second(invoiceDate) eq 59";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should throw error when using 'second' with invalid value", async () => {
      const url = "Invoices?$filter=second(invoiceDate) eq 60";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "0", "1", "2", "3", "4", "5", or "second" but "6" found.`
        );
      }
    });

    it("should support 'year'", async () => {
      const url = "Invoices?$filter=hour(invoiceDate) eq 09";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should throw error when using 'year' with invalid value", async () => {
      const url = "Invoices?$filter=year(invoiceDate) eq 60";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected digit but end of input found.`
        );
      }
    });

    it("should support 'time'", async () => {
      const url = "Invoices?$filter=time(invoiceDate) eq 11:45:32";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should throw error 'time' when using invalid time value", async () => {
      const url = "Invoices?$filter=time(invoiceDate) eq 11:4:32";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "time" or Edm.TimeOfDay but "1" found.`
        );
      }
    });

    it("should support 'round'", async () => {
      const url = "Invoices?$filter=round(total) eq 2";
      await compWithCurParserRes("browse-invoices", url);
    });

    it("should throw error using 'round' with invalid value", async () => {
      const url = "Invoices?$filter=round(total) eq 2.2.2";
      try {
        newParserRes = parser.parse(url);
      } catch (error) {
        expect(error.message).to.equal(
          `Expected "&", end of input, or space but "." found.`
        );
      }
    });
  });
});
