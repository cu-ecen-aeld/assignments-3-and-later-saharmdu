#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <string.h>

int main(int argc, char *argv[]) {
    // Check if the correct number of arguments is provided
    if (argc != 3) {
        printf("Invalid Number of Arguments.\nUsage: %s <file> <string>\n", argv[0]);
        exit(1); // Return with error code
    }

    // Extract the arguments
    char *writefile = argv[1];
    char *writestr = argv[2];

    // Open syslog connection with LOG_USER facility
    openlog("writer", LOG_PID, LOG_USER);

    // Attempt to open the file for writing
    FILE *file = fopen(writefile, "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Failed to open file %s", writefile);
        printf("Failed to open file %s\n", writefile);
        closelog();
        exit(1); 
    }

    // Write the string to the file
    if (fputs(writestr, file) == EOF) {
        syslog(LOG_ERR, "Failed to write to file %s", writefile);
        printf("Failed to write to file %s\n", writefile);
        fclose(file);
        closelog();
        exit(1); 
    }

    // Log the writing operation
    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);

    // Clean up
    fclose(file);
    closelog();

    return 0; // Success
}

