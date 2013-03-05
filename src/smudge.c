#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

// only supports
int main(int argc, char* argv[])
{
	FILE *asset;
	char *path;
    // todo: use libgit2 to parse git config.
	char *asset_path = "/Users/chobie/src/assset-san/assets";
	char *asset_file;
	unsigned char buffer[BUFSIZ] = {0};
	size_t read, length;
	long total, written = 0;

	if (argc != 2) {
		fprintf(stderr, "git-smudge <file-path>");
		exit(-1);
	}

	path = argv[1];
	//fprintf(stderr, "path: %s", path);

	asset_file = malloc(strlen(asset_path) + 1 + strlen(path) + 1);
	sprintf(asset_file, "%s/%s", asset_path, path);
	asset = fopen(asset_file, "rb");

	if (asset) {
		fprintf(stderr, "copying %s...\n", path);
		fseek(asset, 0, SEEK_END);
		total = ftell(asset);
		fseek(asset, 0, SEEK_SET);

		//fprintf(stderr, "# found %s\n", asset_file);
		//fprintf(stderr, "  total: %d\n", total);
		while (total >= written) {
			read = fread(buffer, 1, sizeof(buffer), asset);
			//fprintf(stderr, "bytes: %d\n", read);
			if (read == 0) {
				break;
			}
			length = fwrite(buffer, sizeof(unsigned char), read, stdout);
			//fprintf(stderr, "length: %d", read);

			written += length * sizeof(unsigned char);
		}
		fclose(stdout);
		fclose(asset);
	} else {
		fprintf(stderr, "# Assets file Not found. use original file.");
		while (!feof(stdin)) {
			read = fread(buffer, 1, sizeof(buffer), stdin);
			//fprintf(stderr, "bytes: %d\n", read);
			if (read == 0) {
				break;
			}
			fwrite(buffer, sizeof(unsigned char), read, stdout);
		}
	}

	//fprintf(stderr, "  written: %d\n", written);
	free(asset_file);
	return 0;
}
