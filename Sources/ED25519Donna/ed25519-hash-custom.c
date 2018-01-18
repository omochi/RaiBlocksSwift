#include "ed25519-hash-custom.h"

void ed25519_hash_init(ed25519_hash_context *ctx) {
	blake2b_init(&ctx->blake2b, 64);
}

void ed25519_hash_update(ed25519_hash_context *ctx, const uint8_t *in, size_t inlen) {
	blake2b_update(&ctx->blake2b, in, inlen);
}

void ed25519_hash_final(ed25519_hash_context *ctx, uint8_t *hash) {
	blake2b_final(&ctx->blake2b, hash, 64);
}

void ed25519_hash(uint8_t *hash, const uint8_t *in, size_t inlen) {
	ed25519_hash_context ctx;
	ed25519_hash_init (&ctx);
	ed25519_hash_update (&ctx, in, inlen);
	ed25519_hash_final (&ctx, hash);
}
