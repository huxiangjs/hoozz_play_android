/**
 * 
 * Created on 2023/09/03
 * 
 * Author: Hoozz (huxiangjs@foxmail.com)
 * 
 */

package com.example.hoozz_play.serial;

import android.util.Log;

import com.felhr.usbserial.SerialInputStream;
import com.felhr.usbserial.SerialOutputStream;

public class MLX90640 {
    private static String TAG = MLX90640.class.getSimpleName();

    private static SerialInputStream input = null;
    private static SerialOutputStream output = null;

    public static synchronized native int setResolution(int resolution);
    public static synchronized native int setRefreshRate(int refreshRate);
    public static synchronized native int getCurResolution();
    public static synchronized native int getRefreshRate();
    public static synchronized native int getFrame(float[] data);
    public static synchronized native int defaultConfig();
    public static synchronized native void setEmissivity(float value);
    public static synchronized native float getEmissivity();
    public static synchronized native void setTaShift(float value);
    public static synchronized native float getTaShift();

    static {
        System.loadLibrary("mlx90640");
    }

    /*
     * NOTE: Native C++ uses invoke when calling java,
     * so build.gradle needs to be configured to prevent
     * the method from being optimized.
     */
    public static int writeData(byte[] data) {
        if (output == null) {
            Log.e(TAG, "SerialOutputStream is null");
            return -1;
        }

        try {
            output.write(data);
        } catch (Exception e) {
            Log.e(TAG, "SerialOutputStream write exception");
            return -1;
        }

        return 0;
    }

    public static byte[] readData(int n) {
        if (input == null) {
            Log.e(TAG, "SerialInputStream is null");
            return null;
        }

        byte[] buff = new byte[n];

        try {
            for (int i = 0; i < n; i++) {
                int ret = input.read();
                if (ret == -1) {
                    return null;
                }
                buff[i] = (byte) ret;
            }
        } catch (Exception e) {
            Log.e(TAG, "SerialInputStream read exception");
            return null;
        }

        return buff;
    }

    public static synchronized void setInputStream(SerialInputStream input) {
        MLX90640.input = input;
    }

    public static synchronized void setOutputStream(SerialOutputStream output) {
        MLX90640.output = output;
    }
}
