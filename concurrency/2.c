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
#define MAX_CUST_TOPPINGS 20

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

typedef struct
{
    int id;
    int start_time;
    int end_time;
    int isAvailable;
} Machine;

typedef struct
{
    int id;
    char flavor[100];
    int preparation_time;
} IceCream;

typedef struct
{
    int id;
    int arrival_time;
    int num_orders;
    char **flavors;
    int **toppings;
    int *num_toppings;
} CustomerOrder;

typedef struct
{
    int customer_id;
    IceCream iceCream;
    int num_toppings;
    int *toppings;
    int isAssigned;
    int issued_time;
} singleOrder;

typedef struct
{
    int id;
    char topping[100];
    int quantity;
    int isAvailable;
} Topping;

int N, K, F, T;
int machineTimeAvailable = 0;
char topping_info[MAX_TOPPINGS][2][100];
CustomerOrder customerOrders[MAX_CUSTOMERS];
Machine machines[MAX_MACHINES];
IceCream flavors[MAX_FLAVORS];
Topping toppings[MAX_TOPPINGS];

sem_t customer_sem;

// binary machine semaphore
sem_t machineLock;

// create array of machine semaphores
sem_t machine_sem[MAX_MACHINES];

// binary semaphore to access toppings
sem_t toppingLock;

// binary semaphore to print statements
sem_t printLock;

// binary semaphore for machineTimeAvailable
sem_t machineTimeAvailableLock;

// function to find topping id from topping name
int findToppingId(char *topping)
{
    for (int i = 0; i < T; ++i)
    {
        if (strcmp(topping, topping_info[i][0]) == 0)
        {
            return i;
        }
    }
    return -1;
}

// function to find flavor id from flavor name
int findFlavorId(char *flavor)
{
    for (int i = 0; i < F; ++i)
    {
        if (strcmp(flavor, flavors[i].flavor) == 0)
        {
            return i;
        }
    }
    return -1;
}

void splitString(char *input, char *tokens[], const char *delimiter)
{
    char *token = strtok(input, delimiter);
    int i = 0;
    while (token != NULL)
    {
        tokens[i++] = token;
        token = strtok(NULL, delimiter);
    }
    tokens[i] = NULL;
}

void parseCustomerOrder(char *input, CustomerOrder *order)
{
    char *tokens[100];
    splitString(input, tokens, " ");

    order->arrival_time = atoi(tokens[1]);
    order->num_orders = atoi(tokens[2]);

    order->flavors = (char **)malloc(order->num_orders * sizeof(char *));
    order->toppings = (int **)malloc(order->num_orders * sizeof(int *));
    order->num_toppings = (int *)malloc(order->num_orders * sizeof(int));

    for (int i = 0; i < order->num_orders; ++i)
    {
        printf(DGREY "Flavour and Toppings of %d: " R, i + 1);
        fgets(input, 1000, stdin);
        input[strlen(input) - 1] = '\0';

        char *tokens[100];
        splitString(input, tokens, " ");

        order->flavors[i] = strdup(tokens[0]);

        int topping_count = 0;
        for (int j = 1; tokens[j] != NULL; ++j)
        {
            int topping_id = findToppingId(tokens[j]);
            if (topping_id != -1)
            {
                order->toppings[i] = (int *)realloc(order->toppings[i], (topping_count + 1) * sizeof(int));
                order->toppings[i][topping_count] = topping_id;
                topping_count++;
            }
        }
        order->num_toppings[i] = topping_count;
    }
}

void *single_order_thread(void *arg)
{
    int selected_machine;
    singleOrder *order = (singleOrder *)arg;

    // printf("Customer %d: %s\n", order->customer_id, order->iceCream.flavor);
    // for (int i = 0; i < order->num_toppings; ++i)
    // {
    //     printf("%s ", topping_info[order->toppings[i]][0]);
    // }
    // printf("\n");

    struct timeval start, end;
    gettimeofday(&start, NULL);

    while (order->isAssigned == 0)
    {
        for (int i = 0; i < N; i++)
        {
            if (machines[i].isAvailable == 0)
            {
                continue;
            }
            if (sem_trywait(&machine_sem[i]) == 0)
            {
                selected_machine = i;
                order->isAssigned = 1;
                break;
            }
        }
        usleep(1000); // Sleep for a short time before re-attempt
    }

    gettimeofday(&end, NULL);
    int elapsed_time = (int)(end.tv_sec - start.tv_sec);

    printf("[blue colour] Machine %d starts preparing ice cream %d of customer %d at %d second(s)\n", selected_machine + 1, order->iceCream.id + 1, order->customer_id + 1, order->issued_time + elapsed_time);

    sleep(order->iceCream.preparation_time);

    printf("[blue colour] Machine %d completes preparing ice cream %d of customer %d at %d second(s)\n", selected_machine + 1, order->iceCream.id + 1, order->customer_id + 1, order->issued_time + elapsed_time + order->iceCream.preparation_time);

    sem_post(&machine_sem[selected_machine]);
}

void *customer_thread(void *arg)
{
    CustomerOrder *order = (CustomerOrder *)arg;
    sleep(order->arrival_time);
    sem_wait(&customer_sem);

    // checking if order is feasible or not
    for(int i=0; i<order->num_orders; ++i){
        int flavor_id = findFlavorId(order->flavors[i]);
        if(flavor_id == -1){
            printf("[red colour] Customer %d unserviced because the flavor %s is not available\n", order->id + 1, order->flavors[i]);
            sem_post(&customer_sem);
            pthread_exit(NULL);
        }
        for(int j=0; j<order->num_toppings[i]; ++j){
            int topping_id = findToppingId(topping_info[order->toppings[i][j]][0]);
            if(topping_id == -1){
                printf("[red colour] Customer %d unserviced because the topping %s is not available\n", order->id + 1, topping_info[order->toppings[i][j]][0]);
                sem_post(&customer_sem);
                pthread_exit(NULL);
            }
        }

        // all the topping quantities are stored in topping_info array, from that check whether the quantity of toppings is sufficient or not
        // for(int j=0; j<order->num_toppings[i]; ++j){
        //     int topping_id = findToppingId(topping_info[order->toppings[i][j]][0]);
        //     if(toppings[topping_id].quantity < order->num_toppings[i]){
        //         printf("[red colour] Customer %d unserviced because the topping %s is not sufficient\n", order->id + 1, topping_info[order->toppings[i][j]][0]);
        //         sem_post(&customer_sem);
        //         pthread_exit(NULL);
        //     }
        // }
    }

    // check if the toppings of the orders are available or not if available then reduce the quantity of toppings
    // for(int i=0; i<order->num_orders; ++i){
    //     for(int j=0; j<order->num_toppings[i]; ++j){
    //         int topping_id = findToppingId(topping_info[order->toppings[i][j]][0]);
    //         // print topping id
    //         // printf("%d\n", topping_id);
    //         if(toppings[topping_id].quantity == 0){
    //             printf("[red colour] Customer %d leaves because the topping %s is not sufficient\n", order->id + 1, topping_info[order->toppings[i][j]][0]);
    //             sem_post(&customer_sem);
    //             pthread_exit(NULL);
    //         }
    //         else{
    //             sem_wait(&toppingLock);
    //             toppings[topping_id].quantity--;
    //             sem_post(&toppingLock);
    //         }
    //     }
    // }

    // sum the total time required for all the orders and compare it with the machine time available
    int total_time_required = 0;
    for(int i=0; i<order->num_orders; ++i){
        total_time_required += flavors[findFlavorId(order->flavors[i])].preparation_time;
    }
    
    if(total_time_required > machineTimeAvailable){
        printf("[red colour] Customer %d is unserviced because the total time required is more than the machine time available\n", order->id + 1);
        sem_post(&customer_sem);
        pthread_exit(NULL);
    } else {
        // check if the machine is available within its running times for the order to complete
        int flag = 0;
        for(int i=0; i<order->num_orders; ++i){
            int flavor_id = findFlavorId(order->flavors[i]);
            for(int j=0; j<N; ++j){
                if(machines[j].isAvailable == 1 && machines[j].start_time <= order->arrival_time && machines[j].end_time >= order->arrival_time + flavors[flavor_id].preparation_time){
                    flag = 1;
                    break;
                }
            }
            if(flag == 0){
                printf("[red colour] Customer %d is unserviced because the machine is not available within its running times\n", order->id + 1);
                sem_post(&customer_sem);
                pthread_exit(NULL);
            }
        }

        sem_wait(&machineTimeAvailableLock);
        machineTimeAvailable -= total_time_required;
        sem_post(&machineTimeAvailableLock);
    }

    // creating single order threads for each order
    for (int i = 0; i < order->num_orders; ++i)
    {
        singleOrder *single_order = (singleOrder *)malloc(sizeof(singleOrder));
        single_order->customer_id = order->id;
        strcpy(single_order->iceCream.flavor, order->flavors[i]);
        single_order->iceCream.preparation_time = flavors[findFlavorId(order->flavors[i])].preparation_time;

        single_order->toppings = (int *)malloc(order->num_toppings[i] * sizeof(int));
        for (int j = 0; j < order->num_toppings[i]; ++j)
        {
            single_order->toppings[j] = order->toppings[i][j];
        }

        single_order->isAssigned = 0;
        single_order->issued_time = order->arrival_time;
        single_order->num_toppings = order->num_toppings[i];

        pthread_t single_order_thread_id;
        pthread_create(&single_order_thread_id, NULL, single_order_thread, (void *)single_order);
    }
}

void *machine_thread(void *arg)
{
    Machine *machine = (Machine *)arg;
    sleep(machines[machine->id].start_time);
    sem_post(&machine_sem[machine->id]);

    int current_time = machine->start_time;
    printf("[orange colour] Machine %d has started working at %d second(s)\n", machine->id + 1, current_time);

    sem_post(&machine_sem[machine->id]);
    sleep(machine->end_time - machine->start_time);
    printf("[orange colour] Machine %d has stopped working at %d second(s)\n", machine->id + 1, current_time + machine->end_time - machine->start_time);
    sem_wait(&machineLock);
    machine->isAvailable = 0;
    sem_post(&machineLock);

    pthread_exit(NULL);
}

int main()
{
    pthread_t customer_thread_ids[MAX_CUSTOMERS];
    pthread_t machine_thread_ids[MAX_MACHINES];

    printf(UWHT "Scanning for N, K, F, T:\n" R);
    scanf("%d %d %d %d", &N, &K, &F, &T);

    printf(UWHT "Scanning for machine start and end times:\n" R);
    for (int i = 0; i < N; ++i)
    {
        printf(DGREY "Machine %d: " R, i + 1);
        scanf("%d %d", &machines[i].start_time, &machines[i].end_time);
        machines[i].id = i;
        machines[i].isAvailable = 1;
        machineTimeAvailable += machines[i].end_time - machines[i].start_time;
    }

    printf(UWHT "Scanning for ice cream flavors and preparation times:\n" R);
    for (int i = 0; i < F; ++i)
    {
        printf(DGREY "Ice cream %d: " R, i + 1);
        scanf("%s %d", flavors[i].flavor, &flavors[i].preparation_time);
        flavors[i].id = i;
    }

    printf(UWHT "Scanning for topping names and quantities:\n" R);
    for (int i = 0; i < T; ++i)
    {
        printf(DGREY "Topping %d: " R, i + 1);
        scanf("%s %d", topping_info[i][0], &topping_info[i][1]);
        toppings[i].id = i;
        // update to Topping quantity also
        strcpy(toppings[i].topping, topping_info[i][0]);
        toppings[i].quantity = atoi(topping_info[i][1]);
        toppings[i].isAvailable = 1;
    }

    char buffer[1000];
    int customer_id = 0;

    // skip newline character
    getchar();

    printf(UWHT "Scanning for customer orders:\n" R);
    while (1)
    {
        memset(buffer, 0, sizeof(buffer));
        printf(DGREY "Customer %d: " R, customer_id + 1);

        fgets(buffer, sizeof(buffer), stdin);

        if (buffer[0] == '\n')
        {
            break;
        }

        buffer[strlen(buffer) - 1] = '\0'; // Remove newline character

        CustomerOrder *order = &customerOrders[customer_id];
        order->id = customer_id++;

        parseCustomerOrder(buffer, order);
    }

    sem_init(&customer_sem, 0, K);
    sem_init(&machineLock, 0, 1);
    sem_init(&toppingLock, 0, 1);
    sem_init(&printLock, 0, 1);
    sem_init(&machineTimeAvailableLock, 0, 1);

    for (int i = 0; i < N; ++i)
    {
        sem_init(&machine_sem[i], 0, 0);
    }

    for (int i = 0; i < N; ++i)
    {
        pthread_create(&machine_thread_ids[i], NULL, machine_thread, (void *)&machines[i].id);
    }

    for (int i = 0; i < customer_id; ++i)
    {
        pthread_create(&customer_thread_ids[i], NULL, customer_thread, (void *)&customerOrders[i]);
    }

    for (int i = 0; i < customer_id; ++i)
    {
        pthread_join(customer_thread_ids[i], NULL);
    }

    for (int i = 0; i < N; ++i)
    {
        pthread_join(machine_thread_ids[i], NULL);
    }

    return 0;
}
