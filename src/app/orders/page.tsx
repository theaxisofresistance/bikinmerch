import {Suspense} from "react";import App from "@/components/App";
export default function OrdersPage(){return <Suspense fallback={<div className="container" style={{padding:40}}>Memuat pesanan…</div>}><App/></Suspense>}
