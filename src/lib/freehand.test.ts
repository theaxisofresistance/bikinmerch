import assert from "node:assert/strict";
import {test} from "node:test";
import {drawStrokes, printBounds} from "./freehand";

test("print area follows product, fit, side, position, and scale", () => {
  const center = {position: "center", scale: 100};
  const regular = printBounds("T-shirt", "regular", "front", center);
  assert.equal(regular.width, 285);
  assert.equal(regular.x + regular.width / 2, 500);
  assert.equal(regular.y + regular.height / 2, 440);
  assert.equal(printBounds("T-shirt", "oversized", "back", center).width, 330);
  for (const [name, width, y] of [
    ["Hoodie", 310, 540], ["Tote Bag", 315, 650],
    ["Mug", 280, 560], ["Notebook", 265, 535],
  ] as const) {
    const area = printBounds(name, "regular", "front", center);
    assert.equal(area.width, width);
    assert.equal(area.y + area.height / 2, y);
  }
  const chest = printBounds("T-shirt", "regular", "front", {position: "chest", scale: 100});
  assert.equal(chest.x + chest.width / 2, 610);
  assert.equal(chest.y + chest.height / 2, 360);
  assert.equal(printBounds("T-shirt", "regular", "back", {position: "chest", scale: 100}).x + chest.width / 2, 500);
  assert.equal(printBounds("T-shirt", "regular", "front", {position: "large", scale: 120}).width, 427.5);
  const toteChest = printBounds("Tote Bag", "regular", "front", {position: "chest", scale: 100});
  assert.equal(toteChest.y + toteChest.height / 2, 520);
  assert.ok(toteChest.y > 400, "small tote artwork belongs on the bag body below its handles");
  const toteLarge = printBounds("Tote Bag", "regular", "front", {position: "large", scale: 120});
  assert.equal(toteLarge.width, 400);
  assert.ok(toteLarge.y >= 400, "large tote artwork stays below the handle attachments");
  for (const side of ["front", "back"] as const) {
    const mug = printBounds("Mug", "regular", side, {position: "large", scale: 120});
    assert.equal(mug.x + mug.width / 2, side === "front" ? 416 : 584);
    assert.equal(mug.width, 360);
    assert.ok(mug.y >= 320 && mug.y + mug.height <= 800);
    const small = printBounds("Mug", "regular", side, {position: "chest", scale: 100});
    assert.equal(small.x + small.width / 2, side === "front" ? 416 : 584);
  }
});

test("strokes are clipped, scaled for export, and retain their color and width", () => {
  const calls: [string, ...unknown[]][] = [];
  const context = new Proxy({} as CanvasRenderingContext2D, {
    get: (_, key) => (...args: unknown[]) => calls.push([String(key), ...args]),
    set: (_, key, value) => { calls.push([String(key), value]); return true; },
  });
  drawStrokes(context, [
    {color: "#123456", width: 8, points: [{x: 10, y: 20}, {x: 40, y: 50}]},
    {color: "#ff0000", width: 4, points: [{x: 70, y: 80}]},
  ], 2400, 3000);
  assert.ok(calls.some(call => JSON.stringify(call) === JSON.stringify(["rect", 0, 0, 2400, 3000])));
  assert.ok(calls.some(call => JSON.stringify(call) === JSON.stringify(["scale", 4, 4])));
  assert.ok(calls.some(call => JSON.stringify(call) === JSON.stringify(["strokeStyle", "#123456"])));
  assert.ok(calls.some(call => JSON.stringify(call) === JSON.stringify(["lineWidth", 8])));
  assert.ok(calls.some(call => JSON.stringify(call) === JSON.stringify(["lineTo", 40, 50])));
  assert.ok(calls.some(call => call[0] === "arc" && call[1] === 70 && call[3] === 2));
  assert.equal(calls[0][0], "save");
  assert.equal(calls.at(-1)?.[0], "restore");
});

test("pin and goodie bag use their own printable surfaces",()=>{
 const design={position:"center",scale:100};
 const pin=printBounds("Pin Button","regular","front",design);
 assert.equal(pin.width,pin.height);
 assert.equal(pin.x+pin.width/2,500);
 const bag=printBounds("Goodie Bag","regular","front",design);
 assert.ok(bag.y>=400);
 assert.ok(bag.width<bag.height);
 assert.deepEqual(printBounds("Goodie Bag","regular","back",design),bag);
});

test("umbrella artwork stays within a canopy panel",()=>{
 const area=printBounds("Payung Custom","regular","front",{position:"center",scale:100});
 assert.equal(area.width/area.height,20/15);
 assert.equal(area.x+area.width/2,500);
 assert.ok(area.y>500 && area.y+area.height<900);
});
