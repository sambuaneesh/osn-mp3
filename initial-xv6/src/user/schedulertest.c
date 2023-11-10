#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main()
{
  int n, pid;
  int wtime, RTime;
  int twtime = 0, trtime = 0;
  for(n = 0; n < NFORK; n++)
    {
      pid = fork();
      if(pid < 0)
        break;
      if(pid == 0)
        {
          int processID = getpid();
          int subtractedValue = processID - 4;
          int j = subtractedValue % 4;
          if(j == 0)
            set_priority(1, getpid());
          else if(j == 1)
            set_priority(69, getpid());
          else if(j == 2)
            set_priority(78, getpid());
          else if(j == 3)
            set_priority(99, getpid());

          if(n < IO)
            {
              sleep(200); // IO bound processes
            }
          else
            {
              for(volatile int i = 0; i < 1000000000; i++) {
              } // CPU bound process
            }
          // printf("Process %d finished\n", n);
          exit(0);
        }
    }
  for(; n > 0; n--)
    {
      if(waitx(0, &wtime, &RTime) >= 0)
        {
          trtime += RTime;
          twtime += wtime;
        }
    }
  printf("Average RTime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  exit(0);
}