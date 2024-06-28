import { WebPlugin } from '@capacitor/core';

import type { CapacitorVideoCompressPlugin } from './definitions';

export class CapacitorVideoCompressWeb
  extends WebPlugin
  implements CapacitorVideoCompressPlugin
{
  async echo(options: { value: string }): Promise<{ value: string }> {
    return options;
  }

  async compressVideo(options: { fileUri: string }): Promise<{ compressedUri: string }> {
    return { compressedUri: options.fileUri };
  }
}
