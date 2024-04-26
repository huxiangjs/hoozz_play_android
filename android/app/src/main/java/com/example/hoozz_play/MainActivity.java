/**
 *
 * Created on 2023/09/03
 *
 * Author: Hoozz (huxiangjs@foxmail.com)
 *
 */

package com.example.hoozz_play;

import android.os.Bundle;
import androidx.annotation.NonNull;
import android.util.Log;
import android.view.WindowManager;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.example.hoozz_play.adapter.MLX90640Adapter;
import com.example.hoozz_play.adapter.ESPTouchAdapter;

public class MainActivity extends FlutterActivity {
    private final String TAG = MainActivity.class.getSimpleName();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        /* No sleep */
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
	/* MLX90640 */
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "MLX90640_EVENT")
                .setStreamHandler(new MLX90640Adapter(getBaseContext()));
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "MLX90640_METHOD")
                .setMethodCallHandler(
                    (call, result) -> {
                        Log.d(TAG, "call " + call.method);
                        /*
                        if (!call.method.equals("getXXXX")) {
                            // no support
                            result.notImplemented();
                        }
                        */
                        // return to flutter
                        result.success(MLX90640Adapter.callFunction(call.method, call.argument("value")));
                    }
                );
	/* ESP Touch */
	ESPTouchAdapter espTouchAdapter = new ESPTouchAdapter(getBaseContext());
	new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "ESPTOUCH_EVENT")
                .setStreamHandler(espTouchAdapter);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "ESPTOUCH_METHOD")
                .setMethodCallHandler(
                    (call, result) -> {
                        Log.d(TAG, "call " + call.method);
                        // return to flutter
                        result.success(espTouchAdapter.callFunction(call.method, call));
                    }
                );
        Log.d(TAG, "configureFlutterEngine done");
    }

}
