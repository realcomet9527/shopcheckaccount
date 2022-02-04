import {
__HMRClient as Bun
} from "http://localhost:8080/bun:wrap";
import {
__FastRefreshModule as FastHMR
} from "http://localhost:8080/bun:wrap";
import {
__FastRefreshRuntime as FastRefresh
} from "http://localhost:8080/bun:wrap";
Bun.activate(true);

var hmr = new FastHMR(583570002, "number-literal-bug.js", FastRefresh), exports = hmr.exports;
(hmr._load = function() {
  function test() {
    const precision = 10;
    try {
      parseFloat(0 .toPrecision(precision) + "1");
    } catch (exception) {
      throw new Error("Test Failed", exception);
    }
    testDone(import.meta.url);
  }
  hmr.exportAll({
    test: () => test
  });
})();
var $$hmr_test = hmr.exports.test;
hmr._update = function(exports) {
  $$hmr_test = exports.test;
};

export {
  $$hmr_test as test
};
