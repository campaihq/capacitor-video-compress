import { WebPlugin } from '@capacitor/core';
export class CapacitorVideoCompressWeb extends WebPlugin {
    async compressVideo( /* options: { fileUri: string } */) {
        throw new Error('Not supported on web.');
    }
}
//# sourceMappingURL=web.js.map