export type TextKey = "title" | "subtitle" | "detail";
export type TextOffset = {x: number; y: number};
export type TextDesign = {
  template: string;
  font: string;
  title: string;
  subtitle: string;
  detail: string;
  textOffsets?: Partial<Record<TextKey, TextOffset>>;
};
export type TextBox = {key: TextKey; x: number; y: number; width: number; height: number};
type Spec = [y: number, size: number, maxWidth: number, font: string, weight: number];

export function drawMovableText(
  ctx: CanvasRenderingContext2D, design: TextDesign, key: TextKey,
  y: number, size: number, maxWidth: number, font: string, weight = 800,
) {
  const offset = design.textOffsets?.[key] || {x: 0, y: 0};
  const skew = design.template === "running" && key !== "detail" ? -0.14 : 0;
  ctx.save();
  // Running's parent context is skewed; offsets still follow screen axes.
  ctx.translate(offset.x - skew * offset.y, offset.y);
  ctx.font = `${weight} ${size}px ${font}`;
  const measured = ctx.measureText(design[key]).width;
  if (measured > maxWidth) ctx.font = `${weight} ${size * maxWidth / measured}px ${font}`;
  ctx.fillText(design[key], 0, y);
  ctx.restore();
}

export function templateTextSpecs(design: TextDesign): Record<string, Spec[]> {
  const font = design.font === "serif" ? "Georgia, serif" : design.font === "sans" ? "Arial, sans-serif" : "Arial Narrow, Impact, sans-serif";
  const specs: Record<string, Spec[]> = {
    weekend: [[-95,103,530,font,800],[10,110,490,font,800],[142,20,470,"Arial",600]],
    afterhours: [[-127,126,470,font,800],[0,136,520,font,800],[127,21,475,"Arial",600]],
    ordinary: [[-50,98,510,design.font === "condensed" ? "Georgia" : font,400],[95,23,470,"Arial",600],[142,17,440,"Arial",400]],
    running: [[-102,112,420,font,800],[0,94,420,font,800],[127,20,447,"Arial",700]],
    bloom: [[-55,107,510,design.font === "condensed" ? "Georgia" : font,600],[63,24,460,"Arial",600],[203,19,450,"Arial",400]],
    good: [[-74,139,430,font,800],[37,41,415,font,800],[137,15,340,"Arial",600]],
  };
  return specs;
}

export function textBoxes(ctx: CanvasRenderingContext2D, design: TextDesign): TextBox[] {
  if (design.template === "") return [];
  const specs = templateTextSpecs(design);
  ctx.save();
  const boxes = (["title", "subtitle", "detail"] as TextKey[]).flatMap((key, index) => {
    if (!design[key]) return [];
    const [y, size, maxWidth, family, weight] = (specs[design.template] || specs.weekend)[index];
    ctx.font = `${weight} ${size}px ${family}`;
    const measured = ctx.measureText(design[key]).width;
    const height = size * Math.min(1, maxWidth / (measured || 1)) * 1.15;
    const width = Math.min(measured, maxWidth);
    const skew = design.template === "running" && key !== "detail" ? -0.14 : 0;
    const offset = design.textOffsets?.[key] || {x: 0, y: 0};
    const boundsWidth = width + Math.abs(skew) * height;
    return [{key, x: 300 + offset.x + skew * y - boundsWidth / 2 - 5,
      y: 375 + y + offset.y - height / 2 - 5, width: boundsWidth + 10, height: height + 10}];
  });
  ctx.restore();
  return boxes;
}

export function hitText(boxes: TextBox[], point: TextOffset): TextKey | null {
  return [...boxes].reverse().find(box => point.x >= box.x && point.x <= box.x + box.width && point.y >= box.y && point.y <= box.y + box.height)?.key || null;
}

export function moveText(box: TextBox, offset: TextOffset, delta: TextOffset): TextOffset {
  return {
    x: offset.x + Math.max(-box.x, Math.min(600 - box.x - box.width, delta.x)),
    y: offset.y + Math.max(-box.y, Math.min(750 - box.y - box.height, delta.y)),
  };
}
