#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <sys/time.h>

#define MAX_CUSTOMERS 100
#define MAX_MACHINES 100
#define MAX_FLAVORS 100
#define MAX_TOPPINGS 100

// Reserved
#define RED "\e[0;31m"
#define GRN "\e[0;32m"
#define BLU "\e[0;34m"
#define CYN "\e[0;36m"

#define R "\e[0m" // Reset

// Free to Use
#define BLK "\e[0;30m"
#define YEL "\e[0;33m"
#define MAG "\e[0;35m"
#define WHT "\e[0;37m"
// Underline
#define UBLK "\e[4;30m"
#define URED "\e[4;31m"
#define UGRN "\e[4;32m"
#define UYEL "\e[4;33m"
#define UBLU "\e[4;34m"
#define UMAG "\e[4;35m"
#define UCYN "\e[4;36m"
#define UWHT "\e[4;37m"

#define DGREY "\x1B[38;5;240m"

typedef struct {
    int id;
    int start_time;
    int end_time;
} Machine;

typedef struct {
    char flavor[100];
    int preparation_time;
} IceCream;

typedef struct {
    int id;
    int arrival_time;
    int num_orders;
    char** flavors;
    char*** toppings;
} CustomerOrder;

typedef struct {
    char topping[100];
    int quantity;
} Topping;

int N, K, F, T;
struct timeval start;
CustomerOrder customerOrders[MAX_CUSTOMERS];
Machine machines[MAX_MACHINES];
IceCream flavors[MAX_FLAVORS];
Topping toppings[MAX_TOPPINGS];

// create array of customer semaphores
sem_t customer_sem[MAX_CUSTOMERS];

// create array of machine semaphores
sem_t machine_sem[MAX_MACHINES];

void splitString(char* input, char* tokens[], const char* delimiter) {
    char* token = strtok(input, delimiter);
    int i = 0;
    while (token != NULL) {
        tokens[i++] = token;
        token = strtok(NULL, delimiter);
    }
    tokens[i] = NULL;
}

void* customer_thread(void* arg) {
    CustomerOrder* order = (CustomerOrder*)arg;
    sleep(order->arrival_time);
    // semwait
    sem_wait(&customer_sem[order->id]);
    struct timeval end;
    gettimeofday(&end, NULL);
    int current_time = (int)(end.tv_sec - start.tv_sec);
    printf("[white colour] Customer %d enters at %d second(s)\n", order->id+1, current_time);
    printf("[yellow colour]:\nCustomer %d orders %d ice cream(s)\n", order->id+1, order->num_orders);

    for (int i = 0; i < order->num_orders; ++i) {
        printf("Ice cream %d: %s", i + 1, order->flavors[i]);
        for (int j = 0; order->toppings[i][j] != NULL; ++j) {
            printf(" %s", order->toppings[i][j]);
        }
        printf("\n");
    }

    sem_post(&customer_sem[order->id]);
    pthread_exit(NULL);
}

void* machine_thread(void* arg) {
    Machine* machine = (Machine*)arg;
    sleep(machines[machine->id].start_time);
    sem_wait(&machine_sem[machine->id]);
    struct timeval end;
    gettimeofday(&end, NULL);
    int current_time = (int)(end.tv_sec - start.tv_sec);
    printf("[orange colour] Machine %d has started working at %d second(s)\n", machine->id+1, current_time);

    // Prepare ice cream using the machine

    sem_post(&machine_sem[machine->id]);
    printf("[orange colour] Machine %d has stopped working at %d second(s)\n", machine->id+1, current_time);

    pthread_exit(NULL);
}

int main() {
    pthread_t customer_thread_ids[MAX_CUSTOMERS];
    pthread_t machine_thread_ids[MAX_MACHINES];
    printf(UWHT"Scanning for N, K, F, T:\n"R);
    scanf("%d %d %d %d", &N, &K, &F, &T);

    printf(UWHT"Scanning for machine start and end times:\n"R);
    for (int i = 0; i < N; ++i) {
        printf(DGREY"Machine %d: "R, i + 1);
        scanf("%d %d", &machines[i].start_time, &machines[i].end_time);
        machines[i].id = i;
    }

    printf(UWHT"Scanning for ice cream flavors and preparation times:\n"R);
    for (int i = 0; i < F; ++i) {
        printf(DGREY"Ice cream %d: "R, i + 1);
        scanf("%s %d", flavors[i].flavor, &flavors[i].preparation_time);
    }

    printf(UWHT"Scanning for topping names and quantities:\n"R);
    for (int i = 0; i < T; ++i) {
        printf(DGREY"Topping %d: "R, i + 1);
        scanf("%s %d", toppings[i].topping, &toppings[i].quantity);
    }

    char buffer[1000];
    int customer_id = 0;
    
    // skip newline character
    getchar();

    printf(UWHT"Scanning for customer orders:\n"R);
    while (1) {
        // reset buffer
        memset(buffer, 0, sizeof(buffer));
        printf(DGREY"Customer %d: "R, customer_id+1);

        // scan input to buffer
        fgets(buffer, sizeof(buffer), stdin);

        // if buffer is \n break
        if (buffer[0] == '\n') {
            break;
        }

        buffer[strlen(buffer) - 1] = '\0'; // Remove newline character
        // printf("Customer %d: %s\n", customer_id, buffer);
        CustomerOrder *order = &customerOrders[customer_id];
        order->id = customer_id++;

        char* tokens[100];
        splitString(buffer, tokens, " ");
        order->arrival_time = atoi(tokens[1]);
        order->num_orders = atoi(tokens[2]);

        order->flavors = (char**)malloc(order->num_orders * sizeof(char*));
        order->toppings = (char***)malloc(order->num_orders * sizeof(char**));

        for (int i = 0; i < order->num_orders; ++i) {
            printf(DGREY"Flavour and Toppings of %d: "R, i + 1);
            fgets(buffer, sizeof(buffer), stdin);
            buffer[strlen(buffer) - 1] = '\0'; // Remove newline character

            char* tokens[100];
            splitString(buffer, tokens, " ");
            order->flavors[i] = strdup(tokens[0]);

            order->toppings[i] = (char**)malloc((strlen(buffer) - strlen(tokens[0]) + 1) * sizeof(char*));

            int topping_count = 0;
            for (int j = 1; tokens[j] != NULL; ++j) {
                order->toppings[i][topping_count] = strdup(tokens[j]);
                topping_count++;
            }
            order->toppings[i][topping_count] = NULL;
        }

        // pthread_t customer_thread_id;
        // pthread_create(&customer_thread_id, NULL, customer_thread, (void*)&order);
    }

    // initialize customer semaphores
    for (int i = 0; i < customer_id; ++i) {
        sem_init(&customer_sem[i], 0, 1);
    }

    // initialize machine semaphores
    for (int i = 0; i < N; ++i) {
        sem_init(&machine_sem[i], 0, 1);
    }

    // create machine threads
    for (int i = 0; i < N; ++i) {
        pthread_create(&machine_thread_ids[i], NULL, machine_thread, (void*)&machines[i].id);
    }

    gettimeofday(&start, NULL);

    // create customer threads
    for (int i = 0; i < customer_id; ++i) {
        pthread_create(&customer_thread_ids[i], NULL, customer_thread, (void*)&customerOrders[i]);
    }
    // usleep(1000);

    // Wait for customer threads to finish
    for (int i = 0; i < customer_id; ++i) {
        pthread_join(customer_thread_ids[i], NULL);
    }
    
    // Wait for machine threads to finish
    for (int i = 0; i < N; ++i) {
        pthread_join(machine_thread_ids[i], NULL);
    }

    return 0;
}
