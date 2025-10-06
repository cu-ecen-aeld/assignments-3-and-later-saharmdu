#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    // wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    struct thread_data* thread_func_args = (struct thread_data *)thread_param;
    if (thread_func_args == NULL) {
        ERROR_LOG("thread received null arguments");
        return thread_param;
    }

    thread_func_args->thread_complete_success = false;

    unsigned int wait_to_obtain_us = (unsigned int)thread_func_args->wait_to_obtain_ms * 1000U;
    if (usleep(wait_to_obtain_us) != 0) {
        ERROR_LOG("wait_to_obtain_usleep failed");
        return thread_param;
    }

    int rc = pthread_mutex_lock(thread_func_args->mutex);
    if (rc != 0) {
        ERROR_LOG("pthread_mutex_lock failed: %d", rc);
        return thread_param;
    }

    unsigned int wait_to_release_us = (unsigned int)thread_func_args->wait_to_release_ms * 1000U;
    if (usleep(wait_to_release_us) != 0) {
        ERROR_LOG("wait_to_release_usleep failed");
        pthread_mutex_unlock(thread_func_args->mutex);
        return thread_param;
    }

    rc = pthread_mutex_unlock(thread_func_args->mutex);
    if (rc != 0) {
        ERROR_LOG("pthread_mutex_unlock failed: %d", rc);
        return thread_param;
    }

    thread_func_args->thread_complete_success = true;
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    if (thread == NULL || mutex == NULL) {
        return false;
    }

    struct thread_data *thread_func_args = malloc(sizeof(struct thread_data));
    if (thread_func_args == NULL) {
        ERROR_LOG("malloc failed for thread_data");
        return false;
    }

    thread_func_args->mutex = mutex;
    thread_func_args->wait_to_obtain_ms = wait_to_obtain_ms;
    thread_func_args->wait_to_release_ms = wait_to_release_ms;
    thread_func_args->thread_complete_success = false;

    int rc = pthread_create(thread, NULL, threadfunc, thread_func_args);
    if (rc != 0) {
        ERROR_LOG("pthread_create failed: %d", rc);
        free(thread_func_args);
        return false;
    }

    return true;
}
