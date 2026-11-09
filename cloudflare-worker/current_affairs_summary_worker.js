export default {
async fetch(request,env){
 if(request.method==="OPTIONS")return new Response(null,{status:204,headers:C()});
 const u=new URL(request.url); if(u.pathname!=="/api/current-affairs/summary"||request.method!=="GET")return J({error:"not_found"},404);
 const id=ID(u.searchParams.get("id")); if(!id)return J({error:"missing_id"},400);
 let s=await env.KV.get("s:"+id,"json"); if(s)return J(s);
 let a=await env.KV.get("a:"+id,"json"); if(!a){try{a=(await F(env)).find(x=>x.id===id)||null}catch(e){}}
 if(!a)return J({error:"article_not_found"},404);
 try{s=await G(a,env);await env.KV.put("s:"+id,JSON.stringify(s),{expirationTtl:2592000});return J(s)}
 catch(e){return J({error:"summary_unavailable"},503)}
},
async scheduled(c,env,ctx){ctx.waitUntil(P(env))}
};
async function P(env){
 try{const as=await F(env);let d=new Date().toISOString().slice(0,10),k="p:"+d,n=Number(await env.KV.get(k))||0;
  if(n>=20)return;
  as.sort((x,y)=>R(y)-R(x));
  for(const a of as){if(n>=20)break;if(await env.KV.get("s:"+a.id))continue;if(R(a)<=0)continue;if(a.feedType.toLowerCase()==="opinions"&&R(a)<8)continue;
   try{const s=await G(a,env);await env.KV.put("s:"+a.id,JSON.stringify(s),{expirationTtl:2592000});n++;await env.KV.put(k,String(n),{expirationTtl:172800})}catch(e){}
  }
 }catch(e){}
}
async function F(env){
 const r=await fetch(env.FEED_URL);if(!r.ok)throw Error("feed");
 const d=await r.json(),as=[...(Array.isArray(d.national)?d.national:[]),...(Array.isArray(d.international)?d.international:[])].filter(x=>x&&x.title&&x.articleUrl).map(x=>({id:ID(x.id)||I(x.articleUrl,x.title),title:T(x.title),source:T(x.source||"Current Affairs"),category:T(x.category||"International"),feedType:T(x.feedType||"Latest News"),excerpt:T(x.excerpt||"").slice(0,1000),articleUrl:x.articleUrl}));
 for(const a of as)await env.KV.put("a:"+a.id,JSON.stringify(a),{expirationTtl:172800});return as
}
async function G(a,env){
 let t="";try{const c=new AbortController(),z=setTimeout(()=>c.abort(),12000),r=await fetch(a.articleUrl,{headers:{Accept:"text/html", "User-Agent":"DarsNexa-AI-Summary/1.0"},signal:c.signal});if(r.ok)t=X((await r.text()).slice(0,500000)).slice(0,12000);clearTimeout(z)}catch(e){}
 if(!t)t=a.excerpt||a.title;
 const p=["You are DarsNexa's current-affairs exam summarizer.","Use ONLY the supplied article text. Never invent facts.","Return JSON only: {summary, keyPoints, examRelevance}.","summary: 2-4 concise lines; keyPoints: 3-5 factual points; examRelevance: 1-3 exam subjects.","TITLE: "+a.title,"SOURCE: "+a.source,"CATEGORY: "+a.category,"ARTICLE TEXT:",t].join("\n");
 const r=await fetch(env.AI_URL,{method:"POST",headers:{"Content-Type":"application/json",Authorization:"Bearer "+env.AI_KEY,"X-AI-Provider":"auto"},body:JSON.stringify({model:"auto",stream:false,messages:[{role:"system",content:"Return concise factual exam-focused JSON only."},{role:"user",content:p}]})});
 if(!r.ok)throw Error("ai");const d=await r.json(),m=d.choices&&d.choices[0]&&d.choices[0].message,c=m&&m.content;if(typeof c!=="string")throw Error("content");
 const q=JSON.parse(c.replace(/^\s*\`\`\`json\s*/i,"").replace(/\s*\`\`\`$/i,"").trim()),sum=T(q.summary),kp=Array.isArray(q.keyPoints)?q.keyPoints.map(T).filter(Boolean).slice(0,5):[],er=Array.isArray(q.examRelevance)?q.examRelevance.map(T).filter(Boolean).slice(0,3):[];
 if(!sum||kp.length<3||!er.length)throw Error("invalid");return{version:1,generatedAt:new Date().toISOString(),summary:sum,keyPoints:kp,examRelevance:er}
}
function R(a){const t=(a.title+" "+a.excerpt).toLowerCase(),b=[["politic",8],["government",8],["minister",6],["parliament",6],["election",7],["diplom",7],["foreign affair",8],["geopolit",8],["econom",7],["inflation",6],["trade",5],["security",7],["defen",6],["terror",7],["conflict",6],["war",5],["climate",7],["environment",5],["science",6],["research",4],["united nations",7],["nato",6],["g20",6],["summit",5],["sanction",5],["disaster",5],["pandemic",6],["court",4]],p=[["entertainment",10],["celebrity",10],["hollywood",8],["bollywood",8],["film",7],["movie",7],["music",6],["cricket",5],["football",5],["sports",5]];let n=0;for(const x of b)if(t.includes(x[0]))n+=x[1];for(const x of p)if(t.includes(x[0]))n-=x[1];return n}
function X(h){return h.replace(/<script\b[\s\S]*?<\/script>/gi," ").replace(/<style\b[\s\S]*?<\/style>/gi," ").replace(/<[^>]+>/g," ").replace(/\s+/g," ").replace(/&amp;/gi,"&").replace(/&nbsp;/gi," ").replace(/&lt;/gi,"<").replace(/&gt;/gi,">").trim()}
function I(u,t){return(u||t).toLowerCase().replace(/[^a-z0-9]+/g,"-").slice(0,180)}
function ID(v){v=String(v||"").trim();return/^[a-z0-9-]{1,180}$/i.test(v)?v.toLowerCase():""}
function T(v){return String(v||"").replace(/\s+/g," ").trim()}
function C(){return{"Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"GET, OPTIONS","Access-Control-Allow-Headers":"Content-Type"}}
function J(b,s){return new Response(JSON.stringify(b),{status:s||200,headers:Object.assign({},C(),{"Content-Type":"application/json"})})}