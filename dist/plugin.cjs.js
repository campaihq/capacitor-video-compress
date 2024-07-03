'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var core = require('@capacitor/core');

const CapacitorVideoCompress = core.registerPlugin('CapacitorVideoCompress', {
    web: () => Promise.resolve().then(function () { return web; }).then(m => new m.CapacitorVideoCompressWeb()),
});

class CapacitorVideoCompressWeb extends core.WebPlugin {
    async compressVideo( /* options: { fileUri: string } */) {
        throw new Error('Not supported on web.');
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    CapacitorVideoCompressWeb: CapacitorVideoCompressWeb
});

exports.CapacitorVideoCompress = CapacitorVideoCompress;
//# sourceMappingURL=plugin.cjs.js.map
