package com.capacitor.video.compress;

import com.abedelazizshe.lightcompressorlibrary.VideoCompressor;
import com.abedelazizshe.lightcompressorlibrary.VideoQuality;
import com.abedelazizshe.lightcompressorlibrary.config.AppSpecificStorageConfiguration;
import com.abedelazizshe.lightcompressorlibrary.config.Configuration;
import com.abedelazizshe.lightcompressorlibrary.CompressionListener;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import android.net.Uri;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.concurrent.CompletableFuture;

@CapacitorPlugin(name = "CapacitorVideoCompress")
public class CapacitorVideoCompressPlugin extends Plugin {

    private CapacitorVideoCompress implementation = new CapacitorVideoCompress();

    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value");

        JSObject ret = new JSObject();
        ret.put("value", implementation.echo(value));
        call.resolve(ret);
    }

    @PluginMethod
    public void compressVideo(PluginCall call) {
        String fileUri = call.getString("fileUri");

        String fileName = "compressed-video";
        Uri videoUri = Uri.parse(fileUri);

        ArrayList<Uri> filesToCompress = new ArrayList<>() {{
            add(videoUri);
        }};

        ArrayList<String> fileNames = new ArrayList<>() {{
            add(fileName);
        }};

        CompletableFuture<String> future = new CompletableFuture<>();
        VideoCompressor.start(
                getContext(),
                filesToCompress,
                false,
                null, // new SharedStorageConfiguration(null, null),
                new AppSpecificStorageConfiguration(null),
                new Configuration(
                        VideoQuality.MEDIUM, // quality
                        false, // isMinBitrateCheckEnabled
                        2, // videoBitrateInMbps
                        false, // disableAudio
                        false, // keepOriginalResolution
                        null, //480.0, // height
                        null, //848.0, // width
                        fileNames
                ),
                new CompressionListener() {
                    @Override
                    public void onSuccess(int i, long l, @Nullable String compressedFilePath) {
                        Log.i("compressVideo", "Video was compressed successfully and stored at " + compressedFilePath);
                        future.complete(compressedFilePath);
                    }

                    @Override
                    public void onStart(int i) {
                        Log.i("compressVideo", "Video compression started");
                    }

                    @Override
                    public void onProgress(int i, float progress) {
                        Log.i("compressVideo", "Video compress progress (" + progress + "%)");
                    }

                    @Override
                    public void onFailure(int i, @NonNull String s) {
                        Log.i("compressVideo", "Video compression failed: " + s);
                        future.completeExceptionally(new Exception("Failed to compress video: " + s));
                    }

                    @Override
                    public void onCancelled(int i) {
                        Log.i("compressVideo", "Video compression canceled");
                        future.completeExceptionally(new Exception("Video compression canceled"));
                    }
                }
        );

        future.thenAccept(outputPath -> {
            JSObject ret = new JSObject();
            ret.put("compressedUri", outputPath);
            call.resolve(ret);
        }).exceptionally(throwable -> {
            call.reject("Video compression failed");
            return null;
        });
    }
}
