import type {ReactNode} from "react";
import {ArrowDown, ArrowUp, ImagePlus, Trash2, Type} from "lucide-react";
import type {DesignElement, TextElement} from "@/lib/design-elements";

export function TextboxEditor({element, onChange}: {element: TextElement; onChange: (next: DesignElement) => void}) {
  return <>
    <label className="ms-field"><span>Isi textbox</span><textarea rows={3} maxLength={500} value={element.text} onChange={e=>onChange({...element,text:e.target.value})}/></label>
    <label className="ms-field"><span>Jenis huruf</span><select value={element.fontFamily} onChange={e=>onChange({...element,fontFamily:e.target.value})}>
      <option value="Arial, sans-serif">Arial</option><option value="Georgia, serif">Georgia</option><option value="Arial Narrow, Impact, sans-serif">Impact</option><option value="Georgia">Georgia klasik</option><option value="Arial">Arial klasik</option>
    </select></label>
    <label className="ms-field"><span>Ukuran huruf · {Math.round(element.fontSize)} px</span><input type="range" min="8" max="150" value={element.fontSize} onChange={e=>onChange({...element,fontSize:Number(e.target.value)})}/></label>
    <label className="ms-field"><span>Warna teks</span><input type="color" value={element.color} onChange={e=>onChange({...element,color:e.target.value})}/></label>
    <div className="ms-element-row"><label className="ms-field"><span>Ketebalan</span><select value={element.weight} onChange={e=>onChange({...element,weight:Number(e.target.value)})}><option value="400">Normal</option><option value="600">Medium</option><option value="700">Bold</option><option value="800">Extra bold</option></select></label>
      <label className="ms-field"><span>Rata teks</span><select value={element.align} onChange={e=>onChange({...element,align:e.target.value as TextElement["align"]})}><option value="left">Kiri</option><option value="center">Tengah</option><option value="right">Kanan</option></select></label></div>
  </>;
}

export default function ElementControls({elements, selectedId, onSelect, onAddText, onUpload, onChange, onRemove, onReorder, penTools}: {
  penTools?: ReactNode;
  elements: DesignElement[]; selectedId: string | null; onSelect: (id: string) => void; onAddText: () => void;
  onUpload: (file?: File, replaceId?: string) => void; onChange: (element: DesignElement) => void; onRemove: () => void; onReorder: (direction: number) => void;
}) {
  const selected = elements.find(element=>element.id===selectedId);
  return <section className="ms-element-controls">
    <div className="ms-group-title">Properti komponen</div>
    <div className="ms-element-actions"><button type="button" onClick={onAddText}><Type size={16}/>Tambah textbox</button><label className="ms-element-upload"><ImagePlus size={16}/>Tambah gambar<input type="file" accept="image/png,image/jpeg,image/webp" onChange={e=>{onUpload(e.target.files?.[0]);e.target.value=""}}/></label>{penTools}</div>
    <p className="ms-hint">Pilih komponen, lalu geser di kanvas. Klik dua kali textbox untuk mengedit. PNG, JPG, WebP · maks. 4 MB.</p>
    <div className="ms-element-list" aria-label="Daftar komponen">{[...elements].reverse().map(element=><button type="button" key={element.id} className={selectedId===element.id?"active":""} aria-pressed={selectedId===element.id} onClick={()=>onSelect(element.id)}>{element.type==="text"?<Type size={15}/>:<ImagePlus size={15}/>}<span>{element.type==="text"?element.text||"Textbox kosong":element.name}</span></button>)}</div>
    {!selected && <p className="ms-hint">Pilih teks atau gambar di kanvas untuk mengubah propertinya.</p>}
    {selected && <div className="ms-element-editor">
      {selected.type==="text"?<TextboxEditor element={selected} onChange={onChange}/>:<><img className="ms-element-thumbnail" src={selected.src} alt={selected.name}/><label className="ms-element-upload">Ganti gambar<input type="file" accept="image/png,image/jpeg,image/webp" onChange={e=>{onUpload(e.target.files?.[0],selected.id);e.target.value=""}}/></label></>}
      <label className="ms-field"><span>{selected.type==="text"?"Lebar textbox":"Ukuran gambar"} · {Math.round(selected.width)} px</span><input type="range" min="20" max="600" value={selected.width} onChange={e=>onChange({...selected,width:Number(e.target.value),...(selected.type==="image"?{height:Number(e.target.value)*selected.height/selected.width}:{})})}/></label>
      <div className="ms-element-row"><label className="ms-field"><span>Posisi X</span><input type="number" min="0" max="600" value={Math.round(selected.x)} onChange={e=>onChange({...selected,x:Number(e.target.value)})}/></label><label className="ms-field"><span>Posisi Y</span><input type="number" min="0" max="750" value={Math.round(selected.y)} onChange={e=>onChange({...selected,y:Number(e.target.value)})}/></label></div>
      <div className="ms-element-actions"><button type="button" onClick={()=>onReorder(-1)}><ArrowDown size={14}/>Ke belakang</button><button type="button" onClick={()=>onReorder(1)}><ArrowUp size={14}/>Ke depan</button></div>
      <button type="button" className="ms-element-delete" onClick={onRemove}><Trash2 size={15}/>Hapus komponen</button>
    </div>}
  </section>;
}
