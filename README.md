<!-- [![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/JH3nieSp)
# OSN Monsoon 2023 mini project 3
## xv6 revisited and concurrency

*when will the pain and suffering end?*

## Some pointers/instructions
- main xv6 source code is present inside `initial_xv6/src` directory.
- Feel free to update this directory and add your code from the previous assignment here.
- By now, I believe you are already well aware on how you can check your xv6 implementations. 
- Just to reiterate, make use of the `procdump` function and the `usertests` and `schedulertest` command.
- work inside the `concurrency/` directory for the Concurrency questions (`Cafe Sim` and `Ice Cream Parlor Sim`).

- Answer all the theoretical/analysis-based questions (for PBS scheduler and the concurrency questions) in a single `md `file.
- You may delete these instructions and add your report before submitting.  -->

# Priority-Based Scheduler Implementation in xv6

## Introduction

This report outlines the implementation of a Priority-Based Scheduler (PBS) in the xv6 operating system. The scheduler selects processes for execution based on both static and dynamic priorities. Additionally, a `set_priority` system call has been introduced to allow users to modify process priorities.

## Changes in `proc.c`

### Scheduler Function

```c
// Introduced a global scheduler lock
struct spinlock sched_lock;

// Scheduler function selects the process with the highest priority for execution
void scheduler(void) {
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  
  for (;;) {
    intr_on(); // Enable interrupts on this processor.
    
    int min_priority = MAX_PRIO + 1;
    struct proc *min_proc = 0;

    acquire(&sched_lock); // Acquire the global scheduler lock.

    // Loop over the process table looking for the process to run.
    for (p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock); // Acquire the lock for the individual process.

      // Check if the process is in a RUNNABLE state
      if (p->state != RUNNABLE) {
        release(&p->lock); // Release the lock for the individual process.
        continue;
      } else if (p->state == RUNNABLE) {
        p->RBI = calculate_RBI(p->RTime, p->STime, p->WTime);
      }

      // Calculate dynamic priority
      p->DYNAMIC_PRIO = minOf(p->STATIC_PRIO + p->RBI, MAX_PRIO);

      // Determine the process with the highest priority
      if (min_proc == 0 || p->DYNAMIC_PRIO < min_priority) {
        min_priority = p->DYNAMIC_PRIO;
        min_proc = p;
      } else if (p->DYNAMIC_PRIO == min_priority && p->N_RUN < min_proc->N_RUN) {
        min_priority = p->DYNAMIC_PRIO;
        min_proc = p;
      } else if (p->DYNAMIC_PRIO == min_priority && p->N_RUN == min_proc->N_RUN && p->ctime < min_proc->ctime) {
        min_priority = p->DYNAMIC_PRIO;
        min_proc = p;
      } else if (p->DYNAMIC_PRIO == min_priority && p->N_RUN == min_proc->N_RUN && p->ctime == min_proc->ctime) {
        min_priority = p->DYNAMIC_PRIO;
        min_proc = p;
      }

      release(&p->lock); // Release the lock for the individual process.
    }

    release(&sched_lock); // Release the global scheduler lock.

    // Execute the selected process
    if (min_proc != 0) {
      if (min_proc->state == RUNNABLE) {
        acquire(&min_proc->lock); // Acquire the lock for the chosen process.

        min_proc->state = RUNNING;
        c->proc = min_proc;
        swtch(&c->context, &min_proc->context);

        c->proc = 0;
        release(&min_proc->lock); // Release the lock for the chosen process.
      }
    }
  }
}
```

### `set_priority` System Call

```c
// System call prototype for modifying process priority
int set_priority(int new_priority, int pid);
```

Explanation:
- The `scheduler` function is responsible for selecting the process with the highest priority for execution.
- A global `sched_lock` is introduced to synchronize access to the scheduler across different processes.
- The dynamic priority (`DYNAMIC_PRIO`) is calculated based on the static priority (`STATIC_PRIO`) and recent behavior index (`RBI`).
- The `set_priority` system call prototype allows users to modify the priority of a process. It takes the new priority and process ID as arguments.

## Testing the Scheduler

### User Program `set_priority`

The user program `set_priority` has been implemented to use the `set_priority` system call. It takes the syscall arguments as command-line arguments.

```c
// Implementation of set_priority user program
int set_priority(int new_priority, int pid);
```

Explanation:
- The `set_priority` user program uses the `set_priority` system call to modify the priority of a process.
- It takes the new priority and process ID as command-line arguments.
- The system call returns the old static priority of the process.

### Scheduler Test

The scheduler is tested for Priority-Based Scheduling (PBS) using the following code snippet in the `schedulertest`:

```c
// Scheduler test to set priorities for PBS
if(j == 0)
  set_priority(1, getpid());
else if(j == 1)
  set_priority(69, getpid());
else if(j == 2)
  set_priority(78, getpid());
else if(j == 3)
  set_priority(99, getpid());
```

Explanation:
- The code snippet sets different priorities for processes in the `schedulertest` to observe the behavior of the PBS scheduler.
- The priorities are set using the `set_priority` system call with different values.
- The resulting priorities are then plotted in a scatterplot for analysis.

## Scatterplot for PBS Priorities

A scatterplot is generated to visualize the priorities set for PBS.

![Scatterplot for PBS Priorities](https://i.imgur.com/uESE3UM.png)

The scatterplot displays the relationship between process PIDs and ticks for different priority levels, providing insights into the scheduling behavior.

## Priority Showdown: SP vs RBI

### Meet the Contenders

**Static Priority (SP):** The diva of priorities. User-defined, it's like your favorite playlist - set it and forget it. Ranges from "I'm chillin'" to "I need this pronto!"

**Recent Behavior Index (RBI):** The silent observer. Calculates your process's coolness based on running, sleeping, and waiting times. The more diverse your behavior, the higher the score.

### The Action Unveiled

**SP:** Think of it like picking your favorite ice cream flavor. Vanilla (high SP) means you're keeping it classic. Pistachio (low SP) says, "I'm daring, come at me, scheduler!"

**RBI:** The CSI detective of priorities. Checks your recent moves - running, sleeping, waiting. Did you nap a lot? RBI noticed. Ran a marathon? RBI's on it. Waiting for a bus? RBI's got your back.

### The Dynamic Duo: SP + RBI = DP

**Dynamic Priority (DP):** The love child of SP and RBI. SP gives the baseline, RBI adds the spice. It's like a pizza - base (SP), toppings (RBI), perfection (DP).

### Effectiveness Meter

- **Fairness:** Like a kindergarten teacher, ensures everyone gets a turn. No process left behind!

- **Prevention of Starvation:** Stops the workaholics from hogging the CPU buffet. Everyone deserves a byte!

- **User Control and Autonomy:** You're the chef, choosing the base (SP). RBI's the sous chef, adding secret spices. Bon appétit, scheduler!

## (Jokes Aside!) Observations:

1. **Initial State (RTime = 0, STime = 0):**
    - When a process starts (both `RTime` and `STime` are zero), the RBI is set to a default value (`DEFAULT_RBI`). (25)
    - This ensures that newly launched processes are assigned a reasonable initial priority.
2. **RBI Dynamics:**
    - The RBI calculation reflects the recent behavior of a process based on its running, sleeping, and waiting times.
    - Processes with longer running times and shorter sleep and wait times receive a higher RBI, indicating potential priority reduction.
    - Conversely, processes with significant sleep or wait times receive a higher RBI, potentially leading to a priority boost.
3. **Weighted Contribution:**
    - The formula considers the weighted sum of running, sleeping, and waiting times, providing a balanced perspective on recent behavior.
    - The weightings ensure that running time has a more pronounced impact on RBI than sleep and wait times.
4. **Normalization Factor:**
    - The denominator in the RBI formula ensures that the RBI is normalized to a reasonable range.
    - The addition of 1 in the denominator prevents division by zero and ensures a smooth transition from the initial state.

___

# Cafe Sim
## Overview
The cafe has multiple baristas, each capable of preparing different types of coffee. Customers arrive at the cafe, place their coffee orders, and wait for the baristas to prepare their drinks. The simulation utilizes semaphores and mutex locks to ensure thread safety, and it addresses potential issues like deadlocks and busy waiting.

## Implementation Logic

### Data Structures

I used the following data structures:

- **CoffeeType**: Represents a type of coffee with attributes such as name and preparation time.

- **Customer**: Represents a customer with attributes like ID, coffee type index, arrival time, and tolerance.

- **Semaphore**: Utilized for synchronization between baristas. Each barista has its semaphore to control access to their service.

### Thread Functionality

- **Customer Thread (`customerThread`)**: This function simulates the behavior of each customer as a separate thread. Customers arrive, place their orders, and wait for a barista to prepare their coffee. The thread uses semaphores to acquire a barista for order preparation.

- **Barista Semaphores**: Each barista is represented by a semaphore, initialized to 1. A semaphore is locked when a barista starts preparing an order and released when the order is complete. This ensures that each barista handles one order at a time.

- **Mutex Lock (`print_mutex`)**: A mutex lock is used to synchronize print statements to prevent interference between different threads when printing to the console.

- **Coffee Wastage Mutex (`coffeeWasteMutex`)**: Ensures mutual exclusion when updating the coffee wastage count.

## Evaluation and Insights

### Waiting Time

To calculate the average waiting time, I recorded the arrival time of each customer and the time when they leave with or without their order. The waiting time is the difference between these two times. I then calculated the average waiting time across all customers.

### Coffee Wastage

I used a shared variable (`coffee_waste`) protected by a mutex to keep track of wasted coffees. A coffee is considered wasted if the customer leaves without receiving their order due to exceeding their tolerance time.

## Results

1. **Average Waiting Time:**
   - I calculated the average waiting time by considering the arrival time and the time a customer leaves (with or without their order).
   - The waiting time provides insights into the efficiency of the cafe in serving customers promptly.

2. **Coffee Wastage:**
   - Coffee wastage is determined by customers who leave without their order due to exceeding tolerance.
   - The count of wasted coffees is displayed at the end of the simulation.

___

