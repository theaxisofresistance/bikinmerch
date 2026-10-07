import {Suspense} from "react";
import App from "@/components/App";

export default function SavedDesignsPage(){
 return <Suspense fallback={<div className="container" style={{padding:40}}>Memuat desain…</div>}><App/></Suspense>;
}
