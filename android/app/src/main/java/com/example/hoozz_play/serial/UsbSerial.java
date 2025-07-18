/**
 * refs: https://github.com/altera2015/usbserial/blob/master/android/src/main/java/dev/bessems/usbserial/UsbSerialPlugin.java
 * 
 * Modified by: Hoozz (huxiangjs@foxmail.com)
 * 
 */

package com.example.hoozz_play.serial;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.util.Log;

import com.felhr.usbserial.UsbSerialDevice;
import com.felhr.usbserial.UsbSerialInterface;

import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;

public class UsbSerial {
    private final String TAG = UsbSerial.class.getSimpleName();

    private android.content.Context m_Context;
    private UsbManager m_Manager;
    private Event m_Event;

    private static final String ACTION_USB_PERMISSION = "com.android.example.USB_PERMISSION";
    public static final String ACTION_USB_ATTACHED = "android.hardware.usb.action.USB_DEVICE_ATTACHED";
    public static final String ACTION_USB_DETACHED = "android.hardware.usb.action.USB_DEVICE_DETACHED";

    private final BroadcastReceiver usbReceiver = new BroadcastReceiver() {

        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent.getAction().equals(ACTION_USB_ATTACHED)) {
                Log.d(TAG, "ACTION_USB_ATTACHED");
                if ( m_Event != null ) {
                    UsbDevice device = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    HashMap<String, Object> msg = serializeDevice(device);
                    msg.put("event", ACTION_USB_ATTACHED);
                    m_Event.success(msg);
                }
            } else if (intent.getAction().equals(ACTION_USB_DETACHED)) {
                Log.d(TAG, "ACTION_USB_DETACHED");
                if ( m_Event != null ) {
                    UsbDevice device = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    HashMap<String, Object> msg = serializeDevice(device);
                    msg.put("event", ACTION_USB_DETACHED);
                    m_Event.success(msg);
                }
            }
        }
    };

    public UsbSerial() {
        m_Context = null;
        m_Manager = null;
    }

    private interface AcquirePermissionCallback {
        void onSuccess(UsbDevice device);
        void onFailed(UsbDevice device);
    }

    public interface Result {
        void success(String tag, String msg, Object o);
        void success(List<HashMap<String, Object>> devices);
        void success(UsbSerialDevice serialDeviceDevice);
        void error(String tag, String msg, Object o);
    }

    public interface Event {
        void success(HashMap<String, Object> msg);
    }

    private void acquirePermissions(UsbDevice device, AcquirePermissionCallback cb) {

        class BRC2 extends  BroadcastReceiver {

            private UsbDevice m_Device;
            private AcquirePermissionCallback m_CB;

            BRC2(UsbDevice device, AcquirePermissionCallback cb ) {
                m_Device = device;
                m_CB = cb;
            }

            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (ACTION_USB_PERMISSION.equals(action)) {
                    Log.e(TAG, "BroadcastReceiver intent arrived, entering sync...");
                    m_Context.unregisterReceiver(this);
                    synchronized (this) {
                        Log.e(TAG, "BroadcastReceiver in sync");
                        /* UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE); */
			boolean granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);
			boolean has =  m_Manager.hasPermission(m_Device);
                        if (granted || has) {
                            // createPort(m_DriverIndex, m_PortIndex, m_Result, false);
                            m_CB.onSuccess(m_Device);
                        } else {
                            Log.d(TAG, "permission denied for device ");
                            m_CB.onFailed(m_Device);
                        }
                    }
                }
            }
        }

        Context cw = m_Context; //m_Registrar.context();

        BRC2 usbReceiver = new BRC2(device, cb);

        int flags = 0;

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            flags = PendingIntent.FLAG_IMMUTABLE;
        } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            flags = PendingIntent.FLAG_MUTABLE;
        }

        PendingIntent permissionIntent = PendingIntent.getBroadcast(cw, 0, new Intent(ACTION_USB_PERMISSION), flags);

        IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);

	/* Android 14 and later */
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                cw.registerReceiver(usbReceiver, filter, Context.RECEIVER_EXPORTED);
        } else {
                cw.registerReceiver(usbReceiver, filter);
        }

        m_Manager.requestPermission(device, permissionIntent);
    }

    private void openDevice(String type, UsbDevice device, int iface, Result result, boolean allowAcquirePermission) {

        final AcquirePermissionCallback cb = new AcquirePermissionCallback() {

            @Override
            public void onSuccess(UsbDevice device) {
                openDevice(type, device, iface, result, false);
            }

            @Override
            public void onFailed(UsbDevice device) {
                result.error(TAG, "Failed to acquire permissions.", null);
            }
        };

        try {
            UsbDeviceConnection connection = m_Manager.openDevice(device);

            if ( connection == null && allowAcquirePermission ) {
                acquirePermissions(device, cb);
                return;
            }

            UsbSerialDevice serialDeviceDevice;
            if ( type.equals("") ) {
                serialDeviceDevice = UsbSerialDevice.createUsbSerialDevice(device, connection, iface);
            } else {
                serialDeviceDevice = UsbSerialDevice.createUsbSerialDevice(type, device, connection, iface);
            }

            if (serialDeviceDevice != null) {
                result.success(serialDeviceDevice);
                Log.d(TAG, "success.");
                return;
            }
            result.error(TAG, "Not an Serial device.", null);

        } catch ( java.lang.SecurityException e ) {

            if ( allowAcquirePermission ) {
                acquirePermissions(device, cb);
                return;
            } else {
                result.error(TAG, "Failed to acquire USB permission.", null);
            }
        } catch ( java.lang.Exception e ) {
            result.error(TAG, "Failed to acquire USB device.", null);
        }
    }

    public void createTyped(String type, int vid, int pid, int deviceId, int iface, Result result) {
        Map<String, UsbDevice> devices = m_Manager.getDeviceList();
        for (UsbDevice device : devices.values()) {

            if ( deviceId == device.getDeviceId() || (device.getVendorId() == vid && device.getProductId() == pid) ) {
                openDevice(type, device, iface, result, true);
                return;
            }
        }

        result.error(TAG, "No such device", null);
    }

    private HashMap<String, Object> serializeDevice(UsbDevice device) {
        HashMap<String, Object> dev = new HashMap<>();
        dev.put("deviceName", device.getDeviceName());
        dev.put("vid", device.getVendorId());
        dev.put("pid", device.getProductId());
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            dev.put("manufacturerName", device.getManufacturerName());
            dev.put("productName", device.getProductName());
            dev.put("interfaceCount", device.getInterfaceCount());
            /* if the app targets SDK >= android.os.Build.VERSION_CODES.Q and the app does not have permission to read from the device. */
            try {
                dev.put("serialNumber", device.getSerialNumber());
            } catch  ( java.lang.SecurityException e ) {
            }
        }
        dev.put("deviceId", device.getDeviceId());
        return dev;
    }

    public void listDevices(Result result) {
        Map<String, UsbDevice> devices = m_Manager.getDeviceList();
        if ( devices == null ) {
            result.error(TAG, "Could not get USB device list.", null);
            return;
        }
        List<HashMap<String, Object>> transferDevices = new ArrayList<>();

        for (UsbDevice device : devices.values()) {
            transferDevices.add(serializeDevice(device));
        }
        result.success(transferDevices);
    }

    public void onListen(Event event) {
        m_Event = event;
    }

    public void onCancel() {
        m_Event = null;
    }

    public void register(android.content.Context context) {
        m_Context = context;
        m_Manager = (UsbManager) m_Context.getSystemService(android.content.Context.USB_SERVICE);

        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_USB_DETACHED);
        filter.addAction(ACTION_USB_ATTACHED);
        m_Context.registerReceiver(usbReceiver, filter);
    }

    public void unregister() {
        m_Context.unregisterReceiver(usbReceiver);
        m_Manager = null;
        m_Context = null;
    }
}
