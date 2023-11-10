#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define MIN_PRIO 0
#define MAX_PRIO 100

int main(int argc, char* args[]) {
    if (argc < 3) {
        printf("Usage: set_priority pid priority\n");
        exit(1);
    }
    int priority = atoi(args[1]);
    int pid = atoi(args[2]);
    if (priority < MIN_PRIO || priority > MAX_PRIO) {
        printf("Invalid priority\n");
        exit(1);
    }
    else {
        // set priority returns the old priority
        int old_priority = set_priority(priority, pid);
        if(old_priority == -1) {
            printf("Invalid pid\n");
            exit(1);
        }
    }
    exit(0);
}