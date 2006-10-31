#define GRF_NO_EXPORT
#include <grf.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <sys/time.h>

#ifndef __WIN32
struct timeval tv;

inline void timer_start() {
	gettimeofday((struct timeval *)&tv, NULL);
}

void timer_end(const char *reason) {
	struct timeval tv2;
	float diff;
	gettimeofday((struct timeval *)&tv2, NULL);
	diff = tv2.tv_usec - tv.tv_usec;
	diff = ((tv2.tv_sec - tv.tv_sec) * 1000) + (diff / 1000);
	printf(reason, diff);
}
#else
#define timer_start()
#define timer_end(x)
#endif

void test_grf_version() {
	uint32_t version=grf_version();
	uint8_t major, minor;
	major = version >> 8;
	minor = version & 0xff;
	printf(" - test_version(): %x (%d.%d)\n", version, major, minor);
	if ( (major != VERSION_MAJOR) || (minor != VERSION_MINOR)) {
		puts("Error: This test program was not compiled for this lib!");
		exit(1);
	}
}

void test_new_handler() {
	void *handler;

	if (sizeof(struct grf_header) != GRF_HEADER_SIZE) {
		printf("Your compiler didn't use the right size for the packed structure (%x!=%x) !", (uint32_t) sizeof(struct grf_header), GRF_HEADER_SIZE);
		exit(2);
	}
	grf_set_compression_level(9);

	handler = grf_new("test.grf", true);
	printf(" - test_new_handler(): New handler at %p.\n", handler);
	if (grf_save(handler) == true) {
		puts(" - test_new_handler(): Write file success !");
	} else {
		perror("grf_save");
		grf_free(handler);
		exit(3);
	}
	grf_free(handler);
}

void test_load_file() {
	void *handler, *fhandler;
	void *filec;
	char *fn = "/storage/win_d/Program Files/Gravity/fRO_II/data.grf";
//	char *fn = "test.grf";
	char *fn2 = "DATA/texTURE\\�����������̽�/LOADING45.JPG";

	printf(" - test_load_file(): Opening `%s` in read only mode...\n", fn);
	timer_start();
	handler = grf_load(fn, false);
	printf(" - test_load_file(): Loaded file at %p.\n", handler);
	timer_end(" - test_load_file(): File loading took %fms\n");
	if (handler == NULL) return;
	printf(" - test_load_file(): There are %d files in this GRF.\n", grf_filecount(handler));
	printf(" - test_load_file(): %d byte(s) wasted.\n", grf_wasted_space(handler));
	printf(" - grf_create_tree(): Building global tree...\n");
	timer_start();
	grf_create_tree(handler);
	timer_end(" - grf_create_tree(): Tree created in %fms\n");
	printf(" - test_load_file(): Searching for file %s\n", fn2);
	timer_start();
	fhandler = grf_get_file(handler, fn2);
	timer_end(" - test_load_file(): File search took %fms.\n");
	printf(" - test_load_file(): File is at %p\n", fhandler);
	if (fhandler == NULL) return;
	printf(" - test_load_file(): Real filename is `%s`\n", grf_file_get_filename(fhandler));
	printf(" - test_load_file(): File size is %d bytes.\n", grf_file_get_size(fhandler));
	filec = malloc(grf_file_get_size(fhandler));
	printf(" - test_load_file(): Extracted %d bytes for this file.\n", grf_file_get_contents(fhandler, filec));
	FILE *f=fopen("loading45.jpg", "w");
	if (f == NULL) {
		printf(" - test_writing failed\n");
	} else {
		printf(" - test_writing ok\n");
		fwrite(filec, grf_file_get_size(fhandler), 1, f);
		fclose(f);
	}
	free(filec);
	grf_free(handler);
}

int main() {
	puts(grf_versionstring());
	puts(" * Running library tests...");
	test_grf_version();
	test_new_handler();
	test_load_file();
	return 0;
}
