package org.apache.cordova.labs.keyboard;

import android.app.Activity;
import android.content.Context;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import android.graphics.Rect;
import android.util.DisplayMetrics;
import android.view.ViewTreeObserver.OnGlobalLayoutListener;

public class Keyboard extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
	Activity activity = this.cordova.getActivity();
	InputMethodManager imm = (InputMethodManager)activity.getSystemService(Context.INPUT_METHOD_SERVICE);

	View view;
	try {
	    view = (View)webView.getClass().getMethod("getView").invoke(webView);
	}
	catch (Exception e){
	    view = (View)webView;
	}

	if("show".equals(action)){
	    imm.showSoftInput(view, 0);
	    callbackContext.success();
	    return true;
	}
	else if("hide".equals(action)){
	    imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
	    callbackContext.success();
	    return true;
	} 
	else if ("init".equals(action)) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
            	//calculate density-independent pixels (dp)
                //http://developer.android.com/guide/practices/screens_support.html
                DisplayMetrics dm = new DisplayMetrics();
                cordova.getActivity().getWindowManager().getDefaultDisplay().getMetrics(dm);
                final float density = dm.density;

                //http://stackoverflow.com/a/4737265/1091751 detect if keyboard is showing
                final View rootView = cordova.getActivity().getWindow().getDecorView().findViewById(android.R.id.content).getRootView();
                OnGlobalLayoutListener list = new OnGlobalLayoutListener() {
                    int previousHeightDiff = 0;
                    @Override
                    public void onGlobalLayout() {
                        Rect r = new Rect();
                        //r will be populated with the coordinates of your view that area still visible.
                        rootView.getWindowVisibleDisplayFrame(r);
                        
                        PluginResult result;

                        int heightDiff = rootView.getRootView().getHeight() - r.bottom;
                        int pixelHeightDiff = (int)(heightDiff / density);
                        if (pixelHeightDiff > 100 && pixelHeightDiff != previousHeightDiff) { // if more than 100 pixels, its probably a keyboard...
                        	String msg = "S" + Integer.toString(pixelHeightDiff);
                            result = new PluginResult(PluginResult.Status.OK, msg);
                            result.setKeepCallback(true);
                            callbackContext.sendPluginResult(result);
                        }
                        else if ( pixelHeightDiff != previousHeightDiff && ( previousHeightDiff - pixelHeightDiff ) > 100 ){
                        	String msg = "H";
                            result = new PluginResult(PluginResult.Status.OK, msg);
                            result.setKeepCallback(true);
                            callbackContext.sendPluginResult(result);
                        }
                        previousHeightDiff = pixelHeightDiff;
                     }
                };

                rootView.getViewTreeObserver().addOnGlobalLayoutListener(list);
            	
            	
                PluginResult dataResult = new PluginResult(PluginResult.Status.OK);
                dataResult.setKeepCallback(true);
                callbackContext.sendPluginResult(dataResult);
            }
        });
        return true;
    }

	callbackContext.error(action + " is not a supported action");
	return false;
    }
}
