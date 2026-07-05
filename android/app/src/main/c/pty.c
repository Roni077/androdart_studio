#include <jni.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pthread.h>
#include <termios.h>
#include <pty.h>

typedef struct {
    int master_fd;
    pid_t child_pid;
    int is_running;
    pthread_t read_thread;
    int session_id;
} pty_session_t;

static JavaVM *g_jvm = NULL;

typedef struct {
    pty_session_t *session;
    jobject callback;
    jmethodID on_output_method;
    jmethodID on_exit_method;
} read_thread_arg_t;

static void *read_thread_func(void *arg) {
    read_thread_arg_t *rarg = (read_thread_arg_t *)arg;
    pty_session_t *session = rarg->session;
    char buf[4096];

    JNIEnv *env = NULL;
    (*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL);

    while (session->is_running) {
        ssize_t n = read(session->master_fd, buf, sizeof(buf) - 1);
        if (n > 0) {
            buf[n] = '\0';
            jstring jstr = (*env)->NewStringUTF(env, buf);
            (*env)->CallVoidMethod(env, rarg->callback, rarg->on_output_method,
                                   (jint)session->session_id, jstr);
            (*env)->DeleteLocalRef(env, jstr);
        } else if (n == 0) {
            break;
        } else {
            if (errno == EIO) break;
            if (errno == EINTR) continue;
            break;
        }
    }

    session->is_running = 0;
    jint exit_code = -1;
    int status;
    waitpid(session->child_pid, &status, 0);
    if (WIFEXITED(status)) {
        exit_code = WEXITSTATUS(status);
    }
    (*env)->CallVoidMethod(env, rarg->callback, rarg->on_exit_method,
                           (jint)session->session_id, exit_code);

    (*g_jvm)->DetachCurrentThread(g_jvm);

    (*env)->DeleteGlobalRef(env, rarg->callback);
    free(rarg);
    return NULL;
}

JNIEXPORT jint JNICALL
Java_com_androdartstudio_flutteride_androdart_1studio_MainActivity_nativeCreatePty(
    JNIEnv *env,
    jobject thiz,
    jobject callback,
    jstring command,
    jobjectArray args,
    jobjectArray envVars,
    jstring workingDir) {

    (*env)->GetJavaVM(env, &g_jvm);

    jclass cb_class = (*env)->GetObjectClass(env, callback);
    jmethodID on_output = (*env)->GetMethodID(env, cb_class, "onOutput", "(ILjava/lang/String;)V");
    jmethodID on_exit = (*env)->GetMethodID(env, cb_class, "onExit", "(II)V");

    int master_fd;
    int slave_fd;
    struct winsize ws = { .ws_row = 24, .ws_col = 80, .ws_xpixel = 0, .ws_ypixel = 0 };

    if (openpty(&master_fd, &slave_fd, NULL, NULL, &ws) == -1) {
        return -1;
    }

    int flags = fcntl(master_fd, F_GETFL, 0);
    fcntl(master_fd, F_SETFL, flags | O_NONBLOCK);

    pid_t pid = fork();
    if (pid < 0) {
        close(master_fd);
        close(slave_fd);
        return -1;
    }

    if (pid == 0) {
        close(master_fd);
        setsid();
        ioctl(slave_fd, TIOCSCTTY, 0);
        dup2(slave_fd, STDIN_FILENO);
        dup2(slave_fd, STDOUT_FILENO);
        dup2(slave_fd, STDERR_FILENO);
        if (slave_fd > 2) close(slave_fd);

        if (envVars != NULL) {
            int envLen = (*env)->GetArrayLength(env, envVars);
            for (int i = 0; i < envLen; i += 2) {
                if (i + 1 < envLen) {
                    jstring key = (jstring)(*env)->GetObjectArrayElement(env, envVars, i);
                    jstring val = (jstring)(*env)->GetObjectArrayElement(env, envVars, i + 1);
                    const char *keyStr = (*env)->GetStringUTFChars(env, key, NULL);
                    const char *valStr = (*env)->GetStringUTFChars(env, val, NULL);
                    setenv(keyStr, valStr, 1);
                    (*env)->ReleaseStringUTFChars(env, key, keyStr);
                    (*env)->ReleaseStringUTFChars(env, val, valStr);
                    (*env)->DeleteLocalRef(env, key);
                    (*env)->DeleteLocalRef(env, val);
                }
            }
        }

        if (workingDir != NULL) {
            const char *dirStr = (*env)->GetStringUTFChars(env, workingDir, NULL);
            chdir(dirStr);
            (*env)->ReleaseStringUTFChars(env, workingDir, dirStr);
        }

        const char *cmd = (*env)->GetStringUTFChars(env, command, NULL);
        int argc = 0;
        if (args != NULL) {
            argc = (*env)->GetArrayLength(env, args);
        }
        char **argv = (char **)malloc(sizeof(char *) * (argc + 2));
        argv[0] = (char *)cmd;
        for (int i = 0; i < argc; i++) {
            jstring arg = (jstring)(*env)->GetObjectArrayElement(env, args, i);
            argv[i + 1] = (char *)(*env)->GetStringUTFChars(env, arg, NULL);
            (*env)->DeleteLocalRef(env, arg);
        }
        argv[argc + 1] = NULL;

        execvp(cmd, argv);
        // If execvp fails, write error to stderr and exit
        const char *err_msg = "execvp failed: command not found or permission denied\n";
        write(STDERR_FILENO, err_msg, strlen(err_msg));
        _exit(127);
    }

    close(slave_fd);

    pty_session_t *session = (pty_session_t *)malloc(sizeof(pty_session_t));
    session->master_fd = master_fd;
    session->child_pid = pid;
    session->is_running = 1;
    session->session_id = (int)(intptr_t)session;

    read_thread_arg_t *rarg = (read_thread_arg_t *)malloc(sizeof(read_thread_arg_t));
    rarg->session = session;
    rarg->callback = (*env)->NewGlobalRef(env, callback);
    rarg->on_output_method = on_output;
    rarg->on_exit_method = on_exit;
    pthread_create(&session->read_thread, NULL, read_thread_func, rarg);

    return (jint)session->session_id;
}

JNIEXPORT jint JNICALL
Java_com_androdartstudio_flutteride_androdart_1studio_MainActivity_nativeWritePty(
    JNIEnv *env,
    jobject thiz,
    jint sessionPtr,
    jstring input) {

    pty_session_t *session = (pty_session_t *)(intptr_t)sessionPtr;
    if (session == NULL || !session->is_running) return -1;

    const char *str = (*env)->GetStringUTFChars(env, input, NULL);
    ssize_t len = strlen(str);
    ssize_t written = write(session->master_fd, str, len);
    (*env)->ReleaseStringUTFChars(env, input, str);

    return (jint)written;
}

JNIEXPORT jint JNICALL
Java_com_androdartstudio_flutteride_androdart_1studio_MainActivity_nativeResizePty(
    JNIEnv *env,
    jobject thiz,
    jint sessionPtr,
    jint cols,
    jint rows) {

    pty_session_t *session = (pty_session_t *)(intptr_t)sessionPtr;
    if (session == NULL || !session->is_running) return -1;

    struct winsize ws = { .ws_row = rows, .ws_col = cols, .ws_xpixel = 0, .ws_ypixel = 0 };
    return ioctl(session->master_fd, TIOCSWINSZ, &ws);
}

JNIEXPORT jint JNICALL
Java_com_androdartstudio_flutteride_androdart_1studio_MainActivity_nativeClosePty(
    JNIEnv *env,
    jobject thiz,
    jint sessionPtr) {

    pty_session_t *session = (pty_session_t *)(intptr_t)sessionPtr;
    if (session == NULL) return -1;

    session->is_running = 0;
    if (session->child_pid > 0) {
        kill(session->child_pid, SIGHUP);
    }
    if (session->master_fd >= 0) {
        close(session->master_fd);
    }
    pthread_join(session->read_thread, NULL);
    free(session);
    return 0;
}

JNIEXPORT jstring JNICALL
Java_com_androdartstudio_flutteride_androdart_1studio_MainActivity_nativeGetNativeLibDir(
    JNIEnv *env,
    jobject thiz) {

    jclass context_class = (*env)->FindClass(env, "android/content/Context");
    jmethodID get_files_dir = (*env)->GetMethodID(env, context_class, "getFilesDir", "()Ljava/io/File;");
    jobject files_dir = (*env)->CallObjectMethod(env, thiz, get_files_dir);

    jclass file_class = (*env)->FindClass(env, "java/io/File");
    jmethodID get_path = (*env)->GetMethodID(env, file_class, "getAbsolutePath", "()Ljava/lang/String;");
    jstring path = (jstring)(*env)->CallObjectMethod(env, files_dir, get_path);

    (*env)->DeleteLocalRef(env, context_class);
    (*env)->DeleteLocalRef(env, files_dir);
    (*env)->DeleteLocalRef(env, file_class);

    return path;
}
