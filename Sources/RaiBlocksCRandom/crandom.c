#include "crandom.h"

#ifdef __APPLE__

void crandom_buf(void * buf, size_t size) {
	arc4random_buf(buf, size);
}

#endif