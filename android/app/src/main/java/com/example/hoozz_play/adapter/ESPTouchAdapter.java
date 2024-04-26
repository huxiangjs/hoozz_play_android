/**
 *
 * Created on 2024/04/25
 *
 * Author: Hoozz (huxiangjs@foxmail.com)
 *
 */

package com.example.hoozz_play.adapter;

import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

import com.example.hoozz_play.esptouch.ESPTouch;
import com.example.hoozz_play.esptouch.ESPTouch.OnEspTouchFindListener;
import com.espressif.iot.esptouch.util.ByteUtil;
import com.espressif.iot.esptouch.util.TouchNetUtil;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class ESPTouchAdapter implements EventChannel.StreamHandler {

    private static final String TAG = ESPTouchAdapter.class.getSimpleName();

    /* Declare an EventSink object to send events to the Flutter code */
    private EventChannel.EventSink eventSink = null;

    private Context context = null;

    private ESPTouch espTouch = null;

    public ESPTouchAdapter(Context context) {
        this.context = context;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        Log.d(TAG, "onListen");
        eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        Log.d(TAG, "onCancel");
    }

    private OnEspTouchFindListener onEspTouchFindListener = new OnEspTouchFindListener() {
        @Override
        public void success(String ip, String mac) {
            // Send to flutter
            eventSink.success(ip + ' ' + mac);
        }
    };

    public int callFunction(String funcName, MethodCall args) {
        if (funcName.equals("startConfig")) {
            String wifiName = args.argument("name");
            String wifiPassword = args.argument("pwd");
            String wifiMac = args.argument("mac");
            String maxConfig = args.argument("max");
            // Log.d(TAG, wifiName + " " + wifiPassword);
            byte[] ssid = ByteUtil.getBytesByString(wifiName);         // Wi-Fi SSID
            byte[] password = ByteUtil.getBytesByString(wifiPassword); // Wi-Fi Password
            byte[] bssid = TouchNetUtil.parseBssid2bytes(wifiMac);     // Our MAC address
            byte[] deviceCount = maxConfig.getBytes();                 // The asynchronous task will end after configuring the specified number of devices
            byte[] broadcast = {1};                                    // Configured as broadcast
            if(espTouch != null) espTouch.stop();
            espTouch = new ESPTouch(context, onEspTouchFindListener);
            espTouch.start(ssid, bssid, password, deviceCount, broadcast);
        } else if (funcName.equals("stopConfig")) {
            if(espTouch != null) espTouch.stop();
        } else {
            return -1;
        }

        return 0;
    }
}
