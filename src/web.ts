import { WebPlugin } from '@capacitor/core';

import type { CapacitorVideoCompressPlugin } from './definitions';

export class CapacitorVideoCompressWeb
  extends WebPlugin
  implements CapacitorVideoCompressPlugin
{
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
