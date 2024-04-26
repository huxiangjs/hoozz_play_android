/**
 *
 * Created on 2024/04/25
 *
 * Author: Hoozz (huxiangjs@foxmail.com)
 *
 */

package com.example.hoozz_play.esptouch;

import android.content.Context;
import android.os.AsyncTask;
import com.espressif.iot.esptouch.EsptouchTask;
import com.espressif.iot.esptouch.IEsptouchListener;
import com.espressif.iot.esptouch.IEsptouchResult;
import com.espressif.iot.esptouch.IEsptouchTask;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import android.util.Log;

/* ESP smart network configuration */
public class ESPTouch extends AsyncTask<byte[], String, List<IEsptouchResult>> {

    private final String TAG = ESPTouch.class.getSimpleName();

    private final Object mLock = new Object();
    private Context context = null;
    private IEsptouchTask mEsptouchTask;
    private OnEspTouchFindListener onEspTouchFindListener = null;
    /*
     * Customize the thread pool to solve the problem that AsyncTask
     * in the same thread needs to wait for the previous one to be executed
     * before executing the next one.
     */
    final LinkedBlockingQueue<Runnable> blockingQueue = new LinkedBlockingQueue<Runnable>();
    final ExecutorService exec = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, blockingQueue);

    public interface OnEspTouchFindListener {
        void success(String ip, String mac);
    }

    public ESPTouch(Context context, OnEspTouchFindListener onEspTouchFindListener) {
        this.onEspTouchFindListener = onEspTouchFindListener;
        this.context = context;
    }

    private long usrTime = 0;

    /* Start configuration */
    public void start(byte[] ssid, byte[]  bssid, byte[]  password, byte[]  deviceCount, byte[]  broadcast) {
        executeOnExecutor(exec, ssid, bssid, password, deviceCount, broadcast);
        usrTime = System.currentTimeMillis();
    }

    /* Stop configuration */
    public void stop() {
        cancel(true);
        if (mEsptouchTask != null) {
            mEsptouchTask.interrupt();
        }
    }

    /* Automatically called when running in the background */
    @Override
    protected List<IEsptouchResult> doInBackground(byte[]... params) {
        int taskResultCount;
        synchronized (mLock) {
            byte[] apSsid = params[0];
            byte[] apBssid = params[1];
            byte[] apPassword = params[2];
            byte[] deviceCountData = params[3];
            byte[] broadcastData = params[4];
            taskResultCount = deviceCountData.length == 0 ? -1 : Integer.parseInt(new String(deviceCountData));
            mEsptouchTask = new EsptouchTask(apSsid, apBssid, apPassword, context);
            mEsptouchTask.setPackageBroadcast(broadcastData[0] == 1);
            mEsptouchTask.setEsptouchListener(new IEsptouchListener() {
                @Override
                public void onEsptouchResultAdded(IEsptouchResult result) {
                    publishProgress(result.getBssid(), result.getInetAddress().getHostName());
                }
            });
        }
        return mEsptouchTask.executeForResults(taskResultCount);
    }

    /* Processing progress updates */
    @Override
    protected void onProgressUpdate(String... strings) {
        Log.d(TAG, "Config OK, MAC:" + strings[0] + " IP:" + strings[1] + ", Cost:" + (System.currentTimeMillis() - usrTime) + "ms");
        onEspTouchFindListener.success(strings[1], strings[0]);
    }

    /* Final result */
    @Override
    protected void onPostExecute(List<IEsptouchResult> result) {
        /* The search task has ended and no results were received */
        IEsptouchResult firstResult = result.get(0);
        if (firstResult.isCancelled()) {
            return;
        }
        /* Some results were received before the task was cancelled */
        if (!firstResult.isSuc()) {
            return;
        }
        /* Print all results */
        ArrayList<CharSequence> resultMsgList = new ArrayList<>(result.size());
        Log.d(TAG, "Final result: ");
        for (IEsptouchResult touchResult : result) {
            String str = touchResult.getBssid() + " " + touchResult.getInetAddress().getHostAddress();
            Log.d(TAG, "\t" + str);
        }
    }
}
