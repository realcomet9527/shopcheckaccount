var{Bun:o}=globalThis[Symbol.for("Bun.lazy")]("primordials"),p=o.readableStreamToArrayBuffer,c=o.readableStreamToText,g=(h)=>o.readableStreamToText(h).then(JSON.parse),i=async(h)=>{return new Buffer(await p(h))},k=o.readableStreamToBlob,q={[Symbol.for("CommonJS")]:0,arrayBuffer:p,text:c,json:g,buffer:i,blob:k};export{c as text,g as json,q as default,i as buffer,k as blob,p as arrayBuffer};
