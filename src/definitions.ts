export interface CapacitorVideoCompressPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
