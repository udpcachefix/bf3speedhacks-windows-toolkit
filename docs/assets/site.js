
function filterTools(){
 const q=(document.getElementById('search')?.value||'').toLowerCase();
 const c=(document.getElementById('category')?.value||'').toLowerCase();
 const r=(document.getElementById('risk')?.value||'').toLowerCase();
 document.querySelectorAll('[data-tool]').forEach(el=>{
   const hay=(el.dataset.search||'').toLowerCase();
   const okQ=!q||hay.includes(q), okC=!c||(el.dataset.category||'').toLowerCase()===c, okR=!r||(el.dataset.risk||'').toLowerCase()===r;
   el.style.display=(okQ&&okC&&okR)?'block':'none';
 });
}
document.addEventListener('DOMContentLoaded',()=>{['search','category','risk'].forEach(id=>document.getElementById(id)?.addEventListener('input',filterTools));});
