import {test} from "node:test";
import assert from "node:assert/strict";
import {paymentConfig, createInvoice} from "./xendit";

test("test payment config rejects live keys and insecure return URLs", async () => {
  const old={...process.env}, fetcher=globalThis.fetch;
  try {
    process.env.XENDIT_SECRET_KEY="xnd_production_fake";
    process.env.XENDIT_WEBHOOK_TOKEN="test-token";
    process.env.APP_URL="https://example.com";
    assert.throws(paymentConfig);
    process.env.XENDIT_SECRET_KEY="xnd_development_fake";
    process.env.APP_URL="http://example.com";
    assert.throws(paymentConfig);
    process.env.APP_URL="https://example.com";
    globalThis.fetch=async (_url, options)=>{
      const body=JSON.parse(String(options?.body));
      assert.equal(body.amount,50000);
      assert.equal(body.currency,"IDR");
      assert.equal(body.external_id,"order-1");
      return new Response(JSON.stringify({id:"invoice-1",external_id:"wrong-order",amount:50000,invoice_url:"https://checkout.xendit.co/test"}));
    };
    await assert.rejects(()=>createInvoice("order-1",50000,"test@example.com","Order"));
  } finally {
    globalThis.fetch=fetcher;
    for(const key of ["XENDIT_SECRET_KEY","XENDIT_WEBHOOK_TOKEN","APP_URL"]) {
      if(old[key]===undefined)delete process.env[key];else process.env[key]=old[key];
    }
  }
});
