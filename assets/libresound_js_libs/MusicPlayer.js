var __MP_MusicPlayer = (function (exports) {

    const noOpHandler = {
        apply: (target, thisArg, args) => {
            // console.log('\n---- aplly')
            if (target.name === 'parse') {
                return args[0];
            }
            return new Proxy(() => { }, noOpHandler);
        },
        get: () => {
            // console.log('\n---- get')
            return new Proxy(() => { }, noOpHandler);
        }
    };
    const z = new Proxy({}, noOpHandler);

    var NavType;
    (function (NavType) {
        NavType["tabs"] = "tabs";
        NavType["searchTabs"] = "searchTabs";
        NavType["none"] = "none";
    })(NavType || (NavType = {}));
    var BodyType;
    (function (BodyType) {
        BodyType["items"] = "items";
        BodyType["secitons"] = "sections";
    })(BodyType || (BodyType = {}));
    var ListType;
    (function (ListType) {
        ListType["tracklist"] = "tracklist";
        ListType["grouplist"] = "grouplist";
    })(ListType || (ListType = {}));
    var IconName;
    (function (IconName) {
        IconName["plus"] = "plus";
        IconName["chevron_right"] = "chevron_right";
        IconName["clear"] = "clear";
        IconName["playlist"] = "playlist";
        IconName["trash_can"] = "trash_can";
        IconName["artist"] = "artist";
        IconName["minus"] = "minus";
        IconName["remove"] = "remove";
        IconName["download"] = "download";
        IconName["shuffle"] = "shuffle";
        IconName["house"] = "house";
        IconName["vinyl_record"] = "vinyl_record";
        IconName["pencil"] = "pencil";
        IconName["music_note"] = "music_note";
        IconName["music_notes"] = "music_notes";
        IconName["heart"] = "heart";
        IconName["thumbs_up"] = "thumbs_up";
        IconName["thumbs_down"] = "thumbs_down";
    })(IconName || (IconName = {}));
    var RightControlsType;
    (function (RightControlsType) {
        RightControlsType["search"] = "search";
    })(RightControlsType || (RightControlsType = {}));
    var PlayState;
    (function (PlayState) {
        PlayState["loading"] = "loading";
        PlayState["notReady"] = "notReady";
    })(PlayState || (PlayState = {}));
    var Extension;
    (function (Extension) {
        Extension["m4a"] = ".m4a";
        Extension["mp3"] = ".mp3";
    })(Extension || (Extension = {}));

    const sKeyValue = z.record(z.string(), z.any());
    const sNavType = z.enum(NavType);
    z.enum(BodyType);
    const sListType = z.enum(ListType);
    const sIconName = z.enum(IconName);
    const sPlayState = z.enum(PlayState);
    const sExtension = z.enum(Extension);
    const sTabs = z.array(z.object({
        text: z.string(),
        icon: z.string(),
    }));
    const sSearchTabs = z.array(z.string());
    const sItemAction = z.object({
        text: z.string(),
        icon: sIconName.optional(),
        callback: z.function({ input: [], output: z.promise(z.void()) })
    });
    const sItem = z.object({
        id: z.string(),
        title: z.string(),
        subtitle: z.string().optional(),
        thumbnailUrl: z.string().nullish(),
        props: sKeyValue.nullish(),
    });
    z.object({
        index: z.number(),
        item: sItem
    });
    const sMusicItem = sItem.extend({
        id: z.string(),
        title: z.string(),
        subtitle: z.string().nullish(),
        filepath: z.string().nullish(),
        url: z.string().nullish(),
        thumbnailUrl: z.string().nullish(),
        artist: z.object({
            id: z.string().nullish(),
            title: z.string().nullish()
        }).nullish(),
        album: z.object({
            id: z.string().nullish(),
            title: z.string().nullish()
        }).nullish(),
        duration: z.int().optional(),
        extension: sExtension,
        props: sKeyValue.nullish(),
    });
    const sGroupItem = sItem.extend({
        id: z.string(),
        title: z.string(),
        subtitle: z.string().optional(),
        thumbnailUrl: z.string().nullish(),
        props: sKeyValue.nullish(),
    });
    const sActionBtnDescr = z.object({
        text: z.string().nullish(),
        icon: sIconName.nullish(),
        callback: z.function({ input: [], output: z.promise(z.void()) })
    });
    const sPageHeaderDescr = z.object({
        title: z.string(),
        subtitle: z.string().nullish(),
        thumbnailUrl: z.string().nullish(),
        actionBtn: sActionBtnDescr.nullish()
    });
    z.object({
        id: z.string(),
        onDataReceived: z.function({ input: [z.number(), z.number()], output: z.void() })
    });
    const sSectionHeaderDescr = z.object({
        title: z.string().optional(),
        subtitle: z.string().optional(),
        actionBtn: sActionBtnDescr.nullish()
    });
    const sSectionDescr = z.object({
        listType: sListType,
        itemlist: z.union([z.array(sMusicItem), z.array(sGroupItem)]),
        rowsCount: z.number(),
        header: sSectionHeaderDescr.optional(),
        isBigTile: z.boolean().optional(),
        props: sKeyValue.optional()
    });
    const sTextInput = z.object({
        id: z.string(),
        type: z.enum(['textInput']),
        initial: z.string().nullish(),
        hintText: z.string().nullish(),
        label: z.string().optional(),
        maxWidth: z.number().nonnegative().nullish(),
        isWithCopy: z.boolean().nullish(),
        onChanged: z.function({ input: [z.string()], output: z.void() }).nullish(),
    });
    const sSelectInput = z.object({
        id: z.string(),
        type: z.enum(['selectInput']),
        initial: z.string(),
        elements: z.array(z.tuple([z.string(), z.string()])),
        onChanged: z.function({ input: [z.string()], output: z.void() }).nullish(),
    });
    const sRadioGroupInput = z.object({
        id: z.string(),
        type: z.enum(['radioGroupInput']),
        initial: z.string(),
        elements: z.array(z.tuple([z.string(), z.string()])),
        onChanged: z.function({ input: [z.string()], output: z.void() }).nullish(),
    });
    const sCheckboxInput = z.object({
        id: z.string(),
        type: z.enum(['checkboxInput', 'switchInput']),
        initial: z.boolean(),
        text: z.string().nullish(),
        onChanged: z.function({ input: [z.boolean()], output: z.void() }).nullish(),
    });
    const sButtonInput = z.object({
        id: z.string(),
        type: z.enum(['buttonInput']),
        text: z.string().nullish(),
        onTap: z.function({ input: [], output: z.void() }).nullish(),
    });
    const sInput = z.union([
        sTextInput, sSelectInput, sRadioGroupInput, sCheckboxInput, sButtonInput
    ]);
    const sText = z.object({
        type: z.enum(['text']),
        text: z.string(),
        fontSize: z.number().nonnegative().nullish(),
    });
    const sSpace = z.object({
        type: z.enum(['space']),
        height: z.number().nonnegative().nullish(),
        width: z.number().nonnegative().nullish(),
    });
    const sControl = z.union([sInput, sText, sSpace]);
    const sTabsNav = z.object({
        type: sNavType.optional(),
        tabs: z.union([sTabs, sSearchTabs]).optional(),
        index: z.number().nonnegative().optional(),
    });
    const sAttrs = z.object({
        isShowSearch: z.boolean().optional(),
        tabsNav: sTabsNav.optional(),
    });
    const sMusicPageDescr = z.object({
        type: z.enum(['music']),
        sectionlist: z.array(sSectionDescr),
        title: z.string().optional(),
        header: sPageHeaderDescr.optional(),
        actionBtn: sActionBtnDescr.nullish(),
        attrs: sAttrs.nullish(),
        props: sKeyValue.optional(),
    });
    const sMusicPageDescrUntyped = sMusicPageDescr.omit({ 'type': true });
    const sControlsPageDescr = z.object({
        type: z.enum(['controls']),
        title: z.string().optional(),
        controls: z.array(sControl),
        attrs: sAttrs.nullish(),
        props: sKeyValue.optional()
    });
    const sControlsPageDescrUntyped = sControlsPageDescr.omit({ 'type': true });
    const sWebViewPageDescr = z.object({
        type: z.enum(['webView']),
        title: z.string().optional(),
        url: z.string(),
        attrs: sAttrs.nullish(),
        props: sKeyValue.optional()
    });
    sWebViewPageDescr.omit({ 'type': true });
    const sPageDescr = z.union([sMusicPageDescr, sControlsPageDescr, sWebViewPageDescr]);

    /**
     * App's Downloader
     */
    class Downloader {
        async addAsync(id, title) {
            await PS('downloads__add', { id: id, title: title });
        }
        async updateAsync(id, title) {
            await PS('downloads__update', { id: id, title: title });
        }
        async hasAsync(id) {
            return await PS('downloads__has', { id: id });
        }
        async removeAsync(id) {
            return await PS('downloads__remove', { id: id });
        }
        async freeAsync(id) {
            return await PS('downloads__free', { id: id });
        }
    }

    function fsSend(a, b = null) {
        return __dartjs_sendMessage(`MP.runtime.fs.${a}`, JSON.stringify(b));
    }
    function PS$1(a, b = null) {
        return __dartjs_sendMessage(`PS.${a}`, JSON.stringify(b));
    }
    class Fs {
        async readFile(path, options = '') {
            return await fsSend('readFile', { 'path': path, 'options': options });
        }
        existsSync(path) {
            return fsSend('existsSync', { 'path': path });
        }
        readFileSync(path, options = '') {
            return fsSend('readFileSync', { 'path': path, 'options': options });
        }
        async readAssetAsync(path) {
            return await PS$1('readAssetAsync', { 'path': path });
        }
    }

    function MP$1(a, b = null) {
        return __dartjs_sendMessage(`MP.${a}`, JSON.stringify(b));
    }
    class Logger {
        constructor(prefix, is_mp_logger = false) {
            this._colorMap = {
                'black': '\x1B[30m',
                'red': '\x1B[31m',
                'green': '\x1B[32m',
                'yellow': '\x1B[33m',
                'blue': '\x1B[34m',
                'magenta': '\x1B[35m',
                'cyan': '\x1B[36m',
                'white': '\x1B[37m',
                'reset': '\x1B[0m',
                '': '',
            };
            this.prefix = prefix;
            this.is_mp_logger = is_mp_logger;
        }
        log(...args) {
            this.logGeneral(args, '');
        }
        green(...args) {
            this.logGeneral(args, 'green');
        }
        blue(...args) {
            this.logGeneral(args, 'blue');
        }
        warn(...args) {
            this.logGeneral(args, 'yellow');
        }
        error(...args) {
            this.logGeneral(args, 'red');
        }
        logGeneral(args, color) {
            if (this.is_mp_logger) {
                let argsStr = args.map((el) => typeof el === 'string' ? el : JSON.stringify(el))
                    .join(' ');
                let s = `${this.prefix}${argsStr}`;
                MP$1('logger.logGeneral', { s, color });
            }
            else {
                console.log(`${this._colorMap[color]}${this.prefix}`, ...args, `\x1B[0m`);
            }
        }
        debug(...args) {
            this.logGeneral(args, 'blue');
        }
    }

    // src/vlq.ts
    var comma = ",".charCodeAt(0);
    var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var intToChar = new Uint8Array(64);
    var charToInt = new Uint8Array(128);
    for (let i = 0; i < chars.length; i++) {
      const c = chars.charCodeAt(i);
      intToChar[i] = c;
      charToInt[c] = i;
    }
    function decodeInteger(reader, relative) {
      let value = 0;
      let shift = 0;
      let integer = 0;
      do {
        const c = reader.next();
        integer = charToInt[c];
        value |= (integer & 31) << shift;
        shift += 5;
      } while (integer & 32);
      const shouldNegate = value & 1;
      value >>>= 1;
      if (shouldNegate) {
        value = -2147483648 | -value;
      }
      return relative + value;
    }
    function hasMoreVlq(reader, max) {
      if (reader.pos >= max) return false;
      return reader.peek() !== comma;
    }
    var StringReader = class {
      constructor(buffer) {
        this.pos = 0;
        this.buffer = buffer;
      }
      next() {
        return this.buffer.charCodeAt(this.pos++);
      }
      peek() {
        return this.buffer.charCodeAt(this.pos);
      }
      indexOf(char) {
        const { buffer, pos } = this;
        const idx = buffer.indexOf(char, pos);
        return idx === -1 ? buffer.length : idx;
      }
    };

    // src/sourcemap-codec.ts
    function decode(mappings) {
      const { length } = mappings;
      const reader = new StringReader(mappings);
      const decoded = [];
      let genColumn = 0;
      let sourcesIndex = 0;
      let sourceLine = 0;
      let sourceColumn = 0;
      let namesIndex = 0;
      do {
        const semi = reader.indexOf(";");
        const line = [];
        let sorted = true;
        let lastCol = 0;
        genColumn = 0;
        while (reader.pos < semi) {
          let seg;
          genColumn = decodeInteger(reader, genColumn);
          if (genColumn < lastCol) sorted = false;
          lastCol = genColumn;
          if (hasMoreVlq(reader, semi)) {
            sourcesIndex = decodeInteger(reader, sourcesIndex);
            sourceLine = decodeInteger(reader, sourceLine);
            sourceColumn = decodeInteger(reader, sourceColumn);
            if (hasMoreVlq(reader, semi)) {
              namesIndex = decodeInteger(reader, namesIndex);
              seg = [genColumn, sourcesIndex, sourceLine, sourceColumn, namesIndex];
            } else {
              seg = [genColumn, sourcesIndex, sourceLine, sourceColumn];
            }
          } else {
            seg = [genColumn];
          }
          line.push(seg);
          reader.pos++;
        }
        if (!sorted) sort(line);
        decoded.push(line);
        reader.pos = semi + 1;
      } while (reader.pos <= length);
      return decoded;
    }
    function sort(line) {
      line.sort(sortComparator);
    }
    function sortComparator(a, b) {
      return a[0] - b[0];
    }

    function resolveSourceMap(str, line) {
        try {
            var mapJson = JSON.parse(str);
            const decodedMap = decode(mapJson.mappings);
            var lineObj = getOriginalLineInFile(line, decodedMap);
            if (!lineObj) {
                return null;
            }
            var file = mapJson.sources[lineObj.source];
            return {
                fileSrc: file,
                lineSrc: lineObj.line
            };
        }
        catch (err) {
            return null;
        }
    }
    function getOriginalLineInFile(line, decodedMap) {
        line -= 1;
        var segments = decodedMap[line];
        if (segments.length == 0)
            return null;
        var arr = segments[0];
        if (arr.length >= 4) {
            var [genCol, source, origLine, origCol] = arr;
            return {
                source,
                line: origLine + 1
            };
        }
        return null;
    }

    class Mapper {
        async mapStacktraceAsync(stacktrace) {
            let traces = this._getTraces(stacktrace);
            return await this._modifyTraces(traces);
        }
        async _modifyTraces(traces) {
            // console.log('_modifyTraces')
            let stacktrace = '';
            for (var el of traces) {
                if (typeof el === 'string') {
                    stacktrace += el + '\n';
                    continue;
                }
                let t = el;
                const mapPath = t.fileDst + '.map';
                const fs = new Fs();
                // console.log('existsSync')
                if (fs.existsSync(mapPath)) {
                    let pluginSourceMap;
                    if (mapPath.startsWith('assets/libresound_js_libs')) {
                        // console.log('readAssetAsync')
                        pluginSourceMap = await fs.readAssetAsync(mapPath);
                    }
                    else {
                        // console.log('readFile')
                        pluginSourceMap = fs.readFileSync(mapPath, 'utf8');
                    }
                    // console.log('resolveSourceMap')
                    let res = resolveSourceMap(pluginSourceMap, t.lineDst);
                    if (res !== null) {
                        t = { ...t, ...res };
                    }
                }
                stacktrace += this._traceToStr(t) + '\n';
            }
            // console.log('_modifyTraces return')
            return stacktrace;
        }
        _traceToStr(t) {
            let srcStr = t.fileSrc ? ` [${t.fileSrc}:${t.lineSrc}]` : '';
            return `    at ${t.at} (${t.fileDst}:${t.lineDst})${srcStr}`;
        }
        _getTraces(str) {
            var arr = str.split('\n');
            var traces = [];
            for (var s of arr) {
                var trace = s;
                var o = this._getTrace(s);
                if (o !== null) {
                    trace = o;
                }
                traces.push(trace);
            }
            return traces;
        }
        _getTrace(s) {
            const regex = /at ([\p{Letter}<>\w]*) \(([\p{Letter}<>\w/\\\.]*):(\d+)/u;
            const match = s.match(regex);
            if (match && match.length === 4) {
                return {
                    at: match[1],
                    fileDst: match[2],
                    lineDst: parseInt(match[3]),
                    col: 0,
                };
            }
            return null;
        }
    }

    class SessionStorage {
        constructor() {
            this.map = {};
        }
        get(name) {
            return this.map[name];
        }
        set(name, value) {
            this.map[name] = value;
        }
    }
    function responseToRequestCookies(responseCookies) {
        return responseCookies.map(header => {
            const parts = header.split(';');
            return parts[0];
        });
    }
    let byteStreamController;
    /**
     * A class that not only implments (imitates) parts of browser/nodejs API
     */
    class Runtime {
        constructor() {
            this.fs = new Fs();
            // bytesFetcher = new BytesFetcher()
            this.sessionStorage = new SessionStorage();
            this.byteStreamController = byteStreamController;
            this.logger = new Logger('MusicPlayer/runtime.ts: ');
            this._mapper = new Mapper();
        }
        async fetch(url, options = {}) {
            this.logger.log('fetch url:', url);
            let isRequest = url instanceof Request;
            if (isRequest) ;
            else {
                url = '' + url;
            }
            if (options.credentials === 'always' || options.credentials === 'same-origin') {
                this._addRequestCookies(options);
                this.logger.blue('headers.length', options.headers?.length);
                this.logger.blue('cookie.length', options.headers?.cookie?.length);
            }
            let resp = await MP('fetch', { 'url': url, 'options': options });
            if (options.credentials === 'always' || options.credentials === 'same-origin') {
                this._saveResponseCookies(resp.cookies);
            }
            return _makeResp(resp, options['signal']);
        }
        _addRequestCookies(options) {
            let cookieHeaderStr = this._getCookieHeaderStr();
            if (!options['headers']) {
                options['headers'] = { cookie: cookieHeaderStr };
            }
            else {
                options['headers'].cookie += '; ' + cookieHeaderStr;
            }
        }
        _getCookieHeaderStr() {
            let getCookie = this.sessionStorage.get('response-cookies');
            if (!getCookie)
                return '';
            return responseToRequestCookies(getCookie).join('; ');
        }
        // FIXME: cookies growing. Reset cookies with the same name
        _saveResponseCookies(setCookie) {
            if (setCookie) {
                let cookies = setCookie;
                let getCookie = this.sessionStorage.get('response-cookies');
                if (getCookie) {
                    cookies = [...getCookie, ...setCookie];
                }
                this.sessionStorage.set('response-cookies', cookies);
            }
        }
        async download(url, options) {
            throw new Error(`deprecated`);
        }
        // byteStreamControllerEnqueue(val: any): void {
        //     byteStreamController.enqueue(val)
        // }
        // byteStreamControllerClose(): void {
        //     byteStreamController.close()
        // }
        onDataReceived(recieved, contentLength) {
            console.log((recieved / contentLength * 100).toFixed(2) + ' %');
        }
        setProxy(env) {
            console.log('setProxyConfig', env);
            MP('setProxyConfig', env);
        }
        isTls1_3_get() {
            return MP('isTls1_3_get');
        }
        isTls1_3_set(isTls1_3) {
            console.log('isTls1_3', isTls1_3);
            MP('isTls1_3_set', isTls1_3);
        }
        async addMappingsToErrorAsync(e, code) {
            // this.logger.blue('addMappingsToErrorAsync', e);
            this.logger.blue('addMappingsToErrorAsync');
            if (typeof e === 'string') {
                this.logger.error('String error:', e);
                return e;
            }
            try {
                // this.logger.blue('mapStacktraceAsync', e, e.message, e.stack);
                this.logger.blue('mapStacktraceAsync before');
                let stack = await this._mapper.mapStacktraceAsync(e.stack);
                this.logger.blue('after mapStacktraceAsync');
                let msg = 'Error in plugin lib code (runCodeInAsyncFunc): ' + e.message;
                let s = 'Stacktrace:\n' + stack + 'Code:\n' + `${code}`;
                /*
                this.logger.error('Error in plugin lib code (runCodeInAsyncFunc):', e.message +
                  '\nStacktrace:\n' + stack,
                  'Code:\n' + `${code}`);
                */
                e.message = msg;
                e.stack = s;
            }
            catch (mappingErr) {
                this.logger.warn('Mapping Error (runCodeInAsyncFunc)', mappingErr.message);
                this.logger.error('Error in plugin code:', e.message +
                    '\nStacktrace:\n' + e.stack);
                return e;
            }
            return e;
        }
    }
    async function MP_unit8ListToString(list) {
        // console.log('unit8ListToString')
        return await MP('uint8ListToString', list);
    }
    class BytesFetcher {
        constructor(id) {
            this.id = id;
        }
        static new(onBytesRecived = null) {
            let id = MP('BytesFetcher.new', {});
            return new BytesFetcher(id);
        }
        async fetch(url, options = {}) {
            return _makeResp(await MP('BytesFetcher.fetch', { id: this.id, url, options }), options['signal']);
        }
        abort() {
            MP('BytesFetcher.abort', { id: this.id });
        }
        delete() {
            MP('BytesFetcher.delete', { id: this.id });
        }
        static async run(fn) {
            let bf = BytesFetcher.new();
            let ret = [];
            try {
                console.log(`calling fn`);
                ret = await fn(bf);
                if (!ret || ret.length === 0) {
                    console.log(`bad ret:`, ret);
                }
            }
            catch (e) {
                console.log('Error in BytesFetcher.run(): ' + e);
                throw e;
            }
            finally {
                console.log('calling abort and delete');
                bf.abort();
                bf.delete();
            }
            return ret;
        }
    }
    function MP(a, b = null) {
        // console.log(`${a}(${b})`)
        return __dartjs_sendMessage(`MP.${a}`, JSON.stringify(b));
    }
    function _makeResp(resp, signal = undefined) {
        var getBytes = resp['getBytes'];
        var getChunk = resp['getChunk'];
        var headers = resp['headers'];
        const body = new __Streams.ReadableStream({
            type: 'bytes', // NOTICE: removes first auto pull
            start(c) { byteStreamController = c; },
            cancel(reason) { console.log('stream canceled', reason); },
            async pull(controller) {
                // console.log(`Calling pull`)
                console.log(`getChunk`);
                const chunk = await getChunk();
                if (!chunk) {
                    console.log(`falsy chunk=${chunk}`);
                }
                if (chunk == null) {
                    console.log(`Runtime, chunk=${chunk}`);
                    controller.close();
                }
                else {
                    console.log(`Runtime, chunk (${chunk.byteLength}): ${chunk}`);
                    controller.enqueue(chunk);
                }
            },
        });
        var abort = resp['abort'];
        // console.log(`signal=${signal}`)
        if (signal) {
            signal._onabort = abort;
        }
        let response = {
            status: resp['status'],
            ok: resp['ok'],
            bytes: async function () {
                return await getBytes();
            },
            text: async function () {
                var bytes = await getBytes();
                return await MP_unit8ListToString(bytes);
            },
            json: async function () {
                let txt = await this.text();
                return JSON.parse(txt);
            },
            body: body,
            cookies: resp['cookies'],
            location: resp['location'],
            // headers: resp['headers'],
            headers: {
                // keys: () => keys,
                // entries: () => all,
                get: (n) => headers[n.toLowerCase()],
                has: (n) => n.toLowerCase() in headers
            },
        };
        // this.logger.log('response', response)
        return response;
    }

    class PoolsManager {
        constructor() {
            this.pools = {};
            this.logger = new Logger('🔌 PoolsManager:');
        }
        makePool(name) {
            this.logger.green('+++ makePool pool', name);
            z.string().parse(name);
            if (name in this.pools) {
                let errMsg = `Pool "${name}" already exists`;
                this.logger.error('Error in makePool():', errMsg);
                throw new Error(errMsg);
            }
            this.pools[name] = new Pool();
            return this.getPool(name);
        }
        getPool(name) {
            if (!(name in this.pools)) {
                let errMsg = `Pool "${name}" doesn't exist`;
                this.logger.error('Error in getPool():', errMsg);
                throw new Error(errMsg);
            }
            z.string().parse(name);
            return this.pools[name];
        }
        contains(name) {
            return name in this.pools;
        }
        deletePool(name) {
            this.logger.green('--- delete pool', name);
            z.string().parse(name);
            delete this.pools[name];
        }
    }
    class Pool {
        constructor() {
            this._map = {};
            this._counter = 0;
        }
        get(name) {
            z.string().parse(name);
            return this._map[name];
        }
        add(el) {
            let name = '__id_' + ++this._counter;
            this._map[name] = el;
            return name;
        }
        addWithId(id, el) {
            this._map[id] = el;
            return id;
        }
    }

    async function testAllPS(PS, isLog = false) {
        if (isLog)
            console.log('t"settings.setControlsAsync"');
        await PS('settings.setControlsAsync');
        if (isLog)
            console.log('t"getLanguageAsync"');
        await PS('getLanguageAsync');
        if (isLog)
            console.log('t"downloadMusicItemAsync"');
        await PS('downloadMusicItemAsync');
        if (isLog)
            console.log('t"toThisSourceAsync"');
        await PS('toThisSourceAsync');
        if (isLog)
            console.log('t"showActionsDialogAsync"');
        await PS('showActionsDialogAsync');
        if (isLog)
            console.log('t"closeActionsDialogAsync"');
        await PS('closeActionsDialogAsync');
        if (isLog)
            console.log('t"updateAppStateAsync"');
        await PS('updateAppStateAsync');
        if (isLog)
            console.log('t"initPageStacksAsync"');
        await PS('initPageStacksAsync');
        if (isLog)
            console.log('t"currPageStackName_getAsync"');
        await PS('currPageStackName_getAsync');
        if (isLog)
            console.log('t"currPageStackName_setAsync"');
        await PS('currPageStackName_setAsync');
        if (isLog)
            console.log('t"currTabIdx_getAsync"');
        await PS('currTabIdx_getAsync');
        if (isLog)
            console.log('t"currTabIdx_setAsync"');
        await PS('currTabIdx_setAsync');
        if (isLog)
            console.log('t"tabs_getAsync"');
        await PS('tabs_getAsync');
        if (isLog)
            console.log('t"tabs_setAsync"');
        await PS('tabs_setAsync');
        if (isLog)
            console.log('t"currSearchTabIdx_getAsync"');
        await PS('currSearchTabIdx_getAsync');
        if (isLog)
            console.log('t"currSearchTabIdx_setAsync"');
        await PS('currSearchTabIdx_setAsync');
        if (isLog)
            console.log('t"searchTabs_getAsync"');
        await PS('searchTabs_getAsync');
        if (isLog)
            console.log('t"searchTabs_setAsync"');
        await PS('searchTabs_setAsync');
        if (isLog)
            console.log('t"navType_getAsync"');
        await PS('navType_getAsync');
        if (isLog)
            console.log('t"navType_setAsync"');
        await PS('navType_setAsync');
        if (isLog)
            console.log('t"isShowPreloader_getAsync"');
        await PS('isShowPreloader_getAsync');
        if (isLog)
            console.log('t"isShowPreloader_setAsync"');
        await PS('isShowPreloader_setAsync');
        if (isLog)
            console.log('t"isShowSearch_getAsync"');
        await PS('isShowSearch_getAsync');
        if (isLog)
            console.log('t"isShowSearch_setAsync"');
        await PS('isShowSearch_setAsync');
        if (isLog)
            console.log('t"rightControls_getAsync"');
        await PS('rightControls_getAsync');
        if (isLog)
            console.log('t"rightControls_setAsync"');
        await PS('rightControls_setAsync');
        if (isLog)
            console.log('t"updateThumbnailFromUrlAsync"');
        await PS('updateThumbnailFromUrlAsync');
        if (isLog)
            console.log('t"currPageStack.length_getAsync"');
        await PS('currPageStack.length_getAsync');
        if (isLog)
            console.log('t"currPageStack.last_getAsync"');
        await PS('currPageStack.last_getAsync');
        if (isLog)
            console.log('t"currPageStack.setLast"');
        await PS('currPageStack.setLast');
        if (isLog)
            console.log('t"currPageStack.push"');
        await PS('currPageStack.push');
        if (isLog)
            console.log('t"currPageStack.pop"');
        await PS('currPageStack.pop');
        if (isLog)
            console.log('t"currPageIdAsync"');
        await PS('currPageIdAsync');
        if (isLog)
            console.log('t"currPage.typeAsync"');
        await PS('currPage.typeAsync');
        if (isLog)
            console.log('t"currMusicPage.title_getAsync"');
        await PS('currMusicPage.title_getAsync');
        if (isLog)
            console.log('t"currMusicPage.title_setAsync"');
        await PS('currMusicPage.title_setAsync');
        if (isLog)
            console.log('t"currMusicPage.sectionlist_getAsync"');
        await PS('currMusicPage.sectionlist_getAsync');
        if (isLog)
            console.log('t"currMusicPage.sectionlist_setAsync"');
        await PS('currMusicPage.sectionlist_setAsync');
        if (isLog)
            console.log('t"currMusicPage.header_getAsync"');
        await PS('currMusicPage.header_getAsync');
        if (isLog)
            console.log('t"currMusicPage.header_setAsync"');
        await PS('currMusicPage.header_setAsync');
        if (isLog)
            console.log('t"currMusicPage.acitonBtn_getAsync"');
        await PS('currMusicPage.acitonBtn_getAsync');
        if (isLog)
            console.log('t"currMusicPage.acitonBtn_setAsync"');
        await PS('currMusicPage.acitonBtn_setAsync');
        if (isLog)
            console.log('t"currMusicPage.props_getAsync"');
        await PS('currMusicPage.props_getAsync');
        if (isLog)
            console.log('t"currMusicPage.props_setAsync"');
        await PS('currMusicPage.props_setAsync');
        if (isLog)
            console.log('t"playback.playByIdx"');
        await PS('playback.playByIdx');
        if (isLog)
            console.log('t"queue.insertAllAsync"');
        await PS('queue.insertAllAsync');
        if (isLog)
            console.log('t"queue.addAllAsync"');
        await PS('queue.addAllAsync');
        if (isLog)
            console.log('t"queue.removeRangeAsync"');
        await PS('queue.removeRangeAsync');
        if (isLog)
            console.log('t"queue.clearAsync"');
        await PS('queue.clearAsync');
        if (isLog)
            console.log('t"queue.getTrackAsync"');
        await PS('queue.getTrackAsync');
        if (isLog)
            console.log('t"queue.currTrackIdx_getAsync"');
        await PS('queue.currTrackIdx_getAsync');
        if (isLog)
            console.log('t"queue.currTrackIdx_setAsync"');
        await PS('queue.currTrackIdx_setAsync');
        if (isLog)
            console.log('t"queue.lengthAsync"');
        await PS('queue.lengthAsync');
        if (isLog)
            console.log('t"propertyStorage.get"');
        await PS('propertyStorage.get');
        if (isLog)
            console.log('t"propertyStorage.set"');
        await PS('propertyStorage.set');
        if (isLog)
            console.log('t"errorManager.get"');
        await PS('errorManager.get');
        if (isLog)
            console.log('t"errorManager.set"');
        await PS('errorManager.set');
    }

    function WV(a, b = null) {
        return PS(`WebView.${a}`, b);
    }
    /**
     * WebView for some platforms (Android)
     */
    class WebView {
        constructor() {
            this.listeners = {};
            this.cookieManager = new CookieManager();
            this.logger = new Logger('🔌 WebView:');
        }
        async isSupportedAsync() {
            return await WV('isSupportedAsync');
        }
        async runJavaScriptReturningResultAsync(code) {
            return await WV('runJavaScriptReturningResultAsync', code);
        }
        async currentUrlAsync() {
            return await WV('currentUrlAsync');
        }
        async isNullAsync() {
            z.string().parse('');
            this.logger.log('isNullAsync');
            return await WV('isNullAsync');
        }
    }
    class CookieManager {
        async clearCookiesAsync() {
            await WV('cookieManager.clearCookiesAsync');
        }
        async hasCookiesAsync(_) {
            return await WV('cookieManager.hasCookiesAsync');
        }
        async getCookiesAsync(url) {
            return await WV('cookieManager.getCookiesAsync', url);
        }
        async setCookiesAsync(cookies, origin = undefined) {
            await WV('cookieManager.setCookiesAsync', { cookies, origin });
        }
    }

    function PS(a, b = null) {
        return __dartjs_sendMessage(`PS.${a}`, JSON.stringify(b));
    }
    /**
     * The class to interact with the app
     */
    class MusicPlayer {
        constructor() {
            this.runtime = new Runtime();
            this.source = new Source();
            this.playback = new Playback();
            this.queue = new Queue();
            this.downloader = new Downloader();
            this.downloadsState = new DownloadsState();
            this.propertyStorage = new PropertyStorage();
            this.helpers = new Helpers();
            this.webView = new WebView();
            this.logger = new Logger('🔌MusicPlayer: ');
            this.settings = {
                logger: new Logger('🔌settings '),
                async setControlsAsync(controls) {
                    z.array(sControl).parse(controls);
                    _checkControls(controls);
                    const controlsPool = 'controlsPool';
                    if (musicPlayer._poolManager.contains(controlsPool)) {
                        musicPlayer._poolManager.deletePool(controlsPool);
                    }
                    musicPlayer._poolManager.makePool(controlsPool);
                    _addControlsToPool(controls, controlsPool);
                    await PS('settings.setControlsAsync', controls);
                },
            };
            this._poolManager = new PoolsManager();
            this._PS = (...args) => PS(...args);
            this.testAllPS = (...args) => testAllPS(PS, ...args);
        }
        /**
         * Get currently used language
         */
        async getLanguageAsync() {
            return await PS('getLanguageAsync');
        }
        /**
         * Opens this plugin's source
         */
        async toThisSourceAsync() {
            return await PS('toThisSourceAsync');
        }
        /**
         * Shows actions dialog
         */
        async showActionsDialogAsync(actions, tapPos = null) {
            z.array(sItemAction).parse(actions);
            z.nullable(z.array(z.number()));
            this._actions = actions;
            await PS('showActionsDialogAsync', { tapPos });
        }
        /**
         * Closes actions dialog
         */
        async closeActionsDialogAsync() {
            await PS('closeActionsDialogAsync');
        }
        // TODO: USE caching
        // File? cachedFile = (await getCachedWebFile(mi.id));
        // if (cachedFile != null) {
        //   logger.log('From cache');
        //   mi.filepath = cachedFile.path;
        //   mi.downloaderType = DownloaderType.filepath;
        //   return mi;
        // }
        // TODO: make bytes example
        // var bytes = await mi.fetchBytes();
        // if (bytes.isEmpty) {
        //   throw 'logger.error downloading bytes - length == 0';
        // }
        //
        // var newFile = await writeBytesWithTagsToCache(bytes, mi);
        // // Download not aborted
        // mi.filepath = newFile.path;
        async cachedMiExistsAsync(mi) {
            return await PS('cachedMiExistsAsync', { mi });
        }
        /**
         * Returns string if errored
         * null - if not
        */
        async saveCachedMiAsync(mi) {
            return await PS('saveCachedMiAsync', { mi });
        }
        /**
         * Returns string if errored
         * null - if not
        */
        async saveMiAsync(mi, bytes) {
            return await PS('saveMiAsync', { mi, bytes });
        }
        async showSnackBarAsync(message) {
            await PS('showSnackBarAsync', { message });
        }
        async reloadFsSourceAsync() {
            await PS('reloadFsSourceAsync');
        }
        /**
         * Updates app state.
         * Use this method to update UI after changing app state.
         */
        async updateAppStateAsync() {
            await PS('updateAppStateAsync');
        }
        isMusicItem(item) {
            return 'extension' in item;
        }
    }
    /**
     * App's Source
     */
    class Source {
        constructor() {
            this.currPageStack = new CurrPageStack();
            this.currMusicPage = new CurrMusicPage();
            this.errorManager = new ErrorManager();
            this.eventListeners = {};
        }
        // NOTICE: Funcs pool for a page created/deleted automatically in dart
        async initPageStacksAsync(stacksNames) {
            z.array(z.string()).parse(stacksNames);
            await PS('initPageStacksAsync', stacksNames);
        }
        async currPageStackName_getAsync() {
            return await PS('currPageStackName_getAsync');
        }
        async currPageStackName_setAsync(value) {
            z.string().parse(value);
            await PS('currPageStackName_setAsync', value);
        }
        async currTabIdx_getAsync() {
            return await PS('currTabIdx_getAsync');
        }
        async currTabIdx_setAsync(value) {
            z.number().nonnegative().parse(value, { reportInput: true });
            await PS('currTabIdx_setAsync', value);
        }
        // returns: [[TabNameString, IconName], ...]
        async tabs_getAsync() {
            return await PS('tabs_getAsync');
        }
        // value: [[TabNameString, IconName], ...]
        async tabs_setAsync(value) {
            sTabs.parse(value, { reportInput: true });
            await PS('tabs_setAsync', value);
        }
        async currSearchTabIdx_getAsync() {
            return await PS('currSearchTabIdx_getAsync');
        }
        async currSearchTabIdx_setAsync(value) {
            z.number().nonnegative().parse(value, { reportInput: true });
            await PS('currSearchTabIdx_setAsync', value);
        }
        async searchTabs_getAsync() {
            return await PS('searchTabs_getAsync');
        }
        async searchTabs_setAsync(value) {
            sSearchTabs.parse(value, { reportInput: true });
            await PS('searchTabs_setAsync', value);
        }
        async navType_getAsync() {
            return await PS('navType_getAsync');
        }
        async navType_setAsync(value) {
            sNavType.parse(value);
            await PS('navType_setAsync', value);
        }
        async isShowPreloader_getAsync() {
            return await PS('isShowPreloader_getAsync');
        }
        async isShowPreloader_setAsync(value) {
            z.boolean().parse(value);
            await PS('isShowPreloader_setAsync', value);
        }
        async isShowSearch_getAsync() {
            return await PS('isShowSearch_getAsync');
        }
        async isShowSearch_setAsync(value) {
            z.boolean().parse(value);
            await PS('isShowSearch_setAsync', value);
        }
        async rightControls_getAsync() {
            return await PS('rightControls_getAsync');
        }
        async rightControls_setAsync(value) {
            z.array(z.string()).parse(value);
            await PS('rightControls_setAsync', value);
        }
        async updateThumbnailFromUrlAsync(id, url) {
            z.string().parse(id);
            z.string().parse(url);
            return await PS('updateThumbnailFromUrlAsync', { id: id, url: url });
        }
        /**
         * scrollEnd:
         *   args: scorllExtents: KeyValue
         */
        async addEventListenerAsync(type, listener) {
            switch (type) {
                case 'scrollEnd':
                    this.eventListeners[type] = listener;
                    await PS('source.addEventListener_scrollEnd');
                    break;
            }
        }
    }
    /**
     * Current Page Stack.
     */
    class CurrPageStack {
        async lengthAsync() {
            return await PS('currPageStack.length_getAsync');
        }
        async last_getAsync() {
            let page = await PS('currPageStack.last_getAsync');
            let currPageId = await _getCurrPageIdAsync();
            _addFuncs(currPageId, page);
            return page;
        }
        // NOTICE: Funcs pool for a page created/deleted automatically in dart
        async last_setAsync(pageDescr) {
            sPageDescr.parse(pageDescr, { reportInput: true });
            musicPlayer.logger.blue('last_setAsync');
            await CurrPageStack._onBeforePageCreate(pageDescr);
            await PS('currPageStack.last_setAsync', pageDescr);
            await CurrPageStack._onPageCreate(pageDescr);
        }
        // NOTICE: Funcs pool for a page created/deleted automatically in dart
        async pushAsync(pageDescr) {
            sPageDescr.parse(pageDescr, { reportInput: true });
            // musicPlayer.logger.log('pushAsync')
            await CurrPageStack._onBeforePageCreate(pageDescr);
            await PS('currPageStack.pushAsync', pageDescr);
            await CurrPageStack._onPageCreate(pageDescr);
        }
        static async _onBeforePageCreate(page) {
            if (page.type === 'music') {
                _addNamesToActionBtns(page);
            }
        }
        static async _onPageCreate(page) {
            let currPageId = await _getCurrPageIdAsync();
            if (await _getCurrPageTypeAsync() === 'music') {
                _addActionBtnsToPool(page, currPageId);
            }
            if (await _getCurrPageTypeAsync() === 'controls') {
                _addControlsToPool(page.controls, currPageId);
            }
            if (page.props?.funcs) {
                _saveFuncs(currPageId, page.props.funcs);
            }
        }
        // NOTICE: Funcs pool for a page created/deleted automatically in dart
        async popAsync() {
            musicPlayer.logger.blue('popAsync');
            return await PS('currPageStack.popAsync');
        }
    }
    function _addFuncs(poolId, page) {
        musicPlayer.logger.debug('_addFuncs');
        var pool = musicPlayer._poolManager.getPool(poolId);
        var funcs = pool.get('page_props_funcs');
        if (funcs) {
            page.props = { ...page.props, funcs, };
        }
    }
    function _saveFuncs(poolId, funcs) {
        musicPlayer.logger.debug('_saveFuncs');
        var pool = musicPlayer._poolManager.getPool(poolId);
        pool.addWithId('page_props_funcs', funcs);
    }
    async function _getCurrPageIdAsync() {
        return await PS('currPage.IdAsync');
    }
    async function _getCurrPageTypeAsync() {
        return await PS('currPage.typeAsync');
    }
    /**
     * Current Music Page.
     * Don't use it if current page is not a Music Page
     */
    class CurrMusicPage {
        async title_getAsync() {
            return await PS('currMusicPage.title_getAsync');
        }
        async title_setAsync(value) {
            z.string().parse(value);
            await PS('currMusicPage.title_setAsync', value);
        }
        async sectionlist_getAsync() {
            return await PS('currMusicPage.sectionlist_getAsync');
        }
        async sectionlist_setAsync(value) {
            z.array(sSectionDescr).parse(value, { reportInput: true });
            await _addActionsForCurrPageAsync(value);
            await PS('currMusicPage.sectionlist_setAsync', value);
        }
        async header_getAsync() {
            return await PS('currMusicPage.header_getAsync');
        }
        async header_setAsync(value) {
            sPageHeaderDescr.parse(value);
            await _addActionsForCurrPageAsync(value);
            await PS('currMusicPage.header_setAsync', value);
        }
        async acitonBtn_getAsync() {
            return await PS('currMusicPage.acitonBtn_getAsync');
        }
        async acitonBtn_setAsync(value) {
            sActionBtnDescr.parse(value);
            await _addActionsForCurrPageAsync(value);
            await PS('currMusicPage.acitonBtn_setAsync', value);
        }
        async attrs_getAsync() {
            return await PS('currMusicPage.attrs_getAsync');
        }
        async props_getAsync() {
            let props = await PS('currMusicPage.props_getAsync');
            let currPageId = await _getCurrPageIdAsync();
            _addFuncs(currPageId, props);
            return props;
        }
        async props_setAsync(props) {
            sKeyValue.parse(props);
            let currPageId = await _getCurrPageIdAsync();
            if (props?.funcs) {
                _saveFuncs(currPageId, props.funcs);
            }
            await PS('currMusicPage.props_setAsync', props);
        }
    }
    async function _addActionsForCurrPageAsync(value) {
        let currPageId = await _getCurrPageIdAsync();
        _addNamesToActionBtns(value);
        _addActionBtnsToPool(value, currPageId);
    }
    /**
     * App's Playback
     */
    class Playback {
        constructor() {
            this.eventListeners = {};
        }
        /**
         * Play track by [index] from Queue
         */
        async playByIdxAsync(index) {
            z.number().nonnegative().parse(index);
            await PS('playback.playByIdx', index);
        }
        async stopWithAsync(state) {
            sPlayState.parse(state);
            await PS('playback.stopWithAsync', state);
        }
        async setUrlSourceAsync(mi) {
            sMusicItem.parse(mi);
            return await PS('playback.setUrlSourceAsync', mi);
        }
        async setByteStreamSourceAsync(mi) {
            sMusicItem.parse(mi);
            return await PS('playback.setByteStreamSourceAsync', mi);
        }
        async pushBufferAsync(buffer) {
            z.array(z.number()).parse(buffer);
            return await PS('playback.pushBufferAsync', buffer);
        }
        async flushBuffersAsync() {
            return await PS('playback.flushBuffersAsync', {});
        }
        async setPositionAsync(milliseconds) {
            z.int().nonnegative().parse(milliseconds);
            return await PS('playback.setPositionAsync', { milliseconds });
        }
        async addEventListenerAsync(type, listener) {
            switch (type) {
                case 'counterUpdate':
                    this.eventListeners[type] = listener;
                    await PS('playback.addEventListener_counterUpdate');
                    break;
            }
        }
    }
    /**
     * App's Queue
     */
    class Queue {
        constructor() {
            /**
             * Queue's helpers
             */
            this.helpers = {
                /**
                 * Inserts [MusicItem] after current track
                 */
                playNextAsync: async (mis) => {
                    z.array(sMusicItem, { error: () => `Validation failure for: \n${JSON.stringify(mis, null, 2)}\n` }).parse(mis, {
                        reportInput: true
                    });
                    let idx = (await this.currTrackIdx_getAsync()) + 1;
                    if (idx >= await this.lengthAsync()) {
                        await this.addAllAsync(mis);
                    }
                    else {
                        await this.insertAllAsync(idx, mis);
                    }
                },
            };
            this.eventListeners = {};
        }
        /**
         * Inserts [list] at [index] in the queue
         */
        async insertAllAsync(index, list) {
            z.number().nonnegative().parse(index);
            z.array(sMusicItem).parse(list);
            await PS('queue.insertAllAsync', { index: index, list: list });
        }
        /**
         * Adds [list] at the end of the queue
         */
        async addAllAsync(list) {
            z.array(sMusicItem).parse(list, {
                reportInput: true
            });
            await PS('queue.addAllAsync', list);
        }
        /**
         * Removes a range of elements from the queue.
         * Removes the elements with positions greater than or equal to [start]
         * and less than [end], from the queue.
        */
        async removeRangeAsync(start, end) {
            z.number().nonnegative().parse(start);
            z.number().nonnegative().parse(end);
            await PS('queue.removeRangeAsync', { start: start, end: end });
        }
        /**
         * Removes items before and after the current track.
         * Only this track will remain
         */
        async clearAsync() {
            await PS('queue.clearAsync');
        }
        /**
         * Returns [MusicItem] by [index] from the queue
         */
        async getTrackAsync(index) {
            z.number().nonnegative().parse(index);
            return await PS('queue.getTrackAsync', index);
        }
        /**
         * Sets [MusicItem] at [index] in the queue
         */
        async setTrackAsync(index, mi) {
            z.number().nonnegative().parse(index);
            await PS('queue.setTrackAsync', { index, mi });
        }
        /**
         * Index of current track
         */
        async currTrackIdx_getAsync() {
            return await PS('queue.currTrackIdx_getAsync');
        }
        /**
         * Set index of current track
         */
        async currTrackIdx_setAsync(value) {
            z.number().nonnegative().parse(value);
            await PS('queue.currTrackIdx_setAsync', value);
        }
        /**
         * Queue's length
         */
        async lengthAsync() {
            return await PS('queue.lengthAsync');
        }
        async canAutoplayAsync() {
            return await PS('queue.canAutoplayAsync');
        }
        async setAutoplayAsync(b) {
            await PS('queue.setAutoplayAsync', b);
        }
        /**
         * musicItemChange:
         *   args: index - index of current track in queue, -1 if no item
         */
        async addEventListenerAsync(type, listener) {
            switch (type) {
                case 'musicItemChange':
                    this.eventListeners[type] = listener;
                    await PS('queue.addEventListener_musicItemChange');
                    break;
            }
        }
    }
    class DownloadsState {
        constructor() {
            this._counter = 0;
        }
        async download(obj) {
            let { downloadType, mi, fetch, abort } = obj;
            let poolName = `DownloadState_(${this._counter})`;
            let pool = musicPlayer._poolManager.makePool(poolName);
            pool.addWithId('fetch', fetch);
            pool.addWithId('abort', abort);
            let val = [];
            try {
                console.log(`calling PS register`);
                val = await PS('DownloadsState.download', { downloadType, id: mi.id, text: mi.title, poolName });
                if (!val || val.length === 0) {
                    console.log(`bad val:`, val);
                }
            }
            catch (e) {
                musicPlayer.logger.error('Error in DownloadsState.download(): ' + e);
                throw e;
            }
            finally {
                musicPlayer._poolManager.deletePool(poolName);
            }
            return val;
        }
        async removeAndAbortByTypeAsync(type) {
            await PS('DownloadsState.removeAndAbortByTypeAsync', { type });
        }
        /**
         * Guard function to safely download.
         * The function adds loading indicator, and removes it on end or failure
         *
         * Use `guardMusicItemLoadingAsync` for preparing MusicItem
         */
        async guardDownloadAsync(mi, fn) {
            return await this.guardLoadAsync('download', mi, fn);
        }
        /**
         * Guard function to safely prepare MusicItem while makeing fetch().
         * The function adds loading indicator, and removes it on end or failure.
         * Also it handles PlayState
         *
         * Use `guardDownloadAsync` for downloading files
         */
        async guardMusicItemLoadingAsync(mi, fn) {
            await this.removeAndAbortByTypeAsync('play');
            await musicPlayer.playback.stopWithAsync(PlayState.loading);
            try {
                return await this.guardLoadAsync('play', mi, fn);
            }
            catch (e) {
                musicPlayer.logger.warn('Exception downloading mi: ' + e);
                // if (playState == PlayState.loading) { // Should check?
                await musicPlayer.playback.stopWithAsync(PlayState.notReady);
                // }
                throw e;
            }
        }
        /**
         * The function adds loading indicator, and removes it on end or failure
         */
        async guardLoadAsync(downloadType, mi, fn) {
            return await BytesFetcher.run(async (bf) => {
                return await this.download({
                    downloadType,
                    mi,
                    abort: () => { bf.abort(); },
                    fetch: async () => await fn(bf)
                });
            });
        }
    }
    /**
     * Store and access any data as json in long-term memory
     */
    class PropertyStorage {
        async getAsync(name) {
            z.string().parse(name);
            return await PS('propertyStorage.getAsync', name);
        }
        async setAsync(name, value) {
            z.string().parse(name);
            await PS('propertyStorage.setAsync', { 'name': name, 'value': value });
        }
    }
    class ErrorManager {
        /**
         * Get current error message
         */
        async getAsync() {
            return await PS('errorManager.getAsync');
        }
        /**
         * Set error message that will be show instead of content.
         * Use empty string to clean error message
         */
        async setAsync(err) {
            z.string(err);
            await PS('errorManager.setAsync', err);
        }
    }
    class Helpers {
        MusicPage(obj) {
            sMusicPageDescrUntyped.parse(obj);
            return Object.assign({ type: 'music' }, obj);
        }
        ControlsPage(obj) {
            sControlsPageDescrUntyped.parse(obj);
            return Object.assign({ type: 'controls' }, obj);
        }
        makeTracklist(itemlist) {
            z.array(sItem).parse(itemlist);
            return {
                listType: 'tracklist',
                itemlist: itemlist,
                rowsCount: -1,
            };
        }
        makeGrouplist(itemlist) {
            z.array(sItem).parse(itemlist);
            return {
                listType: 'grouplist',
                itemlist: itemlist,
                rowsCount: -1,
            };
        }
        defaultDownloadProps(downloadId, name) {
            z.string().parse(downloadId);
            z.string().parse(name);
            return {
                id: downloadId,
                onDataReceived: (recieved, contentLength) => {
                    z.number().nonnegative().parse(recieved);
                    z.number().nonnegative().parse(contentLength);
                    musicPlayer.downloader.updateAsync(downloadId, `[${(recieved / contentLength * 100).toFixed(2)} %.]. Downloading "${name}"`);
                }
            };
        }
        async setAttrsAsync(attrs) {
            if (!attrs) {
                musicPlayer.logger.error('nullish attrs:', attrs);
                return;
            }
            sAttrs.parse(attrs, { reportInput: true });
            await PS('helpers.setAttrsAsync', attrs);
        }
        preloader(originalMethod, _context) {
            async function replacementMethod(...args) {
                await Helpers._setPreloaderAsync(true);
                let res;
                let err;
                try {
                    res = await originalMethod.call(this, ...args);
                }
                catch (e) {
                    err = e;
                }
                await Helpers._setPreloaderAsync(false);
                if (err) {
                    throw err;
                }
                return res;
            }
            return replacementMethod;
        }
        static async _setPreloaderAsync(value) {
            await musicPlayer.source.isShowPreloader_setAsync(value);
            await musicPlayer.updateAppStateAsync();
        }
        loading(originalMethod, _context) {
            async function replacementMethod(...args) {
                await musicPlayer.playback.stopWithAsync(PlayState.loading);
                let res;
                try {
                    res = await originalMethod.call(this, ...args);
                }
                catch (e) {
                    await musicPlayer.playback.stopWithAsync(PlayState.notReady);
                    throw e;
                }
                return res;
            }
            return replacementMethod;
        }
    }
    const musicPlayer = new MusicPlayer();
    function _checkControls(controls) {
        let ids = [];
        for (let el of controls) {
            if (!('id' in el))
                continue;
            if (ids.includes(el.id)) {
                musicPlayer.logger.error(`Duplicate id for:`, el);
                throw Error(`Duplicate id: ${el.id}`);
            }
            ids.push(el.id);
        }
    }
    function _addControlsToPool(controls, poolName) {
        musicPlayer.logger.blue('_addControlsToPool');
        var pool = musicPlayer._poolManager.getPool(poolName);
        for (let el of controls) {
            if ('onChanged' in el) {
                pool.addWithId(el.id, el.onChanged);
            }
            if ('onTap' in el) {
                pool.addWithId(el.id, el.onTap);
            }
        }
    }
    function _addNamesToActionBtns(obj) {
        // musicPlayer.logger.log('_addNamesToActionBtns')
        let namedFuncs = _findPropertyPathsWithValues(obj, 'actionBtn');
        for (let el of namedFuncs) {
            let actionBtn = el.value;
            if (!actionBtn) {
                musicPlayer.logger.log(`Property '${el.path}' is nullish`);
                continue;
            }
            if (typeof actionBtn.callback !== "function") {
                musicPlayer.logger.warn(`Property '${el.path}' not function`);
                continue;
            }
            // musicPlayer.logger.blue(`_callbackName '${el.path}' set`)
            actionBtn._callbackName = el.path;
        }
    }
    function _addActionBtnsToPool(obj, poolName) {
        // musicPlayer.logger.log('_addActionBtnsToPool for poolName', poolName)
        var pool = musicPlayer._poolManager.getPool(poolName);
        let namedFuncs = _findPropertyPathsWithValues(obj, 'actionBtn');
        for (let el of namedFuncs) {
            let actionBtn = el.value;
            if (!actionBtn) {
                musicPlayer.logger.log(`Property '${el.path}' is nullish`);
                continue;
            }
            if (typeof actionBtn.callback !== "function") {
                musicPlayer.logger.warn(`Property '${el.path}' not function`);
                continue;
            }
            // musicPlayer.logger.blue(`Property '${el.path}' set [${typeof actionBtn.callback}]`)
            pool.addWithId(el.path, actionBtn.callback);
        }
    }
    function _findPropertyPathsWithValues(obj, targetKey, currentPath = '') {
        if (obj === null || typeof obj !== 'object') {
            return [];
        }
        let pathsAndValues = [];
        for (let key in obj) {
            const path = currentPath ? `${currentPath}.${key}` : key;
            if (key === targetKey) {
                pathsAndValues.push({ path, value: obj[key] });
            }
            // If the value is an array, iterate through its elements
            if (Array.isArray(obj[key])) {
                obj[key].forEach((item, index) => {
                    const arrayPath = `${path}[${index}]`;
                    pathsAndValues = pathsAndValues.concat(_findPropertyPathsWithValues(item, targetKey, arrayPath));
                });
            }
            else {
                pathsAndValues = pathsAndValues.concat(_findPropertyPathsWithValues(obj[key], targetKey, path));
            }
        }
        return pathsAndValues;
    }

    exports.CurrMusicPage = CurrMusicPage;
    exports.CurrPageStack = CurrPageStack;
    exports.DownloadsState = DownloadsState;
    exports.ErrorManager = ErrorManager;
    exports.Helpers = Helpers;
    exports.MusicPlayer = MusicPlayer;
    exports.PS = PS;
    exports.Playback = Playback;
    exports.PropertyStorage = PropertyStorage;
    exports.Queue = Queue;
    exports.Source = Source;
    exports.musicPlayer = musicPlayer;

    return exports;

})({});

const musicPlayer = __MP_MusicPlayer.musicPlayer
var fetch = (...args) => {
    return musicPlayer.runtime.fetch(...args)
}
//# sourceMappingURL=MusicPlayer.js.map
