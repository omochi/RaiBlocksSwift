#include "blake2.h"

typedef struct ed25519_hash_context {
	blake2b_state blake2b;
} ed25519_hash_context;

void ed25519_hash_init(ed25519_hash_context *ctx);
void ed25519_hash_update(ed25519_hash_context *ctx, const uint8_t *in, size_t inlen);
void ed25519_hash_final(ed25519_hash_context *ctx, uint8_t *hash);
void ed25519_hash(uint8_t *hash, const uint8_t *in, size_t inlen);


