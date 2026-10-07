import {Suspense} from "react";import App from "@/components/App";
export default function StorePage(){return <Suspense fallback={<div className="container" style={{padding:40}}>Memuat storefront…</div>}><App/></Suspense>}
