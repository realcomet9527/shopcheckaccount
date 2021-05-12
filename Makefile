
speedy: speedy-prod-native speedy-prod-wasi speedy-prod-wasm

api: 
	peechy --schema src/api/schema.peechy --esm src/api/schema.js --ts src/api/schema.d.ts --zig src/api/schema.zig

speedy-prod-native: 
	zig build -Drelease-fast

speedy-prod-wasm: 
	zig build -Drelease-fast -Dtarget=wasm32-freestanding

speedy-prod-wasi: 
	zig build -Drelease-fast -Dtarget=wasm32-wasi

speedy-dev: speedy-dev-native speedy-dev-wasi speedy-dev-wasm

speedy-dev-native: 
	zig build

speedy-dev-wasm: 
	zig build -Dtarget=wasm32-freestanding

speedy-dev-wasi: 
	zig build -Dtarget=wasm32-wasi

