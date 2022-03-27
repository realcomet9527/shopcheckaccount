const map = Bun.mmap("./mmap.txt", { shared: true });
const utf8deocder = new TextDecoder("utf-8");

let old = new TextEncoder().encode("12345");

setInterval(() => {
  old = old.sort((a, b) => (Math.random() > 0.5 ? -1 : 1));
  console.log(`changing mmap to ~> ${utf8deocder.decode(old)}`);

  map.set(old);
}, 4);
