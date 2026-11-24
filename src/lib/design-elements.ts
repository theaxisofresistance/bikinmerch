import {templateTextSpecs, type TextDesign, type TextKey} from "./design-text";

type ElementBase = {id: string; x: number; y: number; width: number; source?: "template"};
export type TextElement = ElementBase & {type: "text"; text: string; fontSize: number; fontFamily: string; color: string; weight: number; align: "left" | "center" | "right"; skew?: number};
export type ImageElement = ElementBase & {type: "image"; src: string; name: string; height: number};
export type DesignElement = TextElement | ImageElement;
export type ElementBox = {key: string; x: number; y: number; width: number; height: number};

export function textLines(ctx: CanvasRenderingContext2D, element: TextElement): string[] {
  ctx.font = `${element.weight} ${element.fontSize}px ${element.fontFamily}`;
  const lines: string[] = [];
  for (const paragraph of element.text.split("\n")) {
    let line = "";
    for (const char of paragraph) {
      if (line && ctx.measureText(line + char).width > element.width) {lines.push(line); line = "";}
      line += char;
    }
    lines.push(line);
  }
  return lines;
}

export function elementBox(ctx: CanvasRenderingContext2D, element: DesignElement): ElementBox {
  ctx.save();
  const height = element.type === "image" ? element.height : textLines(ctx, element).length * element.fontSize * 1.2;
  ctx.restore();
  return {key: element.id, x: element.x, y: element.y, width: element.width, height};
}

export function fitElement(ctx: CanvasRenderingContext2D, element: DesignElement): DesignElement {
  const next = {...element};
  next.width = Math.max(20, Math.min(600, next.width));
  if (next.type === "text") next.fontSize = Math.max(8, Math.min(150, next.fontSize));
  else {
    const ratio = element.type === "image" ? element.height / element.width : 1;
    next.height = next.width * ratio;
    if (next.height > 750) {next.height = 750; next.width = 750 / ratio;}
  }
  const box = elementBox(ctx, next);
  next.x = Math.max(0, Math.min(600 - box.width, next.x));
  next.y = Math.max(0, Math.min(750 - Math.min(750, box.height), next.y));
  return next;
}

export function hitElement(boxes: ElementBox[], point: {x: number; y: number}): string | null {
  return [...boxes].reverse().find(box => point.x >= box.x && point.x <= box.x + box.width && point.y >= box.y && point.y <= box.y + box.height)?.key || null;
}

export function migrateElements(ctx: CanvasRenderingContext2D, design: TextDesign & {ink: string; logo: string | null; elements?: DesignElement[]}, logo?: HTMLImageElement): DesignElement[] {
  if (design.elements) return design.elements as DesignElement[];
  const elements: DesignElement[] = [];
  if (design.template !== "") {
    const specs = templateTextSpecs(design), spec = specs[design.template] || specs.weekend;
    ctx.save();
    (["title", "subtitle", "detail"] as TextKey[]).forEach((key, i) => {
      if (!design[key]) return;
      const [y, size, width, fontFamily, weight] = spec[i];
      ctx.font = `${weight} ${size}px ${fontFamily}`;
      const fontSize = size * Math.min(1, width / (ctx.measureText(design[key]).width || 1));
      const offset = design.textOffsets?.[key] || {x: 0, y: 0};
      const skew = design.template === "running" && key !== "detail" ? -0.14 : 0;
      elements.push({id: `template-${key}`, type: "text", source: "template", text: design[key], x: 300 + offset.x + skew * y - width / 2,
        y: 375 + y + offset.y - fontSize * 0.6, width, fontSize, fontFamily, weight, color: design.ink, align: "center", skew});
    });
    ctx.restore();
  }
  if (design.logo && logo) {
    const width = Math.min(170, 110 * logo.width / logo.height), height = width * logo.height / logo.width;
    elements.push({id: "legacy-logo", type: "image", src: design.logo, name: "Logo", x: 300 - width / 2, y: 610, width, height});
  }
  return elements;
}

export function drawElements(ctx: CanvasRenderingContext2D, elements: DesignElement[] = [], width: number, height: number, images: Map<string, HTMLImageElement>) {
  ctx.save();
  ctx.beginPath();ctx.rect(0, 0, width, height);ctx.clip();
  ctx.scale(width / 600, height / 750);
  for (const element of elements) {
    ctx.save();
    if (element.type === "image") {
      const image = images.get(element.src);
      if (image) ctx.drawImage(image, element.x, element.y, element.width, element.height);
    } else {
      const lines = textLines(ctx, element), lineHeight = element.fontSize * 1.2;
      ctx.beginPath();ctx.rect(element.x, element.y, element.width, Math.min(750 - element.y, lineHeight * lines.length));ctx.clip();
      ctx.fillStyle = element.color;ctx.textAlign = element.align;ctx.textBaseline = "middle";
      const anchor = element.align === "center" ? element.width / 2 : element.align === "right" ? element.width : 0;
      ctx.translate(element.x + anchor, element.y + lineHeight / 2);
      if (element.skew) ctx.transform(1, 0, element.skew, 1, 0, 0);
      lines.forEach((line, i) => ctx.fillText(line, 0, i * lineHeight));
    }
    ctx.restore();
  }
  ctx.restore();
}
