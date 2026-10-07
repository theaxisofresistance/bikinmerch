import {Suspense} from "react";import App from "@/components/App";
export default function AdminPage(){return <Suspense fallback={<div className="container" style={{padding:40}}>Memuat admin…</div>}><App/></Suspense>}
