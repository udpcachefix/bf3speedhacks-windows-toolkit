
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

const launcherBundles = [
  { launcher: 'Start-Windows-Cleanup-GUI.cmd', bundle: 'files/bundles/Windows-Cleanup-GUI.zip' },
  { launcher: 'Run-Universal-Network-Reset-MTU1492.cmd', bundle: 'files/bundles/Universal-Network-Reset-MTU1492.zip' },
  { launcher: 'Apply_NVIDIA_Inspector_Settings.cmd', bundle: 'files/bundles/NVIDIA-Inspector-Toolkit.zip' },
  { launcher: 'Revert_NVIDIA_Inspector_Settings_Only.cmd', bundle: 'files/bundles/NVIDIA-Inspector-Toolkit.zip' }
];

function routeLauncherDownloads(){
 document.querySelectorAll('a[href]').forEach(link=>{
   const href=decodeURIComponent(link.getAttribute('href')||'');
   const match=launcherBundles.find(item=>href.endsWith(item.launcher));
   if(!match) return;
   link.setAttribute('href', match.bundle);
   link.setAttribute('download', '');
   if(/^download/i.test((link.textContent||'').trim())) link.textContent='Download complete bundle (.zip)';
 });
}

document.addEventListener('DOMContentLoaded',()=>{
 ['search','category','risk'].forEach(id=>document.getElementById(id)?.addEventListener('input',filterTools));
 routeLauncherDownloads();
});
