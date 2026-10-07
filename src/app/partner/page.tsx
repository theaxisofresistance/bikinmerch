import {Suspense} from "react";import App from "@/components/App";
export default function PartnerPage(){return <Suspense fallback={<div className="container" style={{padding:40}}>Memuat antrean…</div>}><App/></Suspense>}
