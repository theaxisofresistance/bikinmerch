import assert from "node:assert/strict";
import {test} from "node:test";
import {drawMovableText, hitText, moveText, textBoxes, type TextDesign} from "./design-text";

const design: TextDesign = {template: "weekend", font: "sans", title: "HELLO", subtitle: "WORLD", detail: "DETAIL"};
function context() {
  const calls: [string, ...unknown[]][] = [];
  const ctx = new Proxy({} as CanvasRenderingContext2D, {
    get: (_, key) => key === "measureText" ? () => ({width: 200}) : (...args: unknown[]) => calls.push([String(key), ...args]),
    set: (_, key, value) => {calls.push([String(key), value]); return true;},
  });
  return {ctx, calls};
}

test("legacy text keeps its position and each text can move independently", () => {
  const {ctx} = context();
  const legacy = textBoxes(ctx, design);
  const moved = textBoxes(ctx, {...design, textOffsets: {title: {x: 35, y: 80}}});
  assert.equal(moved[0].x - legacy[0].x, 35);
  assert.ok(Math.abs(moved[0].y - legacy[0].y - 80) < 0.001);
  assert.deepEqual(moved.slice(1), legacy.slice(1));
  assert.equal(hitText(moved, {x: moved[0].x + 2, y: moved[0].y + 2}), "title");
  assert.equal(hitText(moved, {x: 0, y: 0}), null);
  assert.deepEqual(textBoxes(ctx, {...design, template: ""}), []);
  assert.equal(textBoxes(ctx, {...design, title: ""}).length, 2);
});

test("dragging clamps the whole text box within printable artwork bounds", () => {
  const box = {key: "title" as const, x: 100, y: 150, width: 200, height: 60};
  assert.deepEqual(moveText(box, {x: 20, y: 30}, {x: -999, y: -999}), {x: -80, y: -120});
  assert.deepEqual(moveText(box, {x: 20, y: 30}, {x: 999, y: 999}), {x: 320, y: 570});
  assert.deepEqual(moveText(box, {x: 20, y: 30}, {x: 12, y: -8}), {x: 32, y: 22});
});

test("export rendering applies saved offsets and compensates for skewed running text", () => {
  const {ctx, calls} = context();
  drawMovableText(ctx, {...design, textOffsets: {title: {x: 30, y: 40}}}, "title", -95, 103, 530, "Arial");
  assert.ok(calls.some(call => JSON.stringify(call) === JSON.stringify(["translate", 30, 40])));
  assert.ok(calls.some(call => JSON.stringify(call) === JSON.stringify(["fillText", "HELLO", 0, -95])));
  calls.length = 0;
  drawMovableText(ctx, {...design, template: "running", textOffsets: {title: {x: 30, y: 40}}}, "title", -102, 112, 420, "Arial");
  assert.ok(calls.some(call => call[0] === "translate" && Math.abs(Number(call[1]) - 35.6) < 0.001 && call[2] === 40));
  assert.equal(calls.at(-1)?.[0], "restore");
});
