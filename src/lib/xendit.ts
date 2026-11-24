export function paymentConfig() {
  const key = process.env.XENDIT_SECRET_KEY;
  const token = process.env.XENDIT_WEBHOOK_TOKEN;
  const origin = process.env.APP_URL;
  if (!key?.startsWith("xnd_development_") || !token || !origin) throw new Error("Xendit test configuration missing");
  if (new URL(origin).protocol !== "https:") throw new Error("APP_URL must use HTTPS");
  return {key, token, origin: new URL(origin).origin};
}

export async function createInvoice(id: string, amount: number, email: string, description: string) {
  const {key, origin} = paymentConfig();
  const response = await fetch("https://api.xendit.co/v2/invoices", {
    method: "POST", cache: "no-store",
    headers: {Authorization: `Basic ${Buffer.from(`${key}:`).toString("base64")}`, "Content-Type": "application/json"},
    body: JSON.stringify({external_id: id, amount, currency: "IDR", payer_email: email, description,
      invoice_duration: 3600, should_send_email: false,
      success_redirect_url: `${origin}/dashboard?payment=processing`, failure_redirect_url: `${origin}/dashboard?payment=pending`}),
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok) throw new Error("Xendit invoice request failed");
  const invoice = await response.json();
  if (!invoice.id || !invoice.invoice_url || invoice.external_id !== id || invoice.amount !== amount) throw new Error("Invalid invoice response");
  return invoice as {id: string; invoice_url: string};
}
