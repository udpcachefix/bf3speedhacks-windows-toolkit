const LANGUAGE_KEY='bf3toolkit-language';
const THEME_KEY='bf3toolkit-theme';
const originalText=new WeakMap();
const originalAttrs=new WeakMap();
const originalTitle=document.title;
const metaDescription=document.querySelector('meta[name="description"]');
const originalMetaDescription=metaDescription?.getAttribute('content')||'';
let languageButton=null, themeButton=null, translationMap={}, loadedGermanMap=null, siteChangelogData=null;

function readPreference(key){
 try{return localStorage.getItem(key);}catch{return null;}
}
function writePreference(key,value){
 try{localStorage.setItem(key,value);}catch{}
}
const savedLanguage=readPreference(LANGUAGE_KEY);
let currentLanguage=savedLanguage==='de'||savedLanguage==='en'
 ? savedLanguage
 : ((navigator.language||'').toLowerCase().startsWith('de')?'de':'en');
const savedTheme=readPreference(THEME_KEY);
let currentTheme=savedTheme==='light'||savedTheme==='dark'
 ? savedTheme
 : (window.matchMedia?.('(prefers-color-scheme: light)').matches?'light':'dark');

function pageKey(){
 if(originalTitle==='Not found · udp legacy') return '404';
 const file=(location.pathname.split('/').pop()||'index.html').split('?')[0].split('#')[0];
 return (file.replace(/\.html$/i,'')||'index');
}
async function loadGermanMap(){
 if(loadedGermanMap) return loadedGermanMap;
 const key=pageKey(), names=['common',key];
 if(key==='toolbox') names.push('windows','network','cleanup','nvidia');
 const maps=await Promise.all(names.map(async name=>{
   const response=await fetch(`assets/i18n/de/${name}.json`);
   if(!response.ok) throw new Error(`${name}.json: HTTP ${response.status}`);
   return response.json();
 }));
 loadedGermanMap=Object.assign({},...maps);
 return loadedGermanMap;
}
function t(source){
 return currentLanguage==='de'?(translationMap[source]||source):source;
}
function preserveWhitespace(source,replacement){
 const leading=source.match(/^\s*/)?.[0]||'', trailing=source.match(/\s*$/)?.[0]||'';
 return leading+replacement+trailing;
}
function skipTextNode(node){
 const parent=node.parentElement;
 return !parent||Boolean(parent.closest('script,style,code,pre,kbd,samp,[data-i18n-ignore]'));
}
function applyTextNode(node){
 if(skipTextNode(node)) return;
 if(!originalText.has(node)) originalText.set(node,node.nodeValue);
 const source=originalText.get(node), trimmed=source.trim();
 if(!trimmed) return;
 node.nodeValue=currentLanguage==='de'&&translationMap[trimmed]
   ? preserveWhitespace(source,translationMap[trimmed])
   : source;
}
function applyAttributes(root){
 const elements=[];
 if(root?.nodeType===Node.ELEMENT_NODE) elements.push(root);
 if(root?.querySelectorAll) elements.push(...root.querySelectorAll('*'));
 for(const el of elements){
   if(el.closest?.('[data-i18n-ignore]')) continue;
   for(const attr of ['placeholder','title','aria-label','alt']){
     if(!el.hasAttribute(attr)) continue;
     let stored=originalAttrs.get(el);
     if(!stored){stored={};originalAttrs.set(el,stored);}
     if(!(attr in stored)) stored[attr]=el.getAttribute(attr);
     const source=stored[attr];
     el.setAttribute(attr,currentLanguage==='de'?(translationMap[source]||source):source);
   }
 }
}
function applyTranslations(root=document.body){
 if(!root) return;
 const walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT), nodes=[];
 while(walker.nextNode()) nodes.push(walker.currentNode);
 nodes.forEach(applyTextNode);
 applyAttributes(root);
 if(root===document.body){
   document.documentElement.lang=currentLanguage;
   document.title=currentLanguage==='de'?(translationMap[originalTitle]||originalTitle):originalTitle;
   if(metaDescription){
     metaDescription.setAttribute('content',currentLanguage==='de'
       ? (translationMap[originalMetaDescription]||originalMetaDescription)
       : originalMetaDescription);
   }
 }
 updateControls();
}
function updateControls(){
 if(languageButton){
   languageButton.textContent=currentLanguage==='de'?'EN':'DE';
   const label=currentLanguage==='de'?'Switch to English':'Switch to German';
   languageButton.title=t(label);
   languageButton.setAttribute('aria-label',t(label));
 }
 if(themeButton){
   const target=currentTheme==='dark'?'light':'dark';
   const label=target==='light'?'Light':'Dark';
   const action=target==='light'?'Switch to light theme':'Switch to dark theme';
   themeButton.textContent=(target==='light'?'☀ ':'☾ ')+t(label);
   themeButton.title=t(action);
   themeButton.setAttribute('aria-label',t(action));
 }
}
function applyTheme(theme,persist=true){
 currentTheme=theme==='light'?'light':'dark';
 document.documentElement.dataset.theme=currentTheme;
 if(persist) writePreference(THEME_KEY,currentTheme);
 updateControls();
}
async function setLanguage(language,persist=true){
 currentLanguage=language==='de'?'de':'en';
 if(persist) writePreference(LANGUAGE_KEY,currentLanguage);
 if(currentLanguage==='de'){
   try{translationMap=await loadGermanMap();}
   catch(error){
     console.error('Could not load German translations:',error);
     currentLanguage='en';
     translationMap={};
     if(persist) writePreference(LANGUAGE_KEY,currentLanguage);
   }
 }else translationMap={};
 applyTranslations(document.body);
 refreshLocalizedNumbers();
 renderChangelog();
 filterTools();
}
function ensureChangelogNavLink(){
 const nav=document.querySelector('.nav');
 if(!nav) return;
 let link=nav.querySelector('a[href="changelog.html"]');
 if(!link){
   link=document.createElement('a');
   link.href='changelog.html';
   link.textContent='Changelog';
   const controls=nav.querySelector('.site-controls');
   nav.insertBefore(link,controls||null);
 }
 link.classList.toggle('active',pageKey()==='changelog');
}
function initSiteControls(){
 const nav=document.querySelector('.nav');
 if(!nav||nav.querySelector('.site-controls')) return;
 const controls=document.createElement('div');
 controls.className='site-controls';
 controls.dataset.i18nIgnore='';

 languageButton=document.createElement('button');
 languageButton.type='button';
 languageButton.className='site-toggle language-toggle';
 languageButton.addEventListener('click',()=>setLanguage(currentLanguage==='de'?'en':'de'));

 themeButton=document.createElement('button');
 themeButton.type='button';
 themeButton.className='site-toggle theme-toggle';
 themeButton.addEventListener('click',()=>applyTheme(currentTheme==='dark'?'light':'dark'));

 controls.append(languageButton,themeButton);
 nav.appendChild(controls);
 updateControls();
}
function localeName(){return currentLanguage==='de'?'de-DE':'en-US';}
function formatNumber(value,options={}){return new Intl.NumberFormat(localeName(),options).format(value);}
function refreshLocalizedNumbers(){
 document.querySelectorAll('.file-size[data-bytes]').forEach(el=>{el.textContent=humanSize(Number(el.dataset.bytes));});
 const count=document.getElementById('file-count'), bytes=document.getElementById('file-bytes');
 if(count?.dataset.value) count.textContent=formatNumber(Number(count.dataset.value));
 if(bytes?.dataset.value) bytes.textContent=formatNumber(Number(bytes.dataset.value));
}

applyTheme(currentTheme,false);
const systemTheme=window.matchMedia?.('(prefers-color-scheme: light)');
systemTheme?.addEventListener?.('change',event=>{
 if(!readPreference(THEME_KEY)) applyTheme(event.matches?'light':'dark',false);
});

function filterTools(){
 const q=(document.getElementById('search')?.value||'').toLowerCase();
 const c=(document.getElementById('category')?.value||'').toLowerCase();
 const r=(document.getElementById('risk')?.value||'').toLowerCase();
 document.querySelectorAll('[data-tool]').forEach(el=>{
   const hay=((el.dataset.search||'')+' '+(el.textContent||'')).toLowerCase();
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
 button.textContent=t('Preparing bundle…');
 button.setAttribute('aria-busy','true');
 try{
   const blob=await buildZip(bundle), href=URL.createObjectURL(blob), a=document.createElement('a');
   a.href=href;a.download=bundle.name;document.body.appendChild(a);a.click();a.remove();
   setTimeout(()=>URL.revokeObjectURL(href),1000);
 }catch(error){
   console.error(error);
   alert(currentLanguage==='de'?`Paket ${bundle.name} konnte nicht erstellt werden. ${error.message}`:`Could not prepare ${bundle.name}. ${error.message}`);
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
   button.textContent='Download complete bundle (.zip)';applyTranslations(button);
   button.addEventListener('click',()=>downloadBundle(bundle,button));
   if(actions) actions.appendChild(button);
   else{
     const row=document.createElement('div');row.className='path';row.dataset.bundleName=bundle.name;row.appendChild(button);holder.appendChild(row);
   }
 });
}

function directFileHref(path){return 'files/'+path.split('/').map(encodeURIComponent).join('/');}
function humanSize(bytes){
 if(bytes<1024) return `${formatNumber(bytes)} B`;
 if(bytes<1024*1024){
   const value=bytes/1024, digits=bytes<10240?1:0;
   return `${formatNumber(value,{minimumFractionDigits:digits,maximumFractionDigits:digits})} KB`;
 }
 const value=bytes/(1024*1024);
 return `${formatNumber(value,{minimumFractionDigits:1,maximumFractionDigits:1})} MB`;
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
   applyTranslations(host);addRelatedBundleDownloads();filterTools();
 }catch(error){host.textContent=currentLanguage==='de'?`Toolbox Referenz konnte nicht geladen werden: ${error.message}`:`Could not load Toolbox reference: ${error.message}`;}
}

function formatChangelogDate(date){
 const parsed=new Date(`${date}T00:00:00Z`);
 if(Number.isNaN(parsed.getTime())) return date;
 return new Intl.DateTimeFormat(localeName(),{year:'numeric',month:'long',day:'numeric',timeZone:'UTC'}).format(parsed);
}
function renderChangelog(){
 const host=document.getElementById('site-changelog');
 if(!host||!siteChangelogData?.entries) return;
 host.replaceChildren();
 for(const entry of siteChangelogData.entries.slice(0,siteChangelogData.maxEntries||5)){
   const localized=entry[currentLanguage]||entry.en;
   if(!localized) continue;
   const article=document.createElement('article');
   article.className='change-entry';

   const meta=document.createElement('div');
   meta.className='change-meta';
   const time=document.createElement('time');
   time.dateTime=entry.date;
   time.textContent=formatChangelogDate(entry.date);
   meta.appendChild(time);
   if(entry.version){
     const version=document.createElement('span');
     version.className='change-version';
     version.textContent=t(entry.version);
     meta.appendChild(version);
   }

   const title=document.createElement('h2');
   title.textContent=localized.title;
   const list=document.createElement('ul');
   for(const item of localized.items||[]){
     const li=document.createElement('li');
     li.textContent=item;
     list.appendChild(li);
   }

   article.append(meta,title,list);
   host.appendChild(article);
 }
}
async function hydrateChangelog(){
 const host=document.getElementById('site-changelog');
 if(!host) return;
 try{
   const response=await fetch('assets/site-changelog.json',{cache:'no-cache'});
   if(!response.ok) throw new Error(`HTTP ${response.status}`);
   siteChangelogData=await response.json();
   renderChangelog();
 }catch(error){
   console.error(error);
   host.textContent=currentLanguage==='de'
     ? `Änderungsverlauf konnte nicht geladen werden: ${error.message}`
     : `Could not load changelog: ${error.message}`;
 }
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
   const totalBytes=rows.reduce((n,x)=>n+x.s,0);
   if(count){count.dataset.value=String(rows.length);count.textContent=formatNumber(rows.length);}
   if(bytes){bytes.dataset.value=String(totalBytes);bytes.textContent=formatNumber(totalBytes);}
   host.replaceChildren();
   for(const x of rows){
     const row=document.createElement('div');row.className='file-row';row.dataset.tool='';row.dataset.search=`${x.p} ${x.d} ${x.t}`;
     const first=document.createElement('div'), link=document.createElement('a'), strong=document.createElement('strong'), hash=document.createElement('div');
     link.href=directFileHref(x.p);link.setAttribute('download','');strong.textContent=x.p;link.appendChild(strong);hash.className='path';hash.textContent=x.h;first.append(link,hash);
     const size=document.createElement('div');size.className='file-size';size.dataset.bytes=String(x.s);size.textContent=humanSize(x.s);const type=document.createElement('div');type.textContent=x.t;const desc=document.createElement('div');desc.textContent=x.d;
     row.append(first,size,type,desc);host.appendChild(row);
   }
   applyTranslations(host);refreshLocalizedNumbers();addRelatedBundleDownloads();filterTools();
 }catch(error){host.textContent=currentLanguage==='de'?`Dateikatalog konnte nicht geladen werden: ${error.message}`:`Could not load file catalog: ${error.message}`;}
}

document.addEventListener('DOMContentLoaded',async()=>{
 ensureChangelogNavLink();
 initSiteControls();
 await setLanguage(currentLanguage,false);
 ['search','category','risk'].forEach(id=>document.getElementById(id)?.addEventListener('input',filterTools));
 addRelatedBundleDownloads();
 await Promise.all([hydrateToolbox(),hydrateFiles(),hydrateChangelog()]);
 applyTranslations(document.body);
 refreshLocalizedNumbers();
 renderChangelog();
 filterTools();
});
