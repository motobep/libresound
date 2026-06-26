var __AbortController = (function (exports) {

    class AbortSignal {
        constructor() {
            this.aborted = false;
            this.reason = '';
            this._onabort = null;
        }
        onabort() {
            if (!this._onabort) {
                this.aborted = true;
                this.reason = 'user abort (Undefined handler)';
                console.log('Undefined _onabort. Throwing');
                throw new Error('Undefined _onabort');
            }
            else {
                this._onabort();
                this.aborted = true;
                this.reason = 'user abort';
            }
        }
    }
    class AbortController {
        constructor() {
            this.signal = new AbortSignal();
        }
        abort() {
            this.signal.onabort();
        }
    }

    exports.AbortController = AbortController;
    exports.AbortSignal = AbortSignal;

    return exports;

})({});

const AbortSignal = __AbortController.AbortController
const AbortController = __AbortController.AbortSignal
