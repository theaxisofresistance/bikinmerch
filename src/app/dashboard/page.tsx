import {Suspense} from "react";
import App from "@/components/App";
export default function DashboardPage() {
  return (
    <Suspense
      fallback={
        <div className="container" style={{padding: 40}}>
          Memuat dashboard…
        </div>
      }>
      <App />
    </Suspense>
  );
}
