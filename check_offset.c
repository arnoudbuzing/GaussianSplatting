#include <stdio.h>
#include <stddef.h>
#include "WolframLibrary.h"

int main() {
    printf("Offset of numericarrayLibraryFunctions: %zu\n", offsetof(struct st_WolframLibraryData, numericarrayLibraryFunctions));
    printf("Offset of MTensor_new: %zu\n", offsetof(struct st_WolframLibraryData, MTensor_new));
    printf("Offset of VersionNumber: %zu\n", offsetof(struct st_WolframLibraryData, VersionNumber));
    printf("Size of WolframLibraryDataStruct: %zu\n", sizeof(struct st_WolframLibraryData));
    return 0;
}
