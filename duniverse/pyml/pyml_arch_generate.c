#include <stdio.h>

#if __APPLE__
  #define PLATFORM_NAME "Mac"
#elif __linux__
  #define PLATFORM_NAME "Linux"
#elif defined(WIN32) || defined(_WIN32)
  #define PLATFORM_NAME "Windows"
#else
  #error "Unknown platform"
#endif

int
main(int argc, char* argv[])
{
  FILE *f = fopen("pyml_arch.ml", "w");
  fprintf(f, "\
type t = Linux | Windows | Mac\n\n\
let os = %s\n\n\
", PLATFORM_NAME);
  #if WIN32
    fprintf(f, "%s", "external fd_of_int : int -> Unix.file_descr = \"win_handle_fd\"");
  #else
    fprintf(f, "%s", "external fd_of_int : int -> Unix.file_descr = \"%identity\"");
  #endif
  fclose(f);
} 
