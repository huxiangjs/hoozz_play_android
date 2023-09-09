/**
 * @file mlx90640.cpp
 * @author Hoozz (huxiangjs@foxmail.com)
 * @brief 
 * @version 0.1
 * @date 2023-08-27
 * 
 * @copyright Copyright (c) 2023
 * 
 */
#include <jni.h>
#include <string.h>
#include <android/log.h>
#include <malloc.h>
#include <stdio.h>
#include <MLX90640_I2C_Driver.h>

// #define DEBUG

#define I2C_TO_SERIAL_CMD_PING      0x00
#define I2C_TO_SERIAL_CMD_RESET     0x01
#define I2C_TO_SERIAL_CMD_WRITE     0x02
#define I2C_TO_SERIAL_CMD_READ      0x03
#define I2C_TO_SERIAL_CMD_WAIT      0x04

#define LOG_TAG "MLX90640"

#define MLX90640_I2C_ADDR           0x33

#define MLX90640_JAVA_PATH          "com/example/hoozz_play/serial/MLX90640"

#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

static JNIEnv *g_env = NULL;

/* Call a static method of a Java class */
static void call_java_static_method(const void *retval, const char* method_name, const char* method_sig, ...) {
    /* Check if the JNI environment has been initialized */
    if (g_env == NULL) {
        LOGE("JNI environment is not initialized");
        return;
    }

    jclass java_class = g_env->FindClass(MLX90640_JAVA_PATH);

    jmethodID method_id = g_env->GetStaticMethodID(java_class, method_name, method_sig);

    va_list args;
    va_start(args, method_sig);

    /* According to the return type of the method signature, call the corresponding static method */
    switch (method_sig[strlen(method_sig) - 1]) {
        case 'V': // void
            g_env->CallStaticVoidMethodV(java_class, method_id, args);
            break;
        case 'Z': // boolean
            *((jboolean *)retval) = g_env->CallStaticBooleanMethodV(java_class, method_id, args);
            break;
        case 'B': // byte
            *((jbyte *)retval) = g_env->CallStaticByteMethodV(java_class, method_id, args);
            break;
        case 'C': // char
            *((jchar *)retval) = g_env->CallStaticCharMethodV(java_class, method_id, args);
            break;
        case 'S': // short
            *((jshort *)retval) = g_env->CallStaticShortMethodV(java_class, method_id, args);
            break;
        case 'I': // int
            *((jint *)retval) = g_env->CallStaticIntMethodV(java_class, method_id, args);
            break;
        case 'J': // long
            *((jlong *)retval) = g_env->CallStaticLongMethodV(java_class, method_id, args);
            break;
        case 'F': // float
            *((jfloat *)retval) = g_env->CallStaticFloatMethodV(java_class, method_id, args);
            break;
        case 'D': // double
            *((jdouble *)retval) = g_env->CallStaticDoubleMethodV(java_class, method_id, args);
            break;
        case 'L': // object
            *((jobject *)retval) = g_env->CallStaticObjectMethodV(java_class, method_id, args);
            break;
        default:
            LOGI("Unknown method signature: %s", method_sig);
    }

    va_end(args);
}

#if defined(DEBUG)
static void __hex_dump(void* data, uint32_t size)
{
    uint8_t* p = (uint8_t*)data;
    while (size--)
        LOGD("%02X ", *p++);
    LOGD("\n");
}
#endif

static int __serial_write(uint8_t *data, uint32_t size) {
    /* Check if the JNI environment has been initialized */
    if (g_env == NULL) {
        LOGE("JNI environment is not initialized");
        return -1;
    }

    jclass java_class = g_env->FindClass(MLX90640_JAVA_PATH);

    jbyteArray array = g_env->NewByteArray(size);

    g_env->SetByteArrayRegion(array, 0, size, (jbyte *)data);

    /* Call the static method writeData of the class, pass in a jbyteArray parameter, and return an int value */
    jmethodID method_id = g_env->GetStaticMethodID(java_class, "writeData", "([B)I");
    int result = (int) g_env->CallStaticIntMethod(java_class, method_id, array);

    g_env->DeleteLocalRef(array);

#if defined(DEBUG)
    LOGD("W: ");
    __hex_dump(data, size);
#endif
    return result;
}

static int __serial_read(uint8_t *data, uint32_t size) {
    int result = 0;

    /* Check if the JNI environment has been initialized */
    if (g_env == NULL) {
        LOGE("JNI environment is not initialized");
        return -1;
    }

    /* Find and load Java classes */
    jclass java_class = g_env->FindClass(MLX90640_JAVA_PATH);

    /* Call the static method readData of the class, pass in an int value, and return a byte[] value */
    jmethodID method_id = g_env->GetStaticMethodID(java_class, "readData", "(I)[B");
    jbyteArray ret =  (jbyteArray)g_env->CallStaticObjectMethod(java_class, method_id, (jint)size);;

    if (!g_env->IsSameObject(ret, NULL)) {
        // int length = g_env->GetArrayLength(ret);
        /* Get the element pointer of the return value */
        jbyte *bytes = g_env->GetByteArrayElements(ret, NULL);
        /* Copy data */
        memcpy(data, bytes, size);
        /* Frees the element pointer of the return value */
        g_env->ReleaseByteArrayElements(ret, bytes, 0);
    } else {
        result = -1;
    }

    g_env->DeleteLocalRef(ret);

#if defined(DEBUG)
    LOGD("R: ");
    __hex_dump(data, size);
#endif
    return result;
}

void MLX90640_I2CInit(void)
{
    /* Do nothing */
}

int MLX90640_I2CGeneralReset(void)
{
    int ret;
    uint8_t reset_pack[2] = { I2C_TO_SERIAL_CMD_RESET };

    ret = __serial_write(reset_pack, 1);
    if (ret)
        return -1;

    ret = __serial_read(reset_pack, 2);
    if (ret)
        return -1;

    if (reset_pack[0] != I2C_TO_SERIAL_CMD_RESET || reset_pack[1])
        return -1;

    return 0;
}

int MLX90640_I2CRead(uint8_t slaveAddr, uint16_t startAddress, uint16_t nMemAddressRead, uint16_t* data)
{
    int ret;
    uint8_t read_pack[6] = { I2C_TO_SERIAL_CMD_READ };

    read_pack[1] = slaveAddr;
    read_pack[2] = (uint8_t)(startAddress & 0xFF);
    read_pack[3] = (uint8_t)(startAddress >> 8);
    read_pack[4] = (uint8_t)(nMemAddressRead & 0xFF);
    read_pack[5] = (uint8_t)(nMemAddressRead >> 8);

    ret = __serial_write(read_pack, 6);
    if (ret == -1)
        return -1;

    ret = __serial_read(read_pack, 2);
    if (ret)
        return -1;

    if (read_pack[0] != I2C_TO_SERIAL_CMD_READ || read_pack[1])
        return -1;

    ret = __serial_read((uint8_t *)data, nMemAddressRead * 2);
    if (ret == -1)
        return -1;

    return 0;
}

int MLX90640_I2CWrite(uint8_t slaveAddr, uint16_t writeAddress, uint16_t data)
{
    int ret;
    uint8_t write_pack[6] = { I2C_TO_SERIAL_CMD_WRITE };

    write_pack[1] = slaveAddr;
    write_pack[2] = (uint8_t)(writeAddress & 0xFF);
    write_pack[3] = (uint8_t)(writeAddress >> 8);
    write_pack[4] = (uint8_t)(data & 0xFF);
    write_pack[5] = (uint8_t)(data >> 8);

    ret = __serial_write(write_pack, 6);
    if (ret == -1)
        return -1;

    ret = __serial_read(write_pack, 2);
    if (ret)
        return -1;

    if (write_pack[0] != I2C_TO_SERIAL_CMD_WRITE || write_pack[1])
        return -1;

    return 0;
}

void MLX90640_I2CFreqSet(int freq)
{
    /* Do nothing */
}

static uint16_t eeMLX90640[832];
static uint16_t mlx90640Frame[834];
static float mlx90640To[768];
static paramsMLX90640 mlx90640;
static float vdd;
static float Ta;
static float emissivity = 0.95f;
/* the default shift for a MLX90640 device in open air */
static float ta_shift = -8.0f;
static float tr;
static int subpage;

static char print_buffer[1024];
static void MLX90640_PrintFrame(void)
{
    int i, j, count;

    for (i = 0; i < MLX90640_COLUMN_SIZE; i++) {
        count = 0;
        for (j = 0; j < MLX90640_LINE_SIZE; j++) {
            count += snprintf(print_buffer + count, sizeof(print_buffer) - count,
                              "%4.1f, ", mlx90640To[i * MLX90640_LINE_SIZE + j]);
            if (count == sizeof(print_buffer) - 1)
                break;
        }
        LOGI("%s", print_buffer);
    }
}

/* Blocking wait */
static int MLX90640_WaitFrame(uint8_t slaveAddr)
{
    int ret;
    uint8_t wait_pack[2] = { I2C_TO_SERIAL_CMD_WAIT };

    wait_pack[1] = slaveAddr;

    ret = __serial_write(wait_pack, 2);
    if (ret)
        return -1;

    ret = __serial_read(wait_pack, 2);
    if (ret)
        return -1;

    if (wait_pack[0] != I2C_TO_SERIAL_CMD_WAIT || wait_pack[1])
        return -1;

    return 0;
}

static int MLX90640_UpdateFrame(uint8_t slaveAddr)
{
    int status;

    status = MLX90640_WaitFrame(slaveAddr);
    if (status == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }

    status = MLX90640_GetFrameData(slaveAddr, mlx90640Frame);
    if (status == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }

    vdd = MLX90640_GetVdd(mlx90640Frame, &mlx90640); // vdd = 3.3
    Ta = MLX90640_GetTa(mlx90640Frame, &mlx90640); // Ta = 27.18
    subpage = MLX90640_GetSubPageNumber(mlx90640Frame);

    /* reflected temperature based on the sensor */
    tr = Ta + ta_shift;
    /* ambient temperature */
    MLX90640_CalculateTo(mlx90640Frame, &mlx90640, emissivity, tr, mlx90640To);

    return 0;
}

static int MLX90640_Config(uint8_t slaveAddr)
{
    int curResolution;
    const char* curResolution_Mean[] = { "16-bit", "17-bit", "18-bit", "19-bit" };
    int curRR;
    const char* curRR_Mean[] = { "0.5Hz", "1Hz", "2Hz", "4Hz", "8Hz", "16Hz", "32Hz", "64Hz" };
    int curMode;
    int status;

    /* Reset */
    status = MLX90640_I2CGeneralReset();
    if (status)
        return -1;

    /* 18 bit */
    MLX90640_SetResolution(slaveAddr, 0x02);
    /* 2 Hz */
    // MLX90640_SetRefreshRate(slaveAddr, 0x02);
    /* 4 Hz */
    // MLX90640_SetRefreshRate(slaveAddr, 0x03);
    /* 8 Hz */
    MLX90640_SetRefreshRate(slaveAddr, 0x04);
    /* 16 Hz */
    // MLX90640_SetRefreshRate(slaveAddr, 0x05);
    /* 32 Hz */
    // MLX90640_SetRefreshRate(slaveAddr, 0x06);
    /* 64 Hz */
    // MLX90640_SetRefreshRate(slaveAddr, 0x07);

    curResolution = MLX90640_GetCurResolution(slaveAddr);
    if (curResolution == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }
    LOGI("curResolution: %s (%d)", curResolution_Mean[curResolution], curResolution);

    curRR = MLX90640_GetRefreshRate(slaveAddr);
    if (curRR == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }
    LOGI("curRR: %s (%d)", curRR_Mean[curRR], curRR);

    curMode = MLX90640_GetCurMode(slaveAddr);
    if (curMode == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }
    LOGI("curMode: %s (%d)",
           curMode == 0 ? "interleaved mode" :
           curMode == 1 ? "chess pattern mode" :
           "Unknown", curMode);

    status = MLX90640_DumpEE(slaveAddr, eeMLX90640);
    if (status == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }
    status = MLX90640_ExtractParameters(eeMLX90640, &mlx90640);
    if (status == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }

    status = MLX90640_UpdateFrame(slaveAddr);
    if (status == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }
    LOGI("vdd:%f, Ta:%f", vdd, Ta);
    LOGI("subpage: %d", subpage);
    MLX90640_PrintFrame();

    return 0;
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_setResolution(JNIEnv *env, jclass clazz, jint resolution) {
    g_env = env;
    return MLX90640_SetResolution(MLX90640_I2C_ADDR, resolution);
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_setRefreshRate(JNIEnv *env, jclass clazz, jint refresh_rate) {
    g_env = env;
    return MLX90640_SetRefreshRate(MLX90640_I2C_ADDR, refresh_rate);
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_getCurResolution(JNIEnv *env, jclass clazz) {
    g_env = env;
    return MLX90640_GetCurResolution(MLX90640_I2C_ADDR);
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_getRefreshRate(JNIEnv *env, jclass clazz) {
    g_env = env;
    return MLX90640_GetRefreshRate(MLX90640_I2C_ADDR);
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_defaultConfig(JNIEnv *env, jclass clazz) {
    g_env = env;
    return MLX90640_Config(MLX90640_I2C_ADDR);
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_getFrame(JNIEnv *env, jclass clazz, jfloatArray data) {
    g_env = env;

    int status;

    status = MLX90640_UpdateFrame(MLX90640_I2C_ADDR);
    if (status == -1) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }

    /* Get the length of the array */
    int len = env->GetArrayLength(data);
    if (len < 32 * 24) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }

    jfloat *array = env->GetFloatArrayElements(data, NULL);
    /* Check if fetch is successful, return if failed */
    if (array == NULL) {
        LOGE("Fail: %s:%d", __func__, __LINE__);
        return -1;
    }

    /* Copy data */
    memcpy(array, mlx90640To, sizeof(mlx90640To));

    /*
     * Use the ReleaseFloatArrayElements function to release the pointer
     * and synchronize the modified data into the Java array
     */
    env->ReleaseFloatArrayElements(data, array, 0);

    return 0;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_setEmissivity(JNIEnv *env, jclass clazz, jfloat value) {
    g_env = env;

    emissivity = value;
}
extern "C"
JNIEXPORT jfloat JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_getEmissivity(JNIEnv *env, jclass clazz) {
    g_env = env;

    return emissivity;
}
extern "C"
JNIEXPORT void JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_setTaShift(JNIEnv *env, jclass clazz, jfloat value) {
    g_env = env;

    ta_shift = value;
}
extern "C"
JNIEXPORT jfloat JNICALL
Java_com_example_hoozz_1play_serial_MLX90640_getTaShift(JNIEnv *env, jclass clazz) {
    g_env = env;

    return ta_shift;
}