export type PenPoint = {x: number; y: number};
export type PenStroke = {color: string; width: number; points: PenPoint[]};

// Artwork coordinates are 600 × 750, independent of preview/export resolution.
export function drawStrokes(
  ctx: CanvasRenderingContext2D,
  strokes: PenStroke[] = [],
  width: number,
  height: number,
) {
  ctx.save();
  ctx.beginPath();
  ctx.rect(0, 0, width, height);
  ctx.clip();
  ctx.scale(width / 600, height / 750);
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  for (const stroke of strokes) {
    if (!stroke.points.length) continue;
    ctx.strokeStyle = stroke.color;
    ctx.fillStyle = stroke.color;
    ctx.lineWidth = stroke.width;
    const [first, ...rest] = stroke.points;
    ctx.beginPath();
    if (!rest.length) {
      ctx.arc(first.x, first.y, stroke.width / 2, 0, Math.PI * 2);
      ctx.fill();
    } else {
      ctx.moveTo(first.x, first.y);
      for (const point of rest) ctx.lineTo(point.x, point.y);
      ctx.stroke();
    }
  }
  ctx.restore();
}

export function printBounds(
  productName: string,
  fit: string,
  side: string,
  design: {position: string; scale: number},
) {
  const kind = productName.toLowerCase();
  let x = 500, y = 440, width = fit === "regular" ? 285 : 330;
  if(kind.includes("pin button")) return {x:300,y:305,width:400,height:400};
  if(kind.includes("goodie bag")) return {x:335,y:440,width:330,height:370};
  if(kind.includes("desk mat")) return {x:130,y:350,width:740,height:350};
  if(kind.includes("tumbler")) return {x:385,y:330,width:230,height:430};
  if (kind.includes("hoodie")) { y = 540; width = 310; }
  else if (kind.includes("tote")) { y = 650; width = 315; }
  else if (kind.includes("mug")) { x = side === "front" ? 416 : 584; y = 560; width = 280; }
  else if (!kind.includes("t-shirt")) { y = 535; width = 265; }
  if (design.position === "chest") {
    width *= 0.45;
    if (!kind.includes("mug")) x = kind.includes("t-shirt") && side === "front" ? 610 : 500;
    y = kind.includes("tote") ? 520 : kind.includes("mug") ? 450 : kind.includes("notebook") ? 350 : 360;
  }
  if (design.position === "large") width *= 1.25;
  width *= design.scale / 100;
  if (kind.includes("tote")) width = Math.min(width, 400);
  if (kind.includes("mug")) width = Math.min(width, 360);
  const height = width * 1.25;
  return {x: x - width / 2, y: y - height / 2, width, height};
}
