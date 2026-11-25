"use client";

import {useCallback,useEffect,useMemo,useRef,useState} from "react";
import {ArrowLeft,Download,Pencil,Redo2,RotateCcw,Save,ShoppingCart,Undo2,X} from "lucide-react";
import {useRouter,useSearchParams} from "next/navigation";

import ElementControls from "./studio/ElementControls";
import {drawElements,fitElement,elementBox,hitElement,migrateElements,type DesignElement} from "@/lib/design-elements";
import {drawMovableText,textBoxes,hitText,moveText,type TextKey,type TextBox,type TextOffset} from "@/lib/design-text";
import {drawStrokes,printBounds,type PenStroke} from "@/lib/freehand";

type Product={id:string;name:string;image:string;basePrice:number;printArea:string;category?:string;variants?:{id:string;name:string;color:string;size:string;stock?:number}[]};
type Side="front"|"back";
type MockupKind="shirt"|"hoodie"|"tote"|"mug"|"notebook"|"deskmat"|"tumbler"|"pin"|"goodiebag"|"umbrella";
function mockupKind(productName:string):MockupKind{const name=productName.toLowerCase();return name.includes("payung")?"umbrella":name.includes("pin button")?"pin":name.includes("goodie bag")?"goodiebag":name.includes("desk mat")?"deskmat":name.includes("tumbler")?"tumbler":name.includes("hoodie")?"hoodie":name.includes("tote")?"tote":name.includes("mug")?"mug":name.includes("t-shirt")?"shirt":"notebook"}
type Design={elements?:DesignElement[];textOffsets?:Partial<Record<TextKey,TextOffset>>;strokes?:PenStroke[];enabled:boolean;template:string;title:string;subtitle:string;detail:string;ink:string;accent:string;font:"condensed"|"sans"|"serif";position:"chest"|"center"|"large";scale:number;logo:string|null};
type Project={fit:"regular"|"oversized";shirt:string;activeSide:Side;sides:Record<Side,Design>};

const templates=[
 {id:"weekend",name:"Weekend Society",category:"Komunitas",title:"WEEKEND",subtitle:"SOCIETY",detail:"GOOD PEOPLE. GREAT DAYS.",style:"arch",bg:"#e4ead9",ink:"#294f36",accent:"#b1cf6d"},
 {id:"afterhours",name:"After Hours",category:"Event",title:"AFTER",subtitle:"HOURS",detail:"MUSIC • PEOPLE • MEMORIES",style:"stack",bg:"#dddcef",ink:"#39216b",accent:"#fa724a"},
 {id:"ordinary",name:"Less, But Better",category:"Brand",title:"ordinary.",subtitle:"STUFF WITH SOUL",detail:"EST. 2026 / JAKARTA",style:"minimal",bg:"#ece5db",ink:"#342f2a",accent:"#bd744e"},
 {id:"running",name:"Sunday Run Club",category:"Komunitas",title:"SUNDAY",subtitle:"RUN CLUB",detail:"YOUR PACE. YOUR PEOPLE.",style:"sport",bg:"#e6ecc7",ink:"#293829",accent:"#81a82c"},
 {id:"bloom",name:"In My Own Time",category:"Personal",title:"BLOOM",subtitle:"IN YOUR OWN TIME",detail:"NO RUSH. JUST GROW.",style:"serif",bg:"#f0deda",ink:"#913e41",accent:"#ed9584"},
 {id:"good",name:"Good Things Ahead",category:"Personal",title:"GOOD",subtitle:"THINGS AHEAD",detail:"TAKE IT ONE DAY AT A TIME",style:"badge",bg:"#dce8ee",ink:"#1c5068",accent:"#e9a640"}
] as const;
const palettes=[["#294f36","#b1cf6d"],["#242424","#f4eee1"],["#39216b","#fa724a"],["#913e41","#ed9584"],["#f4eee1","#c6f34b"]];
const shirts=[["#f5f3ea","Putih tulang"],["#27292a","Hitam"],["#a5af8e","Sage"],["#aab9ca","Biru"],["#eee0c9","Sand"]];
const baseDesign:Design={enabled:true,template:"weekend",title:"WEEKEND",subtitle:"SOCIETY",detail:"GOOD PEOPLE. GREAT DAYS.",ink:"#294f36",accent:"#b1cf6d",font:"condensed",position:"center",scale:100,logo:null};
const initialProject:Project={fit:"oversized",shirt:"#f4f1eb",activeSide:"front",sides:{front:{...baseDesign},back:{...baseDesign,enabled:false,position:"large"}}};
const clone=<T,>(value:T):T=>JSON.parse(JSON.stringify(value));
const fontFamily=(s:Design)=>s.font==="serif"?"Georgia, serif":s.font==="sans"?"Arial, sans-serif":"Arial Narrow, Impact, sans-serif";

function drawDesign(ctx:CanvasRenderingContext2D,s:Design,width:number,height:number,logo?:HTMLImageElement){if(!s.enabled)return;const t=s.template===""?undefined:templates.find(x=>x.id===s.template)||templates[0];ctx.save();ctx.translate(width/2,height/2);const factor=Math.min(width/600,height/750);ctx.scale(factor,factor);ctx.textAlign="center";ctx.textBaseline="middle";ctx.fillStyle=s.ink;const family=fontFamily(s);
 if(t?.style==="arch"){ctx.strokeStyle=s.ink;ctx.lineWidth=3;ctx.beginPath();ctx.arc(0,-40,188,Math.PI*1.06,Math.PI*1.94);ctx.stroke();drawMovableText(ctx,s,"title",-95,103,530,family);drawMovableText(ctx,s,"subtitle",10,110,490,family);ctx.fillStyle=s.accent;ctx.fillRect(-165,83,330,8);ctx.fillStyle=s.ink;drawMovableText(ctx,s,"detail",142,20,470,"Arial",600)}
 if(t?.style==="stack"){ctx.fillStyle=s.accent;ctx.save();ctx.rotate(-.06);ctx.fillRect(-246,-183,492,122);ctx.restore();ctx.fillStyle=s.ink;drawMovableText(ctx,s,"title",-127,126,470,family);drawMovableText(ctx,s,"subtitle",0,136,520,family);drawMovableText(ctx,s,"detail",127,21,475,"Arial",600);ctx.fillRect(-215,79,430,3)}
 if(t?.style==="minimal"){drawMovableText(ctx,s,"title",-50,98,510,s.font==="condensed"?"Georgia":family,400);ctx.fillRect(-27,36,54,3);drawMovableText(ctx,s,"subtitle",95,23,470,"Arial",600);drawMovableText(ctx,s,"detail",142,17,440,"Arial",400)}
 if(t?.style==="sport"){ctx.strokeStyle=s.ink;ctx.lineWidth=5;ctx.strokeRect(-244,-193,488,370);ctx.save();ctx.transform(1,0,-.14,1,0,0);drawMovableText(ctx,s,"title",-102,112,420,family);drawMovableText(ctx,s,"subtitle",0,94,420,family);ctx.restore();ctx.fillStyle=s.accent;ctx.fillRect(-244,76,488,101);ctx.fillStyle=s.ink;drawMovableText(ctx,s,"detail",127,20,447,"Arial",700)}
 if(t?.style==="serif"){ctx.strokeStyle=s.accent;ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(0,-26,236,193,-.2,0,Math.PI*2);ctx.stroke();drawMovableText(ctx,s,"title",-55,107,510,s.font==="condensed"?"Georgia":family,600);drawMovableText(ctx,s,"subtitle",63,24,460,"Arial",600);drawMovableText(ctx,s,"detail",203,19,450,"Arial",400)}
 if(t?.style==="badge"){ctx.fillStyle=s.accent;ctx.beginPath();ctx.arc(0,-25,215,0,Math.PI*2);ctx.fill();ctx.fillStyle=s.ink;drawMovableText(ctx,s,"title",-74,139,430,family);drawMovableText(ctx,s,"subtitle",37,41,415,family);ctx.fillRect(-110,90,220,3);drawMovableText(ctx,s,"detail",137,15,340,"Arial",600)}
 if(logo){const ratio=logo.width/logo.height;const w=Math.min(170,110*ratio),h=w/ratio;ctx.drawImage(logo,-w/2,235,w,h)}ctx.restore();drawStrokes(ctx,s.strokes,width,height)}

function TemplateCard({template,active,onClick}:{template:typeof templates[number];active:boolean;onClick:()=>void}){const ref=useRef<HTMLCanvasElement>(null);useEffect(()=>{const c=ref.current;if(!c)return;const ctx=c.getContext("2d");if(!ctx)return;ctx.fillStyle=template.bg;ctx.fillRect(0,0,c.width,c.height);drawDesign(ctx,{...baseDesign,...template,font:"condensed",logo:null},c.width,c.height)},[template]);return <button className={`ms-template${active?" active":""}`} onClick={onClick}><canvas ref={ref} width="280" height="312"/><strong>{template.name}</strong><small>{template.category}</small></button>}

export default function Studio({products,user,onLogin}:{products:Product[];user:any;onLogin:()=>void}){
 const search=useSearchParams(),router=useRouter();
 const [penActive,setPenActive]=useState(false),[penColor,setPenColor]=useState("#242424"),[penWidth,setPenWidth]=useState(8);
 const [selectedText,setSelectedText]=useState<TextKey|null>(null),[editingText,setEditingText]=useState<TextKey|null>(null);
 const [selectedElement,setSelectedElement]=useState<string|null>(null);
 const [canvasLayout,setCanvasLayout]=useState({left:0,top:0,scale:1});
 const componentDrag=useRef<{pointer:number;start:TextOffset;element:DesignElement;before:Project}|null>(null);
 const textDrag=useRef<{pointerId:number;key:TextKey;start:TextOffset;offset:TextOffset;box:TextBox;before:Project;wasDirty:boolean;moved:boolean}|null>(null);
 const draftStroke=useRef<PenStroke|null>(null),drawingPointer=useRef<number|null>(null),previewFrame=useRef<number|null>(null);
 const canvasRef=useRef<HTMLCanvasElement>(null),mockupImages=useRef<Record<MockupKind,Partial<Record<Side,HTMLImageElement>>>>({shirt:{},hoodie:{},tote:{},mug:{},notebook:{},deskmat:{},tumbler:{},pin:{},goodiebag:{},umbrella:{}}),logoImages=useRef(new Map<string,HTMLImageElement>()),history=useRef<Project[]>([]),future=useRef<Project[]>([]);
 const [project,setProject]=useState<Project>(initialProject),[designName,setDesignName]=useState("Desain tanpa judul"),[category,setCategory]=useState("Semua"),[toast,setToast]=useState(""),[dirty,setDirty]=useState(false),[savedId,setSavedId]=useState(""),[busy,setBusy]=useState(false),[downloadOpen,setDownloadOpen]=useState(false),[orderOpen,setOrderOpen]=useState(false),[orderQty,setOrderQty]=useState(1),[orderAddress,setOrderAddress]=useState(""),[variantId,setVariantId]=useState(""),[exportSide,setExportSide]=useState<Side>("front"),[ready,setReady]=useState(false),[,forceHistory]=useState(0);
 const product=products.find(item=>item.id===search.get("product"))||products.find(item=>item.name.toLowerCase().includes("t-shirt"))||products[0],state=project.sides[project.activeSide];
 useEffect(()=>{setSelectedText(null);setEditingText(null)},[project.activeSide,product?.id]);
 useEffect(()=>{
  const canvas=canvasRef.current;if(!canvas)return;
  const update=()=>{const rect=canvas.getBoundingClientRect(),parent=canvas.parentElement!.getBoundingClientRect(),scale=Math.min(rect.width/1000,rect.height/1100);setCanvasLayout({left:rect.left-parent.left+(rect.width-1000*scale)/2,top:rect.top-parent.top+(rect.height-1100*scale)/2,scale})};
  const observer=new ResizeObserver(update);observer.observe(canvas);update();return()=>observer.disconnect();
 },[]);
 useEffect(()=>{let active=true;const sources=Object.values(project.sides).flatMap(d=>(d.elements||[]).flatMap(e=>e.type==="image"?[e.src]:[]));Promise.all(sources.map(src=>new Promise<void>((resolve)=>{if(logoImages.current.has(src)){resolve();return}const img=new Image();img.onload=()=>{logoImages.current.set(src,img);resolve()};img.onerror=()=>resolve();img.src=src}))).then(()=>{if(active){const target=canvasRef.current;if(target){const ctx=target.getContext("2d");if(ctx){const mockup=mockupCanvas(project.activeSide);if(mockup){ctx.clearRect(0,0,1000,1100);ctx.drawImage(mockup,0,0)}}}}});return()=>{active=false}},[project]);
 useEffect(()=>{
  const ctx=canvasRef.current?.getContext("2d");if(!ctx)return;
  const needs=Object.values(project.sides).some(d=>d.enabled&&d.template!==""&&Boolean(d.title||d.subtitle||d.detail));if(!needs)return;
  setProject(current=>{const next=clone(current);for(const side of ["front","back"] as Side[]){const d=next.sides[side];if(!d.enabled||d.template===""||!(d.title||d.subtitle||d.detail))continue;const converted=migrateElements(ctx,{...d,elements:undefined,logo:null});d.elements=[...converted,...(d.elements||[])];d.title="";d.subtitle="";d.detail=""}return next});
 },[project]);
 const productColors=useMemo(()=>{const values=product?.variants?.map(v=>[v.color,v.name.split("/").pop()?.trim()||v.name] as [string,string])||[];return values.filter((entry,index)=>values.findIndex(value=>value[0]===entry[0])===index)},[product]);
 const notify=(message:string)=>{setToast(message);window.setTimeout(()=>setToast(""),2800)};
 const mutate=useCallback((change:(next:Project)=>void)=>{setProject(current=>{history.current.push(clone(current));if(history.current.length>50)history.current.shift();future.current=[];const next=clone(current);change(next);return next});setDirty(true);forceHistory(v=>v+1)},[]);
 const designCanvas=useCallback((design:Design)=>{const c=document.createElement("canvas");c.width=2400;c.height=3000;drawDesign(c.getContext("2d")!,design,c.width,c.height,design.logo?logoImages.current.get(design.logo):undefined);drawElements(c.getContext("2d")!,design.elements,c.width,c.height,logoImages.current);return c},[]);
 const mockupCanvas=useCallback((side:Side,background=false)=>{
  if(!product)return null;
  const c=document.createElement("canvas");c.width=1000;c.height=1100;
  const ctx=c.getContext("2d")!;
  if(background){ctx.fillStyle="#f1f2ee";ctx.fillRect(0,0,1000,1100)}
  const kind=mockupKind(product.name);
  const images=mockupImages.current[kind],photo=images[side],mask=kind==="shirt"?images.front:photo;
  if(!photo||!mask)return null;
  const width=kind==="shirt"&&project.fit==="regular"?790:930,height=kind==="deskmat"?700:930,x=(1000-width)/2,y=kind==="deskmat"?180:40;
  const surface=document.createElement("canvas");surface.width=1000;surface.height=1100;
  const material=surface.getContext("2d")!;
  material.drawImage(mask,x,y,width,height);
  material.globalCompositeOperation="source-in";
  material.fillStyle=project.shirt;material.fillRect(0,0,1000,1100);
  material.globalCompositeOperation="multiply";material.drawImage(photo,x,y,width,height);
  material.globalCompositeOperation="destination-in";material.drawImage(mask,x,y,width,height);
  ctx.save();ctx.shadowColor="#1b271820";ctx.shadowBlur=28;ctx.shadowOffsetY=20;ctx.drawImage(surface,0,0);ctx.restore();
  const design=project.sides[side];
  if(design.enabled){
   const area=printBounds(product.name,project.fit,side,design);
   if(kind==="shirt")ctx.drawImage(designCanvas(design),area.x,area.y,area.width,area.height);
   else{
    const artwork=document.createElement("canvas");artwork.width=1000;artwork.height=1100;
    const ink=artwork.getContext("2d")!;ink.drawImage(designCanvas(design),area.x,area.y,area.width,area.height);
    ink.globalCompositeOperation="destination-in";ink.drawImage(photo,x,y,width,height);
    ctx.save();ctx.globalCompositeOperation="multiply";ctx.drawImage(artwork,0,0);ctx.restore();
   }
  }
  return c;
 },[project,product,designCanvas]);
 const renderPreview=useCallback(()=>{const target=canvasRef.current;if(!target)return;const ctx=target.getContext("2d")!;ctx.clearRect(0,0,target.width,target.height);const mockup=mockupCanvas(project.activeSide);if(mockup)ctx.drawImage(mockup,0,0);if(penActive&&product){const area=printBounds(product.name,project.fit,project.activeSide,state);ctx.save();ctx.strokeStyle="#7e9e3e";ctx.lineWidth=2;ctx.setLineDash([8,6]);ctx.strokeRect(area.x,area.y,area.width,area.height);ctx.restore();if(draftStroke.current){ctx.save();ctx.translate(area.x,area.y);drawStrokes(ctx,[draftStroke.current],area.width,area.height);ctx.restore()}}if(!penActive&&selectedText&&state.enabled&&product){const box=textBoxes(ctx,state).find(item=>item.key===selectedText);if(box){const area=printBounds(product.name,project.fit,project.activeSide,state),scale=area.width/600;ctx.save();ctx.strokeStyle="#6c5ce7";ctx.lineWidth=2;ctx.strokeRect(area.x+box.x*scale,area.y+box.y*scale,box.width*scale,box.height*scale);ctx.restore()}}},[mockupCanvas,project.activeSide,project.fit,penActive,product,state,selectedText]);
 useEffect(()=>{
  if(!product)return;
  let mounted=true;const kind=mockupKind(product.name);setReady(false);
  Promise.all((["front","back"] as Side[]).map(side=>new Promise<void>((resolve,reject)=>{
   if(mockupImages.current[kind][side]){resolve();return}
   const img=new Image();img.decoding="async";
   img.onload=()=>{mockupImages.current[kind][side]=img;resolve()};img.onerror=reject;
   img.src=`/studio/${kind}${side==="back"?"-back":""}.png`;
  }))).then(()=>{if(mounted)setReady(true)}).catch(()=>{if(mounted)notify("Mockup gagal dimuat. Muat ulang halaman.")});
  return()=>{mounted=false};
 },[product?.name]);
 useEffect(()=>{renderPreview()},[renderPreview,ready]);
 useEffect(()=>{if(!search.get("design"))setSavedId("")},[product?.id,search]);
 useEffect(()=>{const id=search.get("design");if(!id||!user)return;let active=true;setBusy(true);fetch(`/api/designs?id=${encodeURIComponent(id)}`).then(async response=>{const data=await response.json();if(!response.ok)throw new Error(data.error||"Desain gagal dibuka.");if(!active)return;const next=data.canvas as Project;if(!next?.sides?.front||!next?.sides?.back)throw new Error("Format desain tidak didukung.");for(const side of ["front","back"] as Side[]){const logo=next.sides[side].logo;if(logo&&!logoImages.current.has(logo)){const image=await new Promise<HTMLImageElement>((resolve,reject)=>{const value=new Image();value.onload=()=>resolve(value);value.onerror=reject;value.src=logo});logoImages.current.set(logo,image)}}setProject(next);setDesignName(data.name);setSavedId(data.id);setDirty(false);history.current=[];future.current=[];if(data.productId!==search.get("product"))router.replace(`/studio?product=${data.productId}&design=${data.id}`,{scroll:false})}).catch(error=>active&&notify(error instanceof Error?error.message:"Desain gagal dibuka.")).finally(()=>active&&setBusy(false));return()=>{active=false}},[search,user,router]);
 useEffect(()=>{const warn=(e:BeforeUnloadEvent)=>{if(dirty)e.preventDefault()};window.addEventListener("beforeunload",warn);return()=>window.removeEventListener("beforeunload",warn)},[dirty]);
 function chooseTemplate(id:string){const t=templates.find(x=>x.id===id);if(!t)return;mutate(next=>Object.assign(next.sides[next.activeSide],{enabled:true,template:t.id,title:t.title,subtitle:t.subtitle,detail:t.detail,ink:t.ink,accent:t.accent,textOffsets:{}}));setSelectedText(null);setEditingText(null);notify(`Template diterapkan ke sisi ${project.activeSide==="front"?"depan":"belakang"}.`)}
 function undo(){const previous=history.current.pop();if(!previous)return;future.current.push(clone(project));setProject(previous);setDirty(true);forceHistory(v=>v+1)}
 function redo(){const next=future.current.pop();if(!next)return;history.current.push(clone(project));setProject(next);setDirty(true);forceHistory(v=>v+1)}
 async function uploadLogo(file?:File){if(!file)return;if(!["image/png","image/jpeg","image/webp"].includes(file.type)||file.size>4*1024*1024){notify("Pilih PNG, JPG, atau WebP maksimal 4 MB.");return}try{const data=await new Promise<string>((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(String(reader.result));reader.onerror=reject;reader.readAsDataURL(file)});const img=await new Promise<HTMLImageElement>((resolve,reject)=>{const value=new Image();value.onload=()=>resolve(value);value.onerror=reject;value.src=data});logoImages.current.set(data,img);mutate(next=>{next.sides[next.activeSide].logo=data});notify("Gambar ditambahkan ke desain.")}catch{notify("Gambar gagal dibuka.")}}
 async function save():Promise<string|null>{if(!user){onLogin();return null}if(user.role!=="CREATOR"){notify("Masuk dengan akun Creator untuk menyimpan desain.");return null}if(!product){notify("Produk belum tersedia.");return null}if(!designName.trim()){notify("Nama desain wajib diisi.");return null}const preview=mockupCanvas("front",true)?.toDataURL("image/png",.75);setBusy(true);try{const response=await fetch("/api/designs",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({id:savedId||undefined,productId:product.id,name:designName,canvas:project,preview})});const data=await response.json();if(!response.ok)throw new Error(data.error||"Desain gagal disimpan.");setSavedId(data.id);localStorage.setItem(`merch-studio-project-${product.id}`,JSON.stringify(project));setDirty(false);router.replace(`/studio?product=${product.id}&design=${data.id}`,{scroll:false});notify(`${designName} berhasil disimpan.`);return data.id}catch(error){notify(error instanceof Error?error.message:"Desain gagal disimpan.");return null}finally{setBusy(false)}}
 async function orderDesign(e:React.FormEvent){e.preventDefault();if(!product)return;const id=await save();if(!id)return;setBusy(true);try{const response=await fetch("/api/orders",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({designId:id,variantId:variantId||product.variants?.[0]?.id,quantity:orderQty,shippingAddress:orderAddress})});const data=await response.json();if(!response.ok)throw new Error(data.error||"Pesanan gagal dibuat.");if(!data.paymentUrl)throw new Error("Tautan pembayaran belum tersedia.");window.location.assign(data.paymentUrl)}catch(error){notify(error instanceof Error?error.message:"Pesanan gagal dibuat.")}finally{setBusy(false)}}
 async function openSaved(){if(!product)return;try{const raw=localStorage.getItem(`merch-studio-project-${product.id}`);if(!raw){notify(`Belum ada desain ${product.name} tersimpan di browser ini.`);return}const next=JSON.parse(raw) as Project;for(const side of ["front","back"] as Side[]){const logo=next.sides[side].logo;if(logo&&!logoImages.current.has(logo)){const img=await new Promise<HTMLImageElement>((resolve,reject)=>{const value=new Image();value.onload=()=>resolve(value);value.onerror=reject;value.src=logo});logoImages.current.set(logo,img)}}history.current.push(clone(project));setProject(next);setDirty(false);notify(`Desain ${product.name} berhasil dibuka.`)}catch{notify("Desain tersimpan tidak bisa dibuka.")}}
 function download(canvas:HTMLCanvasElement|null,name:string){if(!canvas){notify("Mockup belum siap.");return}canvas.toBlob(blob=>{if(!blob)return;const url=URL.createObjectURL(blob),a=document.createElement("a");a.href=url;a.download=name;a.click();window.setTimeout(()=>URL.revokeObjectURL(url),30000)},"image/png")}
 function combined(){const front=mockupCanvas("front",true),back=mockupCanvas("back",true);if(!front||!back)return null;const c=document.createElement("canvas");c.width=2000;c.height=1100;const ctx=c.getContext("2d")!;ctx.drawImage(front,0,0);ctx.drawImage(back,1000,0);return c}
 function penPoint(event:React.MouseEvent<HTMLCanvasElement>){
  if(!product)return null;
  const canvas=event.currentTarget,rect=canvas.getBoundingClientRect();
  // Match the contained canvas image even when CSS constrains its height.
  const scale=Math.min(rect.width/1000,rect.height/1100),left=rect.left+(rect.width-1000*scale)/2,top=rect.top+(rect.height-1100*scale)/2;
  const area=printBounds(product.name,project.fit,project.activeSide,state);
  return {x:((event.clientX-left)/scale-area.x)/area.width*600,y:((event.clientY-top)/scale-area.y)/area.height*750};
 }
 function startPen(event:React.PointerEvent<HTMLCanvasElement>){
  if(!penActive||event.button!==0||drawingPointer.current!==null)return;
  const point=penPoint(event);if(!point||point.x<0||point.x>600||point.y<0||point.y>750)return;
  event.preventDefault();event.currentTarget.setPointerCapture(event.pointerId);drawingPointer.current=event.pointerId;
  draftStroke.current={color:penColor,width:penWidth,points:[point]};renderPreview();
 }
 function movePen(event:React.PointerEvent<HTMLCanvasElement>){
  if(drawingPointer.current!==event.pointerId||!draftStroke.current)return;
  const point=penPoint(event);if(!point)return;
  draftStroke.current.points.push(point);
  if(previewFrame.current===null)previewFrame.current=requestAnimationFrame(()=>{previewFrame.current=null;renderPreview()});
 }
 function finishPen(event:React.PointerEvent<HTMLCanvasElement>){
  if(drawingPointer.current!==event.pointerId)return;
  const stroke=draftStroke.current;draftStroke.current=null;drawingPointer.current=null;
  if(event.currentTarget.hasPointerCapture(event.pointerId))event.currentTarget.releasePointerCapture(event.pointerId);
  if(previewFrame.current!==null){cancelAnimationFrame(previewFrame.current);previewFrame.current=null}
  if(stroke&&event.type!=="pointercancel")mutate(next=>{const design=next.sides[next.activeSide];if(!design.enabled){design.enabled=true;design.template="";design.logo=null;design.strokes=[]}design.strokes=[...(design.strokes||[]),stroke]});
  else renderPreview();
 }
 function currentTextBoxes(){const ctx=canvasRef.current?.getContext("2d");return ctx&&state.enabled?textBoxes(ctx,state):[]}
 function startText(event:React.PointerEvent<HTMLCanvasElement>){
  if(event.button!==0||textDrag.current||!state.enabled)return;
  const point=penPoint(event);if(!point)return;
  const ctx=canvasRef.current!.getContext("2d")!,id=hitElement((state.elements||[]).map(e=>elementBox(ctx,e)),point),element=state.elements?.find(e=>e.id===id);
  if(element){setSelectedElement(element.id);setSelectedText(null);event.currentTarget.setPointerCapture(event.pointerId);componentDrag.current={pointer:event.pointerId,start:point,element:clone(element),before:clone(project)};return}
  const boxes=currentTextBoxes(),key=hitText(boxes,point);setSelectedText(key);setEditingText(null);
  if(!key)return;
  event.preventDefault();event.currentTarget.focus();event.currentTarget.setPointerCapture(event.pointerId);
  textDrag.current={pointerId:event.pointerId,key,start:point,offset:state.textOffsets?.[key]||{x:0,y:0},box:boxes.find(box=>box.key===key)!,before:clone(project),wasDirty:dirty,moved:false};
 }
 function dragText(event:React.PointerEvent<HTMLCanvasElement>){
  const component=componentDrag.current;if(component){const point=penPoint(event),ctx=canvasRef.current?.getContext("2d");if(!point||!ctx)return;const moved=fitElement(ctx,{...component.element,x:component.element.x+point.x-component.start.x,y:component.element.y+point.y-component.start.y});setProject(current=>({...current,sides:{...current.sides,[current.activeSide]:{...current.sides[current.activeSide],elements:(current.sides[current.activeSide].elements||[]).map(e=>e.id===moved.id?moved:e)}}}));setDirty(true);return}

  const drag=textDrag.current,point=penPoint(event);if(!point)return;if(!drag){event.currentTarget.dataset.textHover=String(Boolean(hitText(currentTextBoxes(),point)));return}if(drag.pointerId!==event.pointerId)return;
  const delta={x:point.x-drag.start.x,y:point.y-drag.start.y};
  if(!drag.moved&&Math.hypot(delta.x,delta.y)<2)return;
  const offset=moveText(drag.box,drag.offset,delta);drag.moved=true;
  setProject(current=>({...current,sides:{...current.sides,[current.activeSide]:{...current.sides[current.activeSide],textOffsets:{...current.sides[current.activeSide].textOffsets,[drag.key]:offset}}}}));setDirty(true);
 }
 function finishText(event:React.PointerEvent<HTMLCanvasElement>){
  const component=componentDrag.current;if(component){componentDrag.current=null;if(event.currentTarget.hasPointerCapture(event.pointerId))event.currentTarget.releasePointerCapture(event.pointerId);if(event.type==="pointercancel")setProject(component.before);else{history.current.push(component.before);future.current=[]}return}

  const drag=textDrag.current;if(!drag||drag.pointerId!==event.pointerId)return;textDrag.current=null;
  if(event.currentTarget.hasPointerCapture(event.pointerId))event.currentTarget.releasePointerCapture(event.pointerId);
  if(event.type==="pointercancel"){setProject(drag.before);setDirty(drag.wasDirty)}
  else if(drag.moved){history.current.push(drag.before);if(history.current.length>50)history.current.shift();future.current=[];forceHistory(value=>value+1)}
 }
 function textKeyDown(event:React.KeyboardEvent<HTMLCanvasElement>){
  if(penActive||!selectedText)return;
  if(event.key==="Escape"){setSelectedText(null);setEditingText(null);return}
  if(event.key==="Enter"){event.preventDefault();setEditingText(selectedText);return}
  const directions:Record<string,TextOffset>={ArrowLeft:{x:-1,y:0},ArrowRight:{x:1,y:0},ArrowUp:{x:0,y:-1},ArrowDown:{x:0,y:1}};
  const direction=directions[event.key],box=currentTextBoxes().find(item=>item.key===selectedText);if(!direction||!box)return;
  event.preventDefault();const step=event.shiftKey?10:1,offset=moveText(box,state.textOffsets?.[selectedText]||{x:0,y:0},{x:direction.x*step,y:direction.y*step});mutate(next=>{const design=next.sides[next.activeSide];design.textOffsets={...design.textOffsets,[selectedText]:offset}});
 }
 function editorStyle(){
  const box=currentTextBoxes().find(item=>item.key===editingText);if(!box||!product)return {};
  const area=printBounds(product.name,project.fit,project.activeSide,state),scale=canvasLayout.scale;
  return {left:canvasLayout.left+(area.x+box.x*area.width/600)*scale,top:canvasLayout.top+(area.y+box.y*area.height/750)*scale,width:Math.max(140,box.width*area.width/600*scale),maxWidth:"calc(100% - 24px)"};
 }
 useEffect(()=>()=>{if(previewFrame.current!==null)cancelAnimationFrame(previewFrame.current)},[]);
 function changeElement(element:DesignElement){const ctx=canvasRef.current?.getContext("2d");if(!ctx)return;mutate(next=>{const d=next.sides[next.activeSide];d.elements=(d.elements||[]).map(item=>item.id===element.id?fitElement(ctx,element):item)})}
 function addTextbox(){const id=crypto.randomUUID();mutate(next=>{const d=next.sides[next.activeSide];d.enabled=true;d.elements=[...(d.elements||[]),{id,type:"text",text:"Teks baru",x:140,y:300,width:320,fontSize:48,fontFamily:"Arial, sans-serif",color:d.ink,weight:700,align:"center"}]});setSelectedElement(id)}
 async function uploadElement(file?:File,replaceId?:string){if(!file)return;if(!["image/png","image/jpeg","image/webp"].includes(file.type)||file.size>4194304){notify("Pilih PNG, JPG, WebP maksimal 4 MB.");return}try{const src=await new Promise<string>((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(String(r.result));r.onerror=reject;r.readAsDataURL(file)});const image=await new Promise<HTMLImageElement>((resolve,reject)=>{const i=new Image();i.onload=()=>resolve(i);i.onerror=reject;i.src=src});logoImages.current.set(src,image);const id=replaceId||crypto.randomUUID(),width=Math.min(300,300*image.width/image.height);mutate(next=>{const d=next.sides[next.activeSide];d.enabled=true;const element:DesignElement={id,type:"image",src,name:file.name,x:150,y:200,width,height:width*image.height/image.width};d.elements=replaceId?(d.elements||[]).map(item=>item.id===id?element:item):[...(d.elements||[]),element]});setSelectedElement(id)}catch{notify("Gambar gagal dibuka.")}}
 const filtered=useMemo(()=>templates.filter(t=>category==="Semua"||t.category===category),[category]);

 return <div className="merch-studio-page">
  <main className="ms-main">
   <aside className="ms-sidebar"><a className="ms-back-link" href="/dashboard"><ArrowLeft size={15}/> Kembali ke dashboard</a><div className="ms-eyebrow">MULAI DARI YANG LO SUKA</div><h1>Ide lo. Kaos lo.</h1><p className="ms-muted">Pilih desain, bikin jadi punya lo.</p>
    <section className="ms-product-picker"><div className="ms-eyebrow">01 / PRODUK</div><h2>Pilih merchandise</h2><div className="ms-product-list">{products.map(item=><button key={item.id} className={product?.id===item.id?"active":""} onClick={()=>{setDesignName(`Desain ${item.name}`);router.replace(`/studio?product=${item.id}`,{scroll:false})}}><img src={item.image} alt=""/><span><strong>{item.name}</strong><small>{item.category||"Merchandise"} · {new Intl.NumberFormat("id-ID",{style:"currency",currency:"IDR",maximumFractionDigits:0}).format(item.basePrice)}</small></span></button>)}</div></section>
    <section className="ms-garment"><div className="ms-eyebrow">02 / VARIAN</div><h2>{product?.name||"Produk"}</h2>{product?.name.toLowerCase().includes("t-shirt")&&<div className="ms-segmented">{(["regular","oversized"] as const).map(f=><button key={f} className={project.fit===f?"active":""} onClick={()=>mutate(n=>{n.fit=f})}>{f==="regular"?"Regular":"Oversized"}</button>)}</div>}<div className="ms-swatches">{(productColors.length?productColors:shirts).map(([color,label])=><button key={`${color}-${label}`} className={`ms-swatch${project.shirt===color?" active":""}`} style={{background:color}} aria-label={label} title={label} onClick={()=>mutate(n=>{n.shirt=color})}/>)}</div><div className="ms-color-label">Area cetak: {product?.printArea}</div><p className="ms-hint">Warna berlaku untuk sisi depan dan belakang.</p></section>
    <div className="ms-template-head"><div className="ms-eyebrow">03 / TEMPLATE DESAIN</div><h2>Pilih gaya lo</h2><p className="ms-hint">Untuk sisi {project.activeSide==="front"?"depan":"belakang"}</p></div><div className="ms-categories">{["Semua","Komunitas","Event","Brand","Personal"].map(c=><button key={c} className={category===c?"active":""} onClick={()=>setCategory(c)}>{c}</button>)}</div><div className="ms-templates">{filtered.map(t=><TemplateCard key={t.id} template={t} active={state.enabled&&state.template===t.id} onClick={()=>chooseTemplate(t.id)}/>)}</div><button className="ms-open" onClick={openSaved}><RotateCcw size={14}/> Buka versi browser</button><a className="ms-saved-link" href="/designs">Lihat semua desain tersimpan →</a>
   </aside>
   <section className="ms-workspace"><div className="ms-workspace-top"><input className="ms-design-name" value={designName} maxLength={80} aria-label="Nama desain" onChange={e=>{setDesignName(e.target.value);setDirty(true)}}/><div><button onClick={undo} disabled={!history.current.length} aria-label="Urungkan"><Undo2 size={18}/></button><button onClick={redo} disabled={!future.current.length} aria-label="Ulangi"><Redo2 size={18}/></button><button className="ms-toolbar-action" onClick={save} disabled={busy}><Save size={15}/>{busy?"Menyimpan…":"Simpan"}</button><button className="ms-toolbar-action" onClick={()=>{if(!user){onLogin();return}if(user.role!=="CREATOR"){notify("Pemesanan dari Studio khusus akun Creator.");return}setVariantId(product?.variants?.[0]?.id||"");setOrderOpen(true)}}><ShoppingCart size={15}/> Pesan</button><button className="ms-toolbar-action ms-primary" onClick={()=>{setExportSide(project.activeSide);setDownloadOpen(true)}}><Download size={15}/> Download</button></div></div><div className="ms-side-switch">{(["front","back"] as Side[]).map(side=><button key={side} className={project.activeSide===side?"active":""} onClick={()=>setProject(p=>({...p,activeSide:side}))}><strong>{side==="front"?"Depan":"Belakang"}</strong><small>{project.sides[side].enabled?"Ada desain":"Kosong"}</small></button>)}</div><div className={`ms-preview${penActive?" ms-drawing":" ms-text-canvas"}`}><canvas ref={canvasRef} width="1000" height="1100" aria-label="Kanvas desain merchandise" tabIndex={0} onKeyDown={textKeyDown} onDoubleClick={event=>{if(penActive)return;const point=penPoint(event);if(!point)return;const key=hitText(currentTextBoxes(),point);setSelectedText(key);setEditingText(key)}} onPointerDown={penActive?startPen:startText} onPointerMove={penActive?movePen:dragText} onPointerUp={penActive?finishPen:finishText} onPointerCancel={penActive?finishPen:finishText} onLostPointerCapture={penActive?finishPen:finishText}/>{editingText&&!penActive&&state.enabled&&<input className="ms-inline-text" style={editorStyle()} autoFocus aria-label="Edit teks terpilih" maxLength={editingText==="title"?30:editingText==="subtitle"?40:65} value={state[editingText]} onFocus={event=>event.target.select()} onChange={event=>mutate(next=>{next.sides[next.activeSide][editingText]=event.target.value})} onBlur={()=>setEditingText(null)} onKeyDown={event=>{if(event.key==="Enter"||event.key==="Escape"){event.preventDefault();setEditingText(null);canvasRef.current?.focus()}}}/>}<span><b>{project.activeSide==="front"?"DEPAN":"BELAKANG"}</b> · MOCKUP</span></div><div className="ms-workspace-bottom"><span>✦ Desain bagus, nggak perlu ribet.</span><span>{dirty?"Ada perubahan":savedId?"Tersimpan di akun":"Belum disimpan"}</span></div></section>
   <section className="ms-controls"><ElementControls elements={state.elements||[]} selectedId={selectedElement} onSelect={setSelectedElement} onAddText={addTextbox} onUpload={uploadElement} onChange={changeElement} onRemove={()=>mutate(next=>{const d=next.sides[next.activeSide];d.elements=(d.elements||[]).filter(item=>item.id!==selectedElement)})} onReorder={direction=>mutate(next=>{const items=next.sides[next.activeSide].elements||[],index=items.findIndex(item=>item.id===selectedElement),target=index+direction;if(index>=0&&target>=0&&target<items.length)[items[index],items[target]]=[items[target],items[index]]})} penTools={<div className="ms-pen-tools"><button type="button" className={`ms-pen-toggle${penActive?" active":""}`} aria-pressed={penActive} onClick={()=>{setPenActive(value=>!value);setSelectedText(null);setEditingText(null)}}><Pencil size={17}/> Pen freestyle</button>{penActive&&<><label className="ms-field"><span>Warna pen</span><input type="color" value={penColor} onChange={event=>setPenColor(event.target.value)}/></label><label className="ms-field"><span className="ms-size-label">Ketebalan <output>{penWidth} px</output></span><input type="range" min="1" max="40" value={penWidth} onChange={event=>setPenWidth(Number(event.target.value))}/></label><p className="ms-hint">Gambar di dalam garis putus-putus dengan mouse, sentuhan, atau stylus. Gunakan Undo untuk membatalkan goresan.</p><button type="button" className="ms-remove" disabled={!state.strokes?.length} onClick={()=>mutate(next=>{next.sides[next.activeSide].strokes=[]})}>Hapus semua goresan</button></>}</div>}/><div className="ms-eyebrow">BIKIN JADI PUNYA LO</div><h2>Desain {project.activeSide==="front"?"depan":"belakang"}</h2><button className="ms-clear" disabled={!state.enabled} onClick={()=>mutate(n=>{n.sides[n.activeSide].enabled=false})}>Kosongkan sisi ini</button></section>
  </main>
  <div className={`ms-toast${toast?" visible":""}`}>{toast}</div>
  {downloadOpen&&<div className="ms-dialog-backdrop" onMouseDown={e=>e.target===e.currentTarget&&setDownloadOpen(false)}><div className="ms-dialog"><button className="ms-dialog-close" onClick={()=>setDownloadOpen(false)}><X size={18}/></button><div className="ms-eyebrow">PUNYA LO, SIAP DIBAWA</div><h2>Download desain</h2><p className="ms-muted">Download desain per sisi atau lihat satu kaos lengkap.</p><label className="ms-field"><span>Sisi yang diunduh</span><select value={exportSide} onChange={e=>setExportSide(e.target.value as Side)}><option value="front">Depan</option><option value="back">Belakang</option></select></label><button className="ms-download-option" disabled={!project.sides[exportSide].enabled} onClick={()=>download(designCanvas(project.sides[exportSide]),`bikinmerch-desain-${exportSide}.png`)}><strong>Desain transparan ↗</strong><small>PNG · 2400 × 3000 px · tanpa kaos</small></button><button className="ms-download-option" onClick={()=>download(mockupCanvas(exportSide,true),`bikinmerch-mockup-${exportSide}.png`)}><strong>Mockup kaos ↗</strong><small>PNG · 1000 × 1100 px · untuk preview</small></button><button className="ms-download-option" onClick={()=>download(combined(),"bikinmerch-mockup-depan-belakang.png")}><strong>Mockup depan + belakang ↗</strong><small>PNG · 2000 × 1100 px · dua sisi berdampingan</small></button><p className="ms-export-note">Untuk produksi, konfirmasi ukuran dan resolusi ke vendor cetak. Mockup hanya perkiraan tampilan.</p></div></div>}
  {orderOpen&&product&&<div className="ms-dialog-backdrop" onMouseDown={e=>e.target===e.currentTarget&&setOrderOpen(false)}><form className="ms-dialog" onSubmit={orderDesign}><button type="button" className="ms-dialog-close" onClick={()=>setOrderOpen(false)}><X size={18}/></button><div className="ms-eyebrow">PESAN HASIL DESAINMU</div><h2>Checkout produksi</h2><div className="ms-order-summary"><strong>{designName}</strong><span>{product.name}</span><b>{new Intl.NumberFormat("id-ID",{style:"currency",currency:"IDR",maximumFractionDigits:0}).format(product.basePrice*orderQty)}</b></div><label className="ms-field"><span>Varian produk</span><select required value={variantId} onChange={e=>setVariantId(e.target.value)}>{product.variants?.map(variant=><option key={variant.id} value={variant.id}>{variant.name} · stok {variant.stock??"tersedia"}</option>)}</select></label><label className="ms-field"><span>Jumlah</span><input required type="number" min="1" max="10" value={orderQty} onChange={e=>setOrderQty(Math.max(1,Math.min(10,Number(e.target.value)||1)))}/></label><label className="ms-field"><span>Alamat pengiriman</span><textarea required rows={4} value={orderAddress} onChange={e=>setOrderAddress(e.target.value)} placeholder="Nama penerima, jalan, kecamatan, kota, kode pos"/></label><p className="ms-hint">Pembayaran melalui Xendit test mode. Produksi dimulai setelah pembayaran dikonfirmasi.</p><button className="ms-order-submit" disabled={busy||!variantId||!orderAddress.trim()}><ShoppingCart size={16}/>{busy?"Memproses…":"Lanjut ke pembayaran"}</button></form></div>}
 </div>
}
