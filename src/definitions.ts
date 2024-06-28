export interface CapacitorVideoCompressPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
  compressVideo(options: { fileUri: string }): Promise<{ compressedUri: string }>;
}
