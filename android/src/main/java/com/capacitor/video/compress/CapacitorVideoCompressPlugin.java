package com.capacitor.video.compress;

import android.content.ContentResolver;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.abedelazizshe.lightcompressorlibrary.CompressionListener;
import com.abedelazizshe.lightcompressorlibrary.VideoCompressor;
import com.abedelazizshe.lightcompressorlibrary.VideoQuality;
import com.abedelazizshe.lightcompressorlibrary.config.AppSpecificStorageConfiguration;
import com.abedelazizshe.lightcompressorlibrary.config.Configuration;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.File;
import java.util.ArrayList;
import java.util.concurrent.CompletableFuture;

@CapacitorPlugin(name = "CapacitorVideoCompress")
public class CapacitorVideoCompressPlugin extends Plugin {

    private CapacitorVideoCompress implementation = new CapacitorVideoCompress();

    @PluginMethod
    public void compressVideo(PluginCall call) {
        String fileUri = call.getString("fileUri");

        String fileName = "compressed-video";
        Uri videoUri = Uri.parse(fileUri);

        // Get original video file size and bitrate (store for summary at the end)
        final long originalSize = getFileSize(videoUri);
        final int originalBitrate = getVideoBitrate(videoUri);

        // Fixed target bitrate
        final int targetBitrateMbps = 2;

        // Check if compression should be skipped
        // Skip if: original bitrate is lower than target OR within 10% of target (less than 2.2 Mbps)
        if (originalBitrate > 0) {
            double originalBitrateMbps = originalBitrate / 1000000.0;
            double maxSkipBitrate = targetBitrateMbps * 1.1;

            if (originalBitrateMbps < maxSkipBitrate) {
                Log.i(
                    "compressVideo",
                    "Skipping compression: Original bitrate (" +
                    String.format("%.2f", originalBitrateMbps) +
                    " Mbps) is lower than or within 10% of target (" +
                    targetBitrateMbps +
                    " Mbps)"
                );

                // Skips compression and returns empty string
                JSObject ret = new JSObject();
                ret.put("compressedUri", "");
                call.resolve(ret);
                return;
            } else {
                Log.i(
                    "compressVideo",
                    "Original bitrate: " +
                    String.format("%.2f", originalBitrateMbps) +
                    " Mbps, Target: " +
                    targetBitrateMbps +
                    " Mbps - Compression will proceed"
                );
            }
        } else {
            Log.i("compressVideo", "Original bitrate unavailable, proceeding with compression");
        }

        ArrayList<Uri> filesToCompress = new ArrayList<>() {
            {
                add(videoUri);
            }
        };

        ArrayList<String> fileNames = new ArrayList<>() {
            {
                add(fileName);
            }
        };

        // Track last logged percentage to avoid logging multiple times for the same integer percentage
        final int[] lastLoggedPercentage = { -1 };

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
                targetBitrateMbps, // videoBitrateInMbps - adaptive based on original
                false, // disableAudio
                false, // keepOriginalResolution
                null, //480.0, // height
                null, //848.0, // width
                fileNames
            ),
            new CompressionListener() {
                @Override
                public void onSuccess(int i, long l, @Nullable String compressedFilePath) {
                    // Get compressed video file size and bitrate
                    long compressedSize = 0;
                    int compressedBitrate = 0;
                    if (compressedFilePath != null) {
                        File compressedFile = new File(compressedFilePath);
                        if (compressedFile.exists()) {
                            compressedSize = compressedFile.length();
                            compressedBitrate = getVideoBitrateFromPath(compressedFilePath);
                        }
                    }

                    // Log comprehensive summary at the end
                    Log.i("compressVideo", "========================================");
                    Log.i("compressVideo", "Video Compression Summary");
                    Log.i("compressVideo", "========================================");
                    Log.i("compressVideo", "Original size: " + formatFileSize(originalSize) + " (" + originalSize + " bytes)");
                    if (originalBitrate > 0) {
                        Log.i("compressVideo", "Original bitrate: " + formatBitrate(originalBitrate) + " (" + originalBitrate + " bps)");
                    }
                    Log.i("compressVideo", "Target bitrate: " + targetBitrateMbps + " Mbps");
                    Log.i("compressVideo", "----------------------------------------");
                    Log.i("compressVideo", "Compressed size: " + formatFileSize(compressedSize) + " (" + compressedSize + " bytes)");
                    if (compressedBitrate > 0) {
                        Log.i(
                            "compressVideo",
                            "Compressed bitrate: " + formatBitrate(compressedBitrate) + " (" + compressedBitrate + " bps)"
                        );
                    }
                    Log.i("compressVideo", "----------------------------------------");
                    if (originalSize > 0 && compressedSize > 0) {
                        double compressionRatio = ((double) (originalSize - compressedSize) / originalSize) * 100;
                        Log.i(
                            "compressVideo",
                            "Size reduction: " +
                            formatFileSize(originalSize - compressedSize) +
                            " (" +
                            String.format("%.2f", compressionRatio) +
                            "%)"
                        );
                    }
                    if (originalBitrate > 0 && compressedBitrate > 0) {
                        double bitrateReduction = ((double) (originalBitrate - compressedBitrate) / originalBitrate) * 100;
                        Log.i(
                            "compressVideo",
                            "Bitrate reduction: " +
                            formatBitrate(originalBitrate - compressedBitrate) +
                            " (" +
                            String.format("%.2f", bitrateReduction) +
                            "%)"
                        );
                    }
                    Log.i("compressVideo", "----------------------------------------");
                    Log.i("compressVideo", "Output path: " + compressedFilePath);
                    Log.i("compressVideo", "========================================");

                    future.complete(compressedFilePath);
                }

                @Override
                public void onStart(int i) {
                    Log.i("compressVideo", "Video compression started");
                }

                @Override
                public void onProgress(int i, float progress) {
                    // Only log when we move to a new integer percentage
                    int currentPercentage = (int) progress;
                    if (currentPercentage != lastLoggedPercentage[0]) {
                        lastLoggedPercentage[0] = currentPercentage;
                        Log.i("compressVideo", "Video compress progress (" + currentPercentage + "%)");
                    }
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

        future
            .thenAccept(
                outputPath -> {
                    JSObject ret = new JSObject();
                    ret.put("compressedUri", outputPath);
                    call.resolve(ret);
                }
            )
            .exceptionally(
                throwable -> {
                    call.reject("Video compression failed");
                    return null;
                }
            );
    }

    /**
     * Get file size from Uri
     */
    private long getFileSize(Uri uri) {
        try {
            ContentResolver contentResolver = getContext().getContentResolver();
            android.database.Cursor cursor = contentResolver.query(uri, null, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                int sizeIndex = cursor.getColumnIndex(android.provider.OpenableColumns.SIZE);
                if (sizeIndex != -1) {
                    long size = cursor.getLong(sizeIndex);
                    cursor.close();
                    return size;
                }
                cursor.close();
            }

            // Fallback: try to get file from path
            String path = uri.getPath();
            if (path != null) {
                File file = new File(path);
                if (file.exists()) {
                    return file.length();
                }
            }
        } catch (Exception e) {
            Log.e("compressVideo", "Error getting file size: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Format file size to human-readable format
     */
    private String formatFileSize(long size) {
        if (size < 1024) {
            return size + " B";
        } else if (size < 1024 * 1024) {
            return String.format("%.2f KB", size / 1024.0);
        } else if (size < 1024 * 1024 * 1024) {
            return String.format("%.2f MB", size / (1024.0 * 1024.0));
        } else {
            return String.format("%.2f GB", size / (1024.0 * 1024.0 * 1024.0));
        }
    }

    /**
     * Get video bitrate from Uri
     */
    private int getVideoBitrate(Uri uri) {
        MediaMetadataRetriever retriever = null;
        try {
            retriever = new MediaMetadataRetriever();
            retriever.setDataSource(getContext(), uri);

            String bitrateString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE);
            if (bitrateString != null) {
                return Integer.parseInt(bitrateString);
            }
        } catch (Exception e) {
            Log.e("compressVideo", "Error getting video bitrate from Uri: " + e.getMessage());
        } finally {
            if (retriever != null) {
                try {
                    retriever.release();
                } catch (Exception e) {
                    Log.e("compressVideo", "Error releasing MediaMetadataRetriever: " + e.getMessage());
                }
            }
        }
        return 0;
    }

    /**
     * Get video bitrate from file path
     */
    private int getVideoBitrateFromPath(String filePath) {
        MediaMetadataRetriever retriever = null;
        try {
            retriever = new MediaMetadataRetriever();
            retriever.setDataSource(filePath);

            String bitrateString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE);
            if (bitrateString != null) {
                return Integer.parseInt(bitrateString);
            }
        } catch (Exception e) {
            Log.e("compressVideo", "Error getting video bitrate from path: " + e.getMessage());
        } finally {
            if (retriever != null) {
                try {
                    retriever.release();
                } catch (Exception e) {
                    Log.e("compressVideo", "Error releasing MediaMetadataRetriever: " + e.getMessage());
                }
            }
        }
        return 0;
    }

    /**
     * Format bitrate to human-readable format
     */
    private String formatBitrate(int bitrate) {
        if (bitrate < 1000) {
            return bitrate + " bps";
        } else if (bitrate < 1000000) {
            return String.format("%.2f Kbps", bitrate / 1000.0);
        } else {
            return String.format("%.2f Mbps", bitrate / 1000000.0);
        }
    }
}
