var capacitorCapacitorVideoCompress = (function (exports, core) {
    'use strict';

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

    Object.defineProperty(exports, '__esModule', { value: true });

    return exports;

})({}, capacitorExports);
//# sourceMappingURL=plugin.js.map
