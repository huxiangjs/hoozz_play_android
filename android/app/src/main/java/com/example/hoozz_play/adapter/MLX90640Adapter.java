/**
 * 
 * Created on 2023/09/03
 * 
 * Author: Hoozz (huxiangjs@foxmail.com)
 * 
 */

package com.example.hoozz_play.adapter;

import android.content.Context;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

import com.felhr.usbserial.UsbSerialDevice;
import com.felhr.usbserial.UsbSerialInterface;

import java.nio.charset.StandardCharsets;
import java.security.Provider;
import java.util.HashMap;
import java.util.List;

import com.example.hoozz_play.serial.UsbSerial;
import com.example.hoozz_play.serial.MLX90640;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;

public class MLX90640Adapter implements EventChannel.StreamHandler {

    private static final String TAG = MLX90640Adapter.class.getSimpleName();

    private UsbSerial usbSerial = null;
    private HashMap<String, Object> selectDevice = null;

    /* Declare an EventSink object to send events to the Flutter code */
    private EventChannel.EventSink eventSink = null;

    private Context context = null;

    private Handler handler = null;

    private GetFrameThread getFrameThread = null;

    private UsbSerialDevice selectSerialDevice = null;

    private static final int MSG_TYPE_SUCCESS = 0;
    private static final int MSG_TYPE_ERROR = 1;
    private static final int MSG_TYPE_OPEN = 3;
    private static final int MSG_TYPE_CLOSE = 4;
    private static final int MSG_TYPE_REFRESH_RATE = 5;
    private static final int MSG_TYPE_EMISSIVITY = 6;
    private static final int MSG_TYPE_TA_SHIFT = 7;
    private static final int MSG_TYPE_FRAME_DATA = 8;

    private void sendMessage(int type, Object data) {
        if (handler == null)
            return;

        Message msg = new Message();
        msg.arg1 = type;
        msg.obj = data;
        handler.sendMessage(msg);
    }

    public MLX90640Adapter(Context context) {
        this.context = context;
    
        handler = new Handler() {
            @Override
            public void handleMessage(Message msg) {
                switch(msg.arg1) {
                    case MSG_TYPE_SUCCESS: {
                        String desc = msg.obj != null ? (String)msg.obj : "";
                        eventSink.success("S" + desc);
                        break;
                    }
                    case MSG_TYPE_ERROR: {
                        String desc = msg.obj != null ? (String)msg.obj : "";
                        eventSink.success("E" + desc);
                        break;
                    }
                    case MSG_TYPE_OPEN: {
                        String desc = msg.obj != null ? (String)msg.obj : "";
                        eventSink.success("O" + desc);
                        break;
                    }
                    case MSG_TYPE_CLOSE: {
                        String desc = msg.obj != null ? (String)msg.obj : "";
                        eventSink.success("C" + desc);
                        break;
                    }
                    case MSG_TYPE_REFRESH_RATE: {
                        String desc = msg.obj != null ? (String)msg.obj : "";
                        eventSink.success("R" + desc);
                        break;
                    }
                    case MSG_TYPE_EMISSIVITY: {
                        String desc = msg.obj != null ? (String)msg.obj : "";
                        eventSink.success("F" + desc);
                        break;
                    }
                    case MSG_TYPE_TA_SHIFT: {
                        String desc = msg.obj != null ? (String)msg.obj : "";
                        eventSink.success("T" + desc);
                        break;
                    }
                    case MSG_TYPE_FRAME_DATA: {
                        eventSink.success(msg.obj);
            break;
                    }
                }
            }
        };
    }

    private boolean loop = false;

    private synchronized void setLoop(boolean newValue) {
        loop = newValue;
    }

    private synchronized boolean getLoop() {
        return loop;
    }

    private class GetFrameThread extends Thread {

        @Override
        public void run() {
            if (!getLoop())
                return;

            int ret = MLX90640.defaultConfig();
            Log.d(TAG, "defaultConfig result: " + ret);
            if (ret < 0) {
                sendMessage(MSG_TYPE_ERROR, "Default Config result: " + ret);
                return;
            }

            int refresh_rate = MLX90640.getRefreshRate();
            Log.d(TAG, "refresh_rate result: " + refresh_rate);
            if (refresh_rate < 0) {
                sendMessage(MSG_TYPE_ERROR, "Refresh Rate result: " + refresh_rate);
                return;
            }
            sendMessage(MSG_TYPE_REFRESH_RATE, String.valueOf(refresh_rate));

            int resolution = MLX90640.getCurResolution();
            Log.d(TAG, "resolution result: " + resolution);
            if (resolution < 0) {
                sendMessage(MSG_TYPE_ERROR, "Resolution result: " + resolution);
                return;
            }

            float emissivity = MLX90640.getEmissivity();
            Log.d(TAG, "emissivity result: " + emissivity);
            sendMessage(MSG_TYPE_EMISSIVITY, String.valueOf(emissivity));

            float shift = MLX90640.getTaShift();
            Log.d(TAG, "Ta shift result: " + shift);
            sendMessage(MSG_TYPE_TA_SHIFT, String.valueOf(shift));

            sendMessage(MSG_TYPE_OPEN, null);
            Log.d(TAG, "recv thread while");

            while (ret == 0 && getLoop()) {
                float[] data = new float[32 * 24];

                /* Recv a frame data */
                ret = MLX90640.getFrame(data);
                if (ret < 0)
                    break;

                /* Send a frame data */
                sendMessage(MSG_TYPE_FRAME_DATA, data);
            }

            Log.d(TAG, "recv thread exited");
            sendMessage(MSG_TYPE_CLOSE, null);
        }
    }

    private void configSerialPort(UsbSerialDevice serialDevice) {
        /* Sync open */
        serialDevice.syncOpen();
        serialDevice.setBaudRate(115200);
        serialDevice.setDataBits(UsbSerialInterface.DATA_BITS_8);
        serialDevice.setParity(UsbSerialInterface.PARITY_NONE);
        serialDevice.setFlowControl(UsbSerialInterface.FLOW_CONTROL_OFF);

        MLX90640.setInputStream(serialDevice.getInputStream());
        MLX90640.setOutputStream(serialDevice.getOutputStream());
    }

    private UsbSerial.Result usbResult = new UsbSerial.Result() {
        @Override
        public void success(String tag, String msg, Object o) {
            /* Do nothing */
            Log.d(TAG, "Success" + msg);
        }

        @Override
        public void success(List<HashMap<String, Object>> devices) {
            if (devices.size() == 0)
                return;

            String desc;
            /* Select the first one */
            selectDevice = devices.get(0);
            String deviceName = (String) selectDevice.get("deviceName");
            String productName = (String) selectDevice.get("productName");
            if (productName != null)
                desc = productName;
            else
                desc = deviceName;

            int vid = (int) selectDevice.get("vid");
            int pid = (int) selectDevice.get("pid");
            int deviceId = (int) selectDevice.get("deviceId");
            Log.d(TAG, "Connect device:" + " vid:" + vid + " pid:" + pid + " deviceId: " + deviceId);
            /* Connect device */
            usbSerial.createTyped("", vid, pid, deviceId, -1, usbResult);
        }

        @Override
        public void success(UsbSerialDevice serialDevice) {
            String desc;
            String deviceName = (String) selectDevice.get("deviceName");
            String productName = (String) selectDevice.get("productName");
            if (productName != null)
                desc = productName;
            else
                desc = deviceName;

            selectSerialDevice = serialDevice;

            Log.d(TAG, "Config serial device: " + desc);
            configSerialPort(serialDevice);

            /* Start receiving */
            getFrameThread = new GetFrameThread();
            getFrameThread.start();
        }

        @Override
        public void error(String tag, String msg, Object o) {
            Log.e(TAG, "Error: " + msg);
            sendMessage(MSG_TYPE_ERROR, msg);
        }
    };

    private UsbSerial.Event usbEvent = new UsbSerial.Event() {
        @Override
        public void success(HashMap<String, Object> msg) {
            Log.d(TAG, "List devices success");
            /* List devices */
            usbSerial.listDevices(usbResult);
        }
    };

    private void start() {
        usbSerial = new UsbSerial();
        if (usbSerial == null) {
            Log.e(TAG, "usbSerial == null");
            return;
        }

        setLoop(true);

        usbSerial.register(context);

        /* Listen for USB plugging and unplugging events */
        usbSerial.onListen(usbEvent);

        /* List existing devices */
        usbSerial.listDevices(usbResult);
    }

    private void stop() {
        setLoop(false);

        if (getFrameThread != null) {
            try {
                getFrameThread.join(1000);
            } catch (InterruptedException  e) {
            }
            getFrameThread = null;
        }

        MLX90640.setInputStream(null);
        MLX90640.setOutputStream(null);

        if (selectSerialDevice != null) {
            selectSerialDevice.syncClose();
            selectSerialDevice = null;
        }

        if (usbSerial != null) {
            usbSerial.onCancel();
            usbSerial.unregister();
            usbSerial = null;
        }

        selectDevice = null;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        Log.d(TAG, "onListen");
        eventSink = events;

        start();
    }

    @Override
    public void onCancel(Object arguments) {
        Log.d(TAG, "onCancel");

        stop();
    }

    public static int callFunction(String funcName, Object arg) {
        if (funcName.equals("setTaShift")) {
            double newValue = (double)arg;
            Log.d(TAG, "newValue: " + newValue);
            MLX90640.setTaShift((float)newValue);
        } else if (funcName.equals("setEmissivity")) {
            double newValue = (double)arg;
            Log.d(TAG, "newValue: " + newValue);
            MLX90640.setEmissivity((float)newValue);
        } else if (funcName.equals("setRefreshRate")) {
            int newValue = (int)arg;
            Log.d(TAG, "newValue: " + newValue);
            return MLX90640.setRefreshRate(newValue);
        } else {
            return -1;
        }

        return 0;
    }
}



