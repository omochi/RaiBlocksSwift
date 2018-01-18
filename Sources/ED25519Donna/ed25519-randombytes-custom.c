#include "ed25519-randombytes-custom.h"

void ed25519_randombytes_unsafe(void *p, size_t len) {
    crandom_buf(p, len);
}
