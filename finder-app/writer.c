#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  openlog("Assignment 2", 0, LOG_USER);

  if (argc < 3) {
    syslog(LOG_ERR,
           "writestr (arg1) or searchstr (arg2) not specified. Please provide "
           "the necessary arguments correctly!");
    return 1;
  }

  int file_handler = creat(argv[1], 0644);

  if (file_handler == -1) {
    syslog(LOG_ERR, "Failed to create file");
    return 1;
  }

  if (write(file_handler, argv[2], strlen(argv[2])) == -1) {
    syslog(LOG_ERR, "Failed to write file");
    return 1;
  }

  syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
  return 0;
}