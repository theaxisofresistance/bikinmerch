import {Suspense} from "react";import App from "@/components/App";
export default function Home(){return <Suspense fallback={<div className="container" style={{padding:40}}>Memuat BikinMerch…</div>}><App/></Suspense>}
