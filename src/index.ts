import { registerPlugin } from '@capacitor/core';

import type { CapacitorVideoCompressPlugin } from './definitions';

const CapacitorVideoCompress = registerPlugin<CapacitorVideoCompressPlugin>(
  'CapacitorVideoCompress',
  {
    web: () => import('./web').then(m => new m.CapacitorVideoCompressWeb()),
  },
);

export * from './definitions';
export { CapacitorVideoCompress };
