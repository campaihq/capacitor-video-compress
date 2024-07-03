import { WebPlugin } from '@capacitor/core';
import type { CapacitorVideoCompressPlugin } from './definitions';
export declare class CapacitorVideoCompressWeb extends WebPlugin implements CapacitorVideoCompressPlugin {
    compressVideo(): Promise<{
        compressedUri: string;
    }>;
}
