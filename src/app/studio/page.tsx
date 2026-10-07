import {Suspense} from "react";import App from "@/components/App";
export default function StudioPage(){return <Suspense fallback={<div className="container" style={{padding:40}}>Memuat editor…</div>}><App/></Suspense>}
