// macOS main-thread dispatch helper for OpenGL Viewer.
// Allows the gos-vm thread to run GLFW/OpenGL calls on the main thread.

#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

// Synchronization: the calling thread blocks until the main thread finishes.
typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int done;
    void* result;
} sync_ctx_t;

// Create a sync context
sync_ctx_t* sync_create() {
    sync_ctx_t* ctx = malloc(sizeof(sync_ctx_t));
    pthread_mutex_init(&ctx->mutex, NULL);
    pthread_cond_init(&ctx->cond, NULL);
    ctx->done = 0;
    ctx->result = NULL;
    return ctx;
}

// Wait for the main thread to finish and get the result
void* sync_wait(sync_ctx_t* ctx) {
    pthread_mutex_lock(&ctx->mutex);
    while (!ctx->done) {
        pthread_cond_wait(&ctx->cond, &ctx->mutex);
    }
    void* result = ctx->result;
    pthread_mutex_unlock(&ctx->mutex);
    return result;
}

// Signal that the main thread is done
void sync_signal(sync_ctx_t* ctx, void* result) {
    pthread_mutex_lock(&ctx->mutex);
    ctx->result = result;
    ctx->done = 1;
    pthread_cond_signal(&ctx->cond);
    pthread_mutex_unlock(&ctx->mutex);
}

// Free the sync context
void sync_free(sync_ctx_t* ctx) {
    pthread_mutex_destroy(&ctx->mutex);
    pthread_cond_destroy(&ctx->cond);
    free(ctx);
}

// The function pointer type for work to run on the main thread
typedef void* (*main_thread_fn)(void* arg);

// dispatch_run_on_main runs a function on the main thread and blocks until done.
// Returns the function's return value.
void* dispatch_run_on_main(main_thread_fn fn, void* arg) {
    sync_ctx_t* ctx = sync_create();
    
    // Create a block that calls fn(arg) and signals the sync context
    // Using dispatch_async with a block literal
    dispatch_async(dispatch_get_main_queue(), ^{
        void* result = fn(arg);
        sync_signal(ctx, result);
    });
    
    // Wait for the main thread to finish
    void* result = sync_wait(ctx);
    sync_free(ctx);
    return result;
}
