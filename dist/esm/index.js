import { registerPlugin } from '@capacitor/core';
const CapacitorVideoCompress = registerPlugin('CapacitorVideoCompress', {
    web: () => import('./web').then(m => new m.CapacitorVideoCompressWeb()),
});
export * from './definitions';
export { CapacitorVideoCompress };
//# sourceMappingURL=index.js.map