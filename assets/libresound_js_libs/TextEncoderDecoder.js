var __TextEncoderDecoder = (function (exports) {

	var commonjsGlobal = typeof globalThis !== 'undefined' ? globalThis : typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};

	var textEncodingShim$1 = {exports: {}};

	var textEncodingShim = textEncodingShim$1.exports;

	var hasRequiredTextEncodingShim;

	function requireTextEncodingShim () {
		if (hasRequiredTextEncodingShim) return textEncodingShim$1.exports;
		hasRequiredTextEncodingShim = 1;
		(function (module, exports) {
			(function (root, factory) {
			    {
			        module.exports = factory();
			    }
			}(textEncodingShim, function () {
				// return native implementation if available
				var g = typeof commonjsGlobal !== 'undefined' ? commonjsGlobal : self;
				if (typeof g.TextEncoder !== 'undefined' && typeof g.TextDecoder !== 'undefined') {
					return {'TextEncoder': g.TextEncoder, 'TextDecoder': g.TextDecoder};
				}

				// allowed encoding strings for utf-8
				var utf8Encodings = [
					'utf8',
					'utf-8',
					'unicode-1-1-utf-8'
				];

				var TextEncoder = function(encoding) {
					if (utf8Encodings.indexOf(encoding) < 0 && typeof encoding !== 'undefined' && encoding !== null) {
						throw new RangeError('Invalid encoding type. Only utf-8 is supported');
					} else {
						this.encoding = 'utf-8';
						this.encode = function(str) {
							if (typeof str !== 'string') {
								throw new TypeError('passed argument must be of type string');
							}
							var binstr = unescape(encodeURIComponent(str)),
								arr = new Uint8Array(binstr.length);
							binstr.split('').forEach(function(char, i) {
								arr[i] = char.charCodeAt(0);
							});
							return arr;
						};
					}
				};

				var TextDecoder = function(encoding, options) {
					if (utf8Encodings.indexOf(encoding) < 0 && typeof encoding !== 'undefined' && encoding !== null) {
						throw new RangeError('Invalid encoding type. Only utf-8 is supported');
					}
					this.encoding = 'utf-8';
					this.ignoreBOM = false;
					this.fatal = (typeof options !== 'undefined' && 'fatal' in options) ? options.fatal : false;
					if (typeof this.fatal !== 'boolean') {
						throw new TypeError('fatal flag must be boolean');
					}
					this.decode = function (view, options) {
						if (typeof view === 'undefined') {
							return '';
						}

						var stream = (typeof options !== 'undefined' && 'stream' in options) ? options.stream : false;
						if (typeof stream !== 'boolean') {
							throw new TypeError('stream option must be boolean');
						}

						if (!ArrayBuffer.isView(view)) {
							throw new TypeError('passed argument must be an array buffer view');
						} else {
							var arr = new Uint8Array(view.buffer, view.byteOffset, view.byteLength),
								charArr = new Array(arr.length);
							arr.forEach(function(charcode, i) {
								charArr[i] = String.fromCharCode(charcode);
							});
							return decodeURIComponent(escape(charArr.join('')));
						}
					};
				};
				return {'TextEncoder': TextEncoder, 'TextDecoder': TextDecoder};
			})); 
		} (textEncodingShim$1));
		return textEncodingShim$1.exports;
	}

	var textEncodingShimExports = requireTextEncodingShim();

	exports.TextDecoder = textEncodingShimExports.TextDecoder;
	exports.TextEncoder = textEncodingShimExports.TextEncoder;

	return exports;

})({});

const TextEncoder = __TextEncoderDecoder.TextEncoder
const TextDecoder = __TextEncoderDecoder.TextDecoder
if (typeof globalThis !== 'undefined' ) {
    globalThis.TextEncoder = __TextEncoderDecoder.TextEncoder
    globalThis.TextDecoder = __TextEncoderDecoder.TextDecoder
} else {
    var globalThis = {
        TextEncoder: __TextEncoderDecoder.TextEncoder,
        TextDecoder: __TextEncoderDecoder.TextDecoder,
    }
}

const btoa = (data) => {
    return __dartjs_sendMessage('btoa', JSON.stringify(data));
}
const atob = (data) => {
    return __dartjs_sendMessage('atob', JSON.stringify(data));
}

class Intl {
    static DateTimeFormat() {
        return {
            resolvedOptions() {
                var timeZone = 'Europe/Moscow'
                return {
                    timeZone
                }
            }
        }
    }
}

