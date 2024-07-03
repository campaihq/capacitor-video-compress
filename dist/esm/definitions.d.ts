export interface CapacitorVideoCompressPlugin {
    compressVideo(options: {
        fileUri: string;
    }): Promise<{
        compressedUri: string;
    }>;
}
