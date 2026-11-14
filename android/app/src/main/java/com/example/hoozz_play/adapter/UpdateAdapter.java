/**
 *
 * Created on 2026/11/14
 *
 * Author: Hoozz (huxiangjs@foxmail.com)
 *
 */

package com.example.hoozz_play.adapter;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import androidx.core.content.FileProvider;

import java.io.File;

import com.example.hoozz_play.BuildConfig;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class UpdateAdapter implements MethodChannel.MethodCallHandler {

    private static final String TAG = UpdateAdapter.class.getSimpleName();

    private Context context = null;

    public UpdateAdapter(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "call " + call.method);
        if (call.method.equals("getGitHash")) {
            /* The git hash the app was built from (injected by the gradle build) */
            result.success(BuildConfig.GIT_COMMIT_HASH);
        } else if (call.method.equals("canInstallApk")) {
            result.success(canRequestInstall());
        } else if (call.method.equals("installApk")) {
            String path = call.argument("path");
            result.success(installApk(path));
        } else {
            result.notImplemented();
        }
    }

    private boolean canRequestInstall() {
        if (Build.VERSION.SDK_INT < 26) return true;
        return context.getPackageManager().canRequestPackageInstalls();
    }

    /**
     * Launch the system APK installer for the given file. The file must
     * live in the download directory (shared via the FileProvider, see
     * res/xml/file_provider_paths.xml).
     *
     * @return true when the installer was launched; false when the user
     *         still has to grant "Install unknown apps" (the settings
     *         page is opened then) or the launch failed.
     */
    private boolean installApk(String path) {
        try {
            /* Android 8+ (API 26+): "Install unknown apps" permission */
            if (!canRequestInstall()) {
                Intent intent = new Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:" + context.getPackageName()));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(intent);
                return false;
            }

            File file = new File(path);
            Uri uri = FileProvider.getUriForFile(
                    context,
                    context.getPackageName() + ".fileprovider",
                    file);

            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setDataAndType(uri, "application/vnd.android.package-archive");
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "installApk failed: " + e);
            return false;
        }
    }
}
