(function (global) {
  const SIZE = 640;
  const PERSON = 0;
  const SPORTS_BALL = 32;
  const CLASS_NAMES = { 0: 'person', 32: 'sports ball' };
  const CDN_MODEL =
    'https://cdn.jsdelivr.net/gh/Hyuto/yolov8-onnxruntime-web@master/public/model/yolov8n.onnx';
  const ORT_VERSION = '1.21.0';
  const WASM_PATHS =
    'https://cdn.jsdelivr.net/npm/onnxruntime-web@' + ORT_VERSION + '/dist/';

  let session = null;
  let canvas = null;
  let ctx = null;
  let objectUrl = null;

  function modelUrls() {
    const base = (document.querySelector('base') || {}).href || global.location.origin + '/';
    return [new URL('models/yolov8n.onnx', base).href, CDN_MODEL];
  }

  async function createSession(ort, url) {
    return ort.InferenceSession.create(url, { executionProviders: ['wasm'] });
  }

  async function load() {
    if (session) return;
    const ort = global.ort;
    if (!ort) throw new Error('onnxruntime-unavailable');
    ort.env.wasm.wasmPaths = WASM_PATHS;
    // Flutter web is not crossOriginIsolated; extra threads just warn and fail.
    ort.env.wasm.numThreads = 1;
    ort.env.wasm.simd = true;

    let lastError;
    const urls = modelUrls();
    for (var i = 0; i < urls.length; i++) {
      try {
        session = await createSession(ort, urls[i]);
        lastError = null;
        break;
      } catch (error) {
        lastError = error;
      }
    }
    if (!session) throw lastError || new Error('yolo-model-unavailable');
  }

  function resetCanvas() {
    canvas = document.createElement('canvas');
    ctx = canvas.getContext('2d', { willReadFrequently: true });
  }

  function isPixelSecurityError(error) {
    const message = String((error && error.message) || error || '');
    return (
      message.indexOf('tainted') >= 0 ||
      message.indexOf('SecurityError') >= 0 ||
      message.indexOf('video-pixels-blocked') >= 0
    );
  }

  function canReadVideo(video) {
    if (!video || !video.videoWidth) return false;
    try {
      const probe = document.createElement('canvas');
      probe.width = 2;
      probe.height = 2;
      const probeCtx = probe.getContext('2d', { willReadFrequently: true });
      probeCtx.drawImage(video, 0, 0, 2, 2);
      probeCtx.getImageData(0, 0, 2, 2);
      return true;
    } catch (_) {
      return false;
    }
  }

  function revokeObjectUrl() {
    if (!objectUrl) return;
    try {
      URL.revokeObjectURL(objectUrl);
    } catch (_) {}
    objectUrl = null;
  }

  async function fetchAsObjectUrl(url) {
    const res = await fetch(url, { mode: 'cors', credentials: 'omit' });
    if (!res.ok) throw new Error('fetch-failed ' + res.status);
    const blob = await res.blob();
    revokeObjectUrl();
    objectUrl = URL.createObjectURL(blob);
    return objectUrl;
  }

  function objectUrlFromBytes(bytes) {
    const view = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
    revokeObjectUrl();
    objectUrl = URL.createObjectURL(new Blob([view], { type: 'video/mp4' }));
    return objectUrl;
  }

  function preprocess(video) {
    if (!canvas || !ctx) resetCanvas();
    canvas.width = SIZE;
    canvas.height = SIZE;
    const vw = video.videoWidth;
    const vh = video.videoHeight;
    const scale = Math.min(SIZE / vw, SIZE / vh);
    const nw = vw * scale;
    const nh = vh * scale;
    const padX = (SIZE - nw) / 2;
    const padY = (SIZE - nh) / 2;
    ctx.fillStyle = 'rgb(114,114,114)';
    ctx.fillRect(0, 0, SIZE, SIZE);
    ctx.drawImage(video, padX, padY, nw, nh);
    var rgba;
    try {
      rgba = ctx.getImageData(0, 0, SIZE, SIZE).data;
    } catch (error) {
      resetCanvas();
      throw new Error('video-pixels-blocked');
    }
    const plane = SIZE * SIZE;
    const tensor = new Float32Array(3 * plane);
    for (var i = 0; i < plane; i++) {
      const o = i * 4;
      tensor[i] = rgba[o] / 255;
      tensor[plane + i] = rgba[o + 1] / 255;
      tensor[2 * plane + i] = rgba[o + 2] / 255;
    }
    return { tensor: tensor, scale: scale, padX: padX, padY: padY, srcW: vw, srcH: vh };
  }

  function asProb(score) {
    if (score < 0 || score > 1) return 1 / (1 + Math.exp(-score));
    return score;
  }

  function toVideoBox(cx, cy, w, h, meta) {
    var x = (cx - w / 2 - meta.padX) / meta.scale;
    var y = (cy - h / 2 - meta.padY) / meta.scale;
    var bw = w / meta.scale;
    var bh = h / meta.scale;
    if (x < 0) {
      bw += x;
      x = 0;
    }
    if (y < 0) {
      bh += y;
      y = 0;
    }
    if (x + bw > meta.srcW) bw = meta.srcW - x;
    if (y + bh > meta.srcH) bh = meta.srcH - y;
    return [x, y, Math.max(0, bw), Math.max(0, bh)];
  }

  function parseOutput(output, meta, minScore) {
    const dims = output.dims;
    const data = output.data;
    const boxes = [];

    if (dims.length === 3 && dims[2] === 6) {
      const num = dims[1];
      for (var i = 0; i < num; i++) {
        const o = i * 6;
        const score = asProb(data[o + 4]);
        const klass = data[o + 5];
        const name = CLASS_NAMES[klass];
        if (!name || score < minScore) continue;
        const x1 = data[o];
        const y1 = data[o + 1];
        const x2 = data[o + 2];
        const y2 = data[o + 3];
        boxes.push({
          class: name,
          score: score,
          bbox: toVideoBox((x1 + x2) / 2, (y1 + y2) / 2, x2 - x1, y2 - y1, meta),
        });
      }
      return boxes;
    }

    var numPred;
    var numAttrs;
    var at;
    if (dims.length === 3 && dims[1] < dims[2]) {
      numAttrs = dims[1];
      numPred = dims[2];
      at = function (attr, i) {
        return data[attr * numPred + i];
      };
    } else if (dims.length === 3) {
      numPred = dims[1];
      numAttrs = dims[2];
      at = function (attr, i) {
        return data[i * numAttrs + attr];
      };
    } else {
      return boxes;
    }

    const wanted = [PERSON, SPORTS_BALL];
    for (var p = 0; p < numPred; p++) {
      var best = minScore;
      var klass = -1;
      for (var c = 0; c < wanted.length; c++) {
        const id = wanted[c];
        const attr = 4 + id;
        if (attr >= numAttrs) continue;
        const score = asProb(at(attr, p));
        if (score > best) {
          best = score;
          klass = id;
        }
      }
      if (klass < 0) continue;
      boxes.push({
        class: CLASS_NAMES[klass],
        score: best,
        bbox: toVideoBox(at(0, p), at(1, p), at(2, p), at(3, p), meta),
      });
    }
    return boxes;
  }

  function iou(a, b) {
    const ax2 = a.bbox[0] + a.bbox[2];
    const ay2 = a.bbox[1] + a.bbox[3];
    const bx2 = b.bbox[0] + b.bbox[2];
    const by2 = b.bbox[1] + b.bbox[3];
    const left = Math.max(a.bbox[0], b.bbox[0]);
    const top = Math.max(a.bbox[1], b.bbox[1]);
    const right = Math.min(ax2, bx2);
    const bottom = Math.min(ay2, by2);
    const iw = right - left;
    const ih = bottom - top;
    if (iw <= 0 || ih <= 0) return 0;
    const inter = iw * ih;
    return inter / (a.bbox[2] * a.bbox[3] + b.bbox[2] * b.bbox[3] - inter);
  }

  function nms(boxes, iouThr, maxBoxes) {
    const byClass = {};
    for (var i = 0; i < boxes.length; i++) {
      const box = boxes[i];
      if (!byClass[box.class]) byClass[box.class] = [];
      byClass[box.class].push(box);
    }
    const kept = [];
    const keys = Object.keys(byClass);
    for (var k = 0; k < keys.length; k++) {
      const list = byClass[keys[k]].sort(function (a, b) {
        return b.score - a.score;
      });
      const selected = [];
      for (var j = 0; j < list.length; j++) {
        const box = list[j];
        var overlap = false;
        for (var s = 0; s < selected.length; s++) {
          if (iou(selected[s], box) >= iouThr) {
            overlap = true;
            break;
          }
        }
        if (!overlap) selected.push(box);
      }
      for (var t = 0; t < selected.length; t++) kept.push(selected[t]);
    }
    kept.sort(function (a, b) {
      return b.score - a.score;
    });
    return kept.slice(0, maxBoxes);
  }

  let ocrWorker = null;
  let ocrLoading = null;
  let lastOcrAt = 0;
  let lastJerseyBoxes = [];

  function parseJersey(text) {
    const digits = String(text || '').replace(/[^0-9]/g, '');
    if (!digits) return null;
    const clipped = digits.length > 2 ? digits.substring(0, 2) : digits;
    const n = parseInt(clipped, 10);
    if (!n || n < 1 || n > 99) return null;
    return n;
  }

  function bboxIou(a, b) {
    const ax2 = a.bbox[0] + a.bbox[2];
    const ay2 = a.bbox[1] + a.bbox[3];
    const bx2 = b.bbox[0] + b.bbox[2];
    const by2 = b.bbox[1] + b.bbox[3];
    const left = Math.max(a.bbox[0], b.bbox[0]);
    const top = Math.max(a.bbox[1], b.bbox[1]);
    const right = Math.min(ax2, bx2);
    const bottom = Math.min(ay2, by2);
    const iw = right - left;
    const ih = bottom - top;
    if (iw <= 0 || ih <= 0) return 0;
    const inter = iw * ih;
    return inter / (a.bbox[2] * a.bbox[3] + b.bbox[2] * b.bbox[3] - inter);
  }

  function carryJerseys(boxes) {
    for (var i = 0; i < boxes.length; i++) {
      const box = boxes[i];
      if (box.jerseyNumber || box.class !== 'person' || !box.bbox) continue;
      var best = 0.25;
      var number = null;
      for (var j = 0; j < lastJerseyBoxes.length; j++) {
        const prev = lastJerseyBoxes[j];
        if (!prev.jerseyNumber || !prev.bbox) continue;
        const score = bboxIou(box, prev);
        if (score > best) {
          best = score;
          number = prev.jerseyNumber;
        }
      }
      if (number) box.jerseyNumber = number;
    }
  }

  async function ensureOcr() {
    if (ocrWorker) return ocrWorker;
    if (ocrLoading) return ocrLoading;
    const Tesseract = global.Tesseract;
    if (!Tesseract || !Tesseract.createWorker) return null;
    ocrLoading = Tesseract.createWorker('eng')
      .then(function (worker) {
        return worker
          .setParameters({ tessedit_char_whitelist: '0123456789' })
          .then(function () {
            ocrWorker = worker;
            return worker;
          });
      })
      .catch(function () {
        return null;
      });
    return ocrLoading;
  }

  async function attachJerseys(video, boxes) {
    if (!canReadVideo(video)) {
      carryJerseys(boxes);
      return;
    }
    const worker = await ensureOcr();
    if (!worker) {
      carryJerseys(boxes);
      return;
    }
    const vw = video.videoWidth;
    const vh = video.videoHeight;
    const crop = document.createElement('canvas');
    crop.width = 96;
    crop.height = 96;
    const cropCtx = crop.getContext('2d', { willReadFrequently: true });
    const people = boxes
      .filter(function (box) {
        return box.class === 'person' && box.bbox && box.bbox[3] >= vh * 0.07;
      })
      .sort(function (a, b) {
        return b.bbox[3] - a.bbox[3];
      })
      .slice(0, 6);
    for (var i = 0; i < people.length; i++) {
      const box = people[i];
      const x = box.bbox[0] + box.bbox[2] * 0.22;
      const y = box.bbox[1] + box.bbox[3] * 0.16;
      const w = box.bbox[2] * 0.56;
      const h = box.bbox[3] * 0.4;
      if (w < 4 || h < 4) continue;
      try {
        cropCtx.fillStyle = '#000000';
        cropCtx.fillRect(0, 0, 96, 96);
        cropCtx.drawImage(video, x, y, w, h, 0, 0, 96, 96);
        cropCtx.getImageData(0, 0, 1, 1);
        const result = await worker.recognize(crop);
        const number = parseJersey(result && result.data && result.data.text);
        if (number) box.jerseyNumber = number;
      } catch (_) {}
    }
    carryJerseys(boxes);
    lastJerseyBoxes = boxes.filter(function (box) {
      return !!box.jerseyNumber;
    });
  }

  async function detect(video, maxBoxes, minScore) {
    if (!session) throw new Error('yolo-not-loaded');
    if (!video || !video.videoWidth) return [];
    if (!canReadVideo(video)) return [];
    try {
      const meta = preprocess(video);
      const input = new global.ort.Tensor('float32', meta.tensor, [1, 3, SIZE, SIZE]);
      const feeds = {};
      feeds[session.inputNames[0]] = input;
      const results = await session.run(feeds);
      const raw = parseOutput(results[session.outputNames[0]], meta, minScore || 0.28);
      const boxes = nms(raw, 0.4, maxBoxes || 32);
      const now = Date.now();
      if (now - lastOcrAt > 500) {
        lastOcrAt = now;
        await attachJerseys(video, boxes);
      } else {
        carryJerseys(boxes);
      }
      return boxes;
    } catch (error) {
      if (isPixelSecurityError(error)) return [];
      throw error;
    }
  }

  global.grintaYolo = {
    load: load,
    detect: detect,
    canReadVideo: canReadVideo,
    fetchAsObjectUrl: fetchAsObjectUrl,
    objectUrlFromBytes: objectUrlFromBytes,
    revokeObjectUrl: revokeObjectUrl,
  };
})(globalThis);
