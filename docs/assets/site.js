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

const relatedBundles = [
  {name:'Windows-Cleanup-GUI.zip',members:[
    ['files/toolbox/cleanup/Start-Windows-Cleanup-GUI.cmd','Start-Windows-Cleanup-GUI.cmd'],
    ['files/toolbox/cleanup/Windows-Orphan-Cleanup-Audit.ps1','Windows-Orphan-Cleanup-Audit.ps1']
  ]},
  {name:'Universal-Network-Reset-MTU1492.zip',members:[
    ['files/toolbox/network/reset/Run-Universal-Network-Reset-MTU1492.cmd','Run-Universal-Network-Reset-MTU1492.cmd'],
    ['files/toolbox/network/reset/Universal-Network-Reset-MTU1492.ps1','Universal-Network-Reset-MTU1492.ps1']
  ]},
  {name:'NVIDIA-Inspector-Toolkit.zip',members:[
    ['files/toolbox/nvidia/inspector/Apply_NVIDIA_Inspector_Settings.cmd','Apply_NVIDIA_Inspector_Settings.cmd'],
    ['files/toolbox/nvidia/inspector/Revert_NVIDIA_Inspector_Settings_Only.cmd','Revert_NVIDIA_Inspector_Settings_Only.cmd'],
    ['files/toolbox/nvidia/inspector/NVIDIA_Inspector_Settings.nip','NVIDIA_Inspector_Settings.nip'],
    ['files/toolbox/nvidia/inspector/NVIDIA_Inspector_Default.nip','NVIDIA_Inspector_Default.nip'],
    ['files/toolbox/nvidia/inspector/inspector.exe','inspector.exe']
  ]},
  {name:'Chocolatey-Package-Installer.zip',members:[
    ['files/scripts/Install-ChocolateyPackages.ps1','scripts/Install-ChocolateyPackages.ps1'],
    ['files/packages/chocolatey-packages.txt','packages/chocolatey-packages.txt']
  ]},
  {name:'Windows11-EnergyMode-Workaround.zip',members:[
    ['files/experimental/power/Apply-EnergyModeWorkaround.reg','Apply-EnergyModeWorkaround.reg'],
    ['files/experimental/power/Set-HighPerformance.cmd','Set-HighPerformance.cmd'],
    ['files/experimental/power/Restore-EnergyModeDefaults.reg','Restore-EnergyModeDefaults.reg'],
    ['files/experimental/power/README.md','README.md']
  ]},
  {name:'Legacy-NvApi64-Workaround.zip',members:[
    ['files/archive/legacy-workarounds/nvidia/Move-NvApi64.ps1','Move-NvApi64.ps1'],
    ['files/archive/legacy-workarounds/nvidia/Restore-NvApi64.ps1','Restore-NvApi64.ps1']
  ]},
  {name:'Legacy-Services-Disable-Restore.zip',members:[
    ['files/archive/wfiles-original/Files [OLD]/Services Disable.reg','Services Disable.reg'],
    ['files/archive/wfiles-original/Files [OLD]/Services Restore.reg','Services Restore.reg']
  ]}
];

let crcTable;
function getCrcTable(){
 if(crcTable) return crcTable;
 crcTable=new Uint32Array(256);
 for(let n=0;n<256;n++){
   let c=n;
   for(let k=0;k<8;k++) c=(c&1)?(0xedb88320^(c>>>1)):(c>>>1);
   crcTable[n]=c>>>0;
 }
 return crcTable;
}
function crc32(bytes){
 const table=getCrcTable();
 let c=0xffffffff;
 for(const b of bytes) c=table[(c^b)&0xff]^(c>>>8);
 return (c^0xffffffff)>>>0;
}
function u16(v){return new Uint8Array([v&255,(v>>>8)&255]);}
function u32(v){return new Uint8Array([v&255,(v>>>8)&255,(v>>>16)&255,(v>>>24)&255]);}
function concatBytes(parts){
 const total=parts.reduce((n,p)=>n+p.length,0), out=new Uint8Array(total);
 let offset=0;
 for(const part of parts){out.set(part,offset);offset+=part.length;}
 return out;
}
async function buildZip(bundle){
 const encoder=new TextEncoder(), locals=[], central=[];
 let offset=0;
 for(const [url,entryName] of bundle.members){
   const response=await fetch(encodeURI(url));
   if(!response.ok) throw new Error(`Failed to fetch ${url}: HTTP ${response.status}`);
   const data=new Uint8Array(await response.arrayBuffer()), name=encoder.encode(entryName), crc=crc32(data);
   const local=concatBytes([u32(0x04034b50),u16(20),u16(0x0800),u16(0),u16(0),u16(0),u32(crc),u32(data.length),u32(data.length),u16(name.length),u16(0),name,data]);
   locals.push(local);
   central.push(concatBytes([u32(0x02014b50),u16(20),u16(20),u16(0x0800),u16(0),u16(0),u16(0),u32(crc),u32(data.length),u32(data.length),u16(name.length),u16(0),u16(0),u16(0),u16(0),u32(0),u32(offset),name]));
   offset+=local.length;
 }
 const centralBytes=concatBytes(central);
 const end=concatBytes([u32(0x06054b50),u16(0),u16(0),u16(bundle.members.length),u16(bundle.members.length),u32(centralBytes.length),u32(offset),u16(0)]);
 return new Blob([...locals,centralBytes,end],{type:'application/zip'});
}
async function downloadBundle(bundle,button){
 const oldText=button.textContent;
 button.textContent='Preparing bundle…';
 button.setAttribute('aria-busy','true');
 try{
   const blob=await buildZip(bundle), href=URL.createObjectURL(blob), a=document.createElement('a');
   a.href=href;a.download=bundle.name;document.body.appendChild(a);a.click();a.remove();
   setTimeout(()=>URL.revokeObjectURL(href),1000);
 }catch(error){
   console.error(error);
   alert(`Could not prepare ${bundle.name}. ${error.message}`);
 }finally{
   button.textContent=oldText;button.removeAttribute('aria-busy');
 }
}
function bundleForHref(href){
 return relatedBundles.find(bundle=>href.endsWith(`files/bundles/${bundle.name}`)||bundle.members.some(([url])=>href.endsWith(url)));
}
function bindDeclaredBundleDownloads(){
 document.querySelectorAll('[data-bundle-name]').forEach(button=>{
   const bundle=relatedBundles.find(item=>item.name===button.dataset.bundleName);
   if(!bundle||button.dataset.bundleBound) return;
   button.dataset.bundleBound='1';
   button.addEventListener('click',event=>{event.preventDefault();downloadBundle(bundle,button);});
 });
}
function addRelatedBundleDownloads(){
 bindDeclaredBundleDownloads();
 document.querySelectorAll('a[href][download]').forEach(link=>{
   const href=decodeURIComponent(link.getAttribute('href')||''), bundle=bundleForHref(href);
   if(!bundle) return;
   if(href.endsWith(`files/bundles/${bundle.name}`)){
     if(link.dataset.bundleBound) return;
     link.dataset.bundleBound='1';
     link.addEventListener('click',event=>{event.preventDefault();downloadBundle(bundle,link);});
     return;
   }
   const actions=link.closest('.actions'), holder=actions||link.parentElement;
   if(!holder||holder.querySelector(`[data-bundle-name="${bundle.name}"]`)) return;
   const button=document.createElement('button');
   button.type='button';button.className='button';button.dataset.bundleName=bundle.name;
   button.textContent='Download complete bundle (.zip)';
   button.addEventListener('click',()=>downloadBundle(bundle,button));
   if(actions) actions.appendChild(button);
   else{
     const row=document.createElement('div');row.className='path';row.dataset.bundleName=bundle.name;row.appendChild(button);holder.appendChild(row);
   }
 });
}

function directFileHref(path){return 'files/'+path.split('/').map(encodeURIComponent).join('/');}
function humanSize(bytes){
 if(bytes<1024) return `${bytes} B`;
 if(bytes<1024*1024) return `${(bytes/1024).toFixed(bytes<10240?1:0)} KB`;
 return `${(bytes/(1024*1024)).toFixed(1)} MB`;
}
function basename(path){return path.split('/').pop();}
function stripMarkdown(text){return text.replace(/\*\*/g,'').replace(/`/g,'').replace(/[“”]/g,'"').trim();}

async function hydrateToolbox(){
 const host=document.getElementById('toolbox-list');
 if(!host) return;
 try{
   const response=await fetch('TOOLBOX_REFERENCE.md');
   if(!response.ok) throw new Error(`HTTP ${response.status}`);
   const lines=(await response.text()).split(/\r?\n/), items=[];
   let category='', item=null;
   const finish=()=>{if(item){items.push(item);item=null;}};
   for(const raw of lines){
     const line=raw.trim();
     const cat=line.match(/^## (.+)$/);
     if(cat){finish();category=cat[1];continue;}
     const head=line.match(/^### `(.+)`$/);
     if(head){finish();item={path:head[1],category,risk:'',purpose:'',usage:'',notes:[]};continue;}
     if(!item) continue;
     if(line.startsWith('**Risk:**')) item.risk=stripMarkdown(line.slice(9));
     else if(line.startsWith('**Purpose:**')) item.purpose=stripMarkdown(line.slice(12));
     else if(line.startsWith('**Usage:**')) item.usage=stripMarkdown(line.slice(10));
     else if(line&&!line.startsWith('|')&&!line.startsWith('---')) item.notes.push(stripMarkdown(line));
   }
   finish();host.replaceChildren();
   for(const x of items){
     const article=document.createElement('article');article.className='tool';article.dataset.tool='';article.dataset.category=x.category;article.dataset.risk=x.risk;
     article.dataset.search=[x.path,x.category,x.risk,x.purpose,x.usage,...x.notes].join(' ');
     const top=document.createElement('div');top.className='tool-top';
     const left=document.createElement('div'), title=document.createElement('h3'), path=document.createElement('div');
     title.textContent=basename(x.path);path.className='path';path.textContent=x.path;left.append(title,path);
     const badge=document.createElement('span');badge.className=`badge ${x.risk}`;badge.textContent=x.risk;top.append(left,badge);article.appendChild(top);
     const purpose=document.createElement('p');purpose.textContent=x.purpose;article.appendChild(purpose);
     const actions=document.createElement('div');actions.className='actions';const link=document.createElement('a');link.className='button';link.href=directFileHref('toolbox/'+x.path);link.setAttribute('download','');link.textContent='Download file';actions.appendChild(link);article.appendChild(actions);
     const details=document.createElement('details'), summary=document.createElement('summary');summary.textContent='Behavior, limitations and usage';details.appendChild(summary);
     if(x.notes.length){const p=document.createElement('p');p.textContent=x.notes.join(' ');details.appendChild(p);}
     if(x.usage){const p=document.createElement('p'), strong=document.createElement('strong');strong.textContent='Usage: ';p.append(strong,document.createTextNode(x.usage));details.appendChild(p);}
     article.appendChild(details);host.appendChild(article);
   }
   addRelatedBundleDownloads();filterTools();
 }catch(error){host.textContent=`Could not load Toolbox reference: ${error.message}`;}
}

async function hydrateFiles(){
 const host=document.getElementById('file-list');
 if(!host) return;
 try{
   const catalogParts=['catalog-01.json','catalog-02.json','catalog-03.json','catalog-04.json','catalog-05.json','catalog-06.json','catalog-07.json','catalog-08.json'];
   const chunks=await Promise.all(catalogParts.map(async name=>{
     const response=await fetch(`files/${name}`);
     if(!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
     return response.json();
   }));
   const rows=chunks.flat();
   const count=document.getElementById('file-count'), bytes=document.getElementById('file-bytes');
   if(count) count.textContent=rows.length.toLocaleString('en-US');
   if(bytes) bytes.textContent=rows.reduce((n,x)=>n+x.s,0).toLocaleString('en-US');
   host.replaceChildren();
   for(const x of rows){
     const row=document.createElement('div');row.className='file-row';row.dataset.tool='';row.dataset.search=`${x.p} ${x.d} ${x.t}`;
     const first=document.createElement('div'), link=document.createElement('a'), strong=document.createElement('strong'), hash=document.createElement('div');
     link.href=directFileHref(x.p);link.setAttribute('download','');strong.textContent=x.p;link.appendChild(strong);hash.className='path';hash.textContent=x.h;first.append(link,hash);
     const size=document.createElement('div');size.textContent=humanSize(x.s);const type=document.createElement('div');type.textContent=x.t;const desc=document.createElement('div');desc.textContent=x.d;
     row.append(first,size,type,desc);host.appendChild(row);
   }
   addRelatedBundleDownloads();filterTools();
 }catch(error){host.textContent=`Could not load file catalog: ${error.message}`;}
}

document.addEventListener('DOMContentLoaded',()=>{
 ['search','category','risk'].forEach(id=>document.getElementById(id)?.addEventListener('input',filterTools));
 addRelatedBundleDownloads();hydrateToolbox();hydrateFiles();
});
