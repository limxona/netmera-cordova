package com.netmera.cordova.plugin;

import android.app.Application;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import com.netmera.Netmera;

public class NetmeraApplication extends Application {
    @Override
    public void onCreate() {
        Log.d("MyApplication", "onCreate");
        super.onCreate();

        try {
            ApplicationInfo ai = getPackageManager().getApplicationInfo(this.getPackageName(), PackageManager.GET_META_DATA);
            Bundle bundle = ai.metaData;
            String netmeraKey = bundle.getString("NETMERA_KEY");
            String netmeraFCM = bundle.getString("FCM_KEY");
            String netmeraBaseUrl = bundle.getString("NETMERA_BASE_URL");

            Netmera.init(this, netmeraFCM.trim().substring(1), netmeraKey.trim());
            if(!netmeraBaseUrl.trim().isEmpty()) {
                Netmera.setBaseUrl(netmeraBaseUrl);
            }
            Netmera.logging(true);
            Netmera.enablePopupPresentation();

            Log.d("TAG", "onCreate: hello");
        } catch (PackageManager.NameNotFoundException e) {
            Log.e("TAG", "Failed to load meta-data, NameNotFound: " + e.getMessage());
        } catch (NullPointerException e) {
            Log.e("TAG", "Failed to load meta-data, NullPointer: " + e.getMessage());
        }
    }
}