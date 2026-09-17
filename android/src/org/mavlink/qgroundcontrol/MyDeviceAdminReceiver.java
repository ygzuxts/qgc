package org.mavlink.qgroundcontrol;

import android.app.admin.DeviceAdminReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class MyDeviceAdminReceiver extends DeviceAdminReceiver {
    private static final String TAG = MyDeviceAdminReceiver.class.getSimpleName();

    @Override
    public void onEnabled(Context context, Intent intent) {
        Log.i(TAG, "Device owner enabled");
    }

    @Override
    public void onDisabled(Context context, Intent intent) {
        Log.i(TAG, "Device owner disabled");
    }
}
