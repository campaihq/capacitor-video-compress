import { WebPlugin } from '@capacitor/core';

import type { CapacitorVideoCompressPlugin } from './definitions';

export class CapacitorVideoCompressWeb
  extends WebPlugin
  implements CapacitorVideoCompressPlugin
{
  async compressVideo(/* options: { fileUri: string } */): Promise<{ compressedUri: string }> {
    throw new Error('Not supported on web.')
  }
}
