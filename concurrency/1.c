#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <string.h>
#include <sys/time.h>

#define MAX_COFFEE_TYPES 10
#define MAX_CUSTOMERS 100

typedef struct {
    char name[20];
    int preparation_time;
} CoffeeType;

typedef struct {
    int id;
    int coffee_type_index;
    int arrival_time;
    int tolerance;
} Customer;

int coffee_waste = 0;
int waiting_time = 0;

CoffeeType coffee_types[MAX_COFFEE_TYPES];
Customer customers[MAX_CUSTOMERS];
sem_t baristaSemaphores[MAX_CUSTOMERS];
sem_t coffeeWasteMutex;
pthread_mutex_t print_mutex = PTHREAD_MUTEX_INITIALIZER;
int num_baristas;

// Define color codes
#define ANSI_COLOR_WHITE "\033[0m"
#define ANSI_COLOR_YELLOW "\033[0;33m"
#define ANSI_COLOR_CYAN "\033[0;36m"
#define ANSI_COLOR_BLUE "\033[0;34m"
#define ANSI_COLOR_GREEN "\033[0;32m"
#define ANSI_COLOR_RED "\033[0;31m"

void *customerThread(void *arg) {
    struct timeval start;
    gettimeofday(&start, NULL);

    Customer *customer = (Customer *)arg;

    usleep(customer->arrival_time * 1000000);
    pthread_mutex_lock(&print_mutex);
    printf(ANSI_COLOR_WHITE "Customer %d arrives at %d second(s)\n", customer->id, customer->arrival_time);
    printf(ANSI_COLOR_YELLOW "Customer %d orders a %s\n", customer->id, coffee_types[customer->coffee_type_index].name);
    pthread_mutex_unlock(&print_mutex);

    int selected_barista = -1;
    while (selected_barista == -1) {
        for (int i = 0; i < num_baristas; i++) {
            if (sem_trywait(&baristaSemaphores[i]) == 0) {
                selected_barista = i;
                break;
            }
        }
        usleep(1000); // Sleep for a short time before re-attempt
    }

    struct timeval end;
    gettimeofday(&end, NULL);
    int current_time = (int)(end.tv_sec - start.tv_sec);

    pthread_mutex_lock(&print_mutex);
    printf(ANSI_COLOR_CYAN "Barista %d begins preparing the order of customer %d at %d second(s)\n", selected_barista + 1, customer->id, current_time + 1);
    pthread_mutex_unlock(&print_mutex);

    usleep(coffee_types[customer->coffee_type_index].preparation_time * 1000000);

    gettimeofday(&end, NULL);
    current_time = (int)(end.tv_sec - start.tv_sec);

    // if tolerance is exceeded, customer leaves
    if (current_time - customer->arrival_time > customer->tolerance) {
        pthread_mutex_lock(&print_mutex);
        printf(ANSI_COLOR_RED "Customer %d leaves without their order at %d second(s)\n", customer->id, customer->tolerance + customer->arrival_time);
        waiting_time += customer->tolerance;
        sem_wait(&coffeeWasteMutex);
        coffee_waste++;
        sem_post(&coffeeWasteMutex);
        pthread_mutex_unlock(&print_mutex);
    }

    pthread_mutex_lock(&print_mutex);
    printf(ANSI_COLOR_BLUE "Barista %d completes the order of customer %d at %d second(s)\n", selected_barista + 1, customer->id, current_time + 1);
    if(current_time - customer->arrival_time <= customer->tolerance)
        printf(ANSI_COLOR_GREEN "Customer %d leaves with their order at %d second(s)\n", customer->id, current_time + 1);
        waiting_time += current_time - customer->arrival_time;
    pthread_mutex_unlock(&print_mutex);

    sem_post(&baristaSemaphores[selected_barista]);
    pthread_exit(NULL);
}

int main() {
    int num_coffee_types, num_customers;
    int i;
    pthread_t threads[MAX_CUSTOMERS];

    scanf("%d %d %d", &num_baristas, &num_coffee_types, &num_customers);

    if (num_baristas <= 0 || num_coffee_types <= 0 || num_customers <= 0) {
        printf("Invalid input for baristas, coffee types, or customers. Please enter valid values.\n");
        return 1;
    }

    if (num_baristas > MAX_CUSTOMERS || num_coffee_types > MAX_COFFEE_TYPES || num_customers > MAX_CUSTOMERS) {
        printf("Exceeded maximum limits for baristas, coffee types, or customers. Please enter valid values.\n");
        return 1;
    }

    for (i = 0; i < num_baristas; i++) {
        sem_init(&baristaSemaphores[i], 0, 1); // Initialize each barista semaphore
    }

    sem_init(&coffeeWasteMutex, 0, 1);

    for (i = 0; i < num_coffee_types; i++) {
        scanf("%s %d", coffee_types[i].name, &coffee_types[i].preparation_time);
    }

    for (i = 0; i < num_customers; i++) {
        customers[i].id = i + 1;
        char coffee_type[20];
        scanf("%d %s %d %d", &customers[i].id, coffee_type, &customers[i].arrival_time, &customers[i].tolerance);

        int found = 0;
        for (int j = 0; j < num_coffee_types; j++) {
            if (strcmp(coffee_type, coffee_types[j].name) == 0) {
                customers[i].coffee_type_index = j;
                found = 1;
                break;
            }
        }

        if (!found) {
            printf("Coffee type '%s' not found for customer %d. Please check the input.\n", coffee_type, customers[i].id);
            return 1;
        }
    }

    printf("\n-------------------------\n");
    printf("Simulation starting!!!\n");
    printf("-------------------------\n\n");

    for (i = 0; i < num_customers; i++) {
        pthread_create(&threads[i], NULL, customerThread, &customers[i]);
    }

    for (i = 0; i < num_customers; i++) {
        pthread_join(threads[i], NULL);
    }

    printf(ANSI_COLOR_WHITE"\n%d coffee wasted", coffee_waste);
    printf("\nAverage waiting time: %d\n", waiting_time / num_customers);

    return 0;
}
