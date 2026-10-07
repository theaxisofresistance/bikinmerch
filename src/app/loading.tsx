export default function Loading(){
 return <div className="skeleton-page" aria-busy="true" aria-label="Memuat halaman">
  <div className="skeleton-header"><div className="sk sk-logo"/><div className="sk-nav"><i className="sk"/><i className="sk"/><i className="sk"/></div><div className="sk sk-user"/></div>
  <main className="skeleton-content"><div className="sk sk-kicker"/><div className="sk sk-title"/><div className="sk sk-subtitle"/><div className="skeleton-cards">{Array.from({length:6},(_,index)=><div className="skeleton-card" key={index}><i className="sk sk-image"/><i className="sk sk-line wide"/><i className="sk sk-line"/></div>)}</div></main>
 </div>;
}
