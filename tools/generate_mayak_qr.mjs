import { mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const objectToken = process.argv[2]?.trim() || 'mayak';
const payload = objectToken.includes('://')
  ? objectToken
  : `retroar://object/${objectToken}`;
const objectSlug = payload.split('/').pop()?.replace(/[^a-z0-9_-]/gi, '_') || 'object';
const outputBaseName = process.argv[3]?.trim() || `${objectSlug}_test_qr`;
const version = 2;
const size = 17 + version * 4;
const dataCodewords = 34;
const eccCodewords = 10;
const outputDir = resolve('qr');

function appendBits(bits, value, length) {
  for (let i = length - 1; i >= 0; i -= 1) {
    bits.push((value >>> i) & 1);
  }
}

function buildDataCodewords(text) {
  const bytes = [...Buffer.from(text, 'utf8')];
  const bits = [];

  appendBits(bits, 0b0100, 4);
  appendBits(bits, bytes.length, 8);

  for (const byte of bytes) {
    appendBits(bits, byte, 8);
  }

  const capacityBits = dataCodewords * 8;
  appendBits(bits, 0, Math.min(4, capacityBits - bits.length));

  while (bits.length % 8 !== 0) {
    bits.push(0);
  }

  const codewords = [];
  for (let i = 0; i < bits.length; i += 8) {
    let byte = 0;
    for (let j = 0; j < 8; j += 1) {
      byte = (byte << 1) | bits[i + j];
    }
    codewords.push(byte);
  }

  for (let pad = 0; codewords.length < dataCodewords; pad += 1) {
    codewords.push(pad % 2 === 0 ? 0xec : 0x11);
  }

  return codewords;
}

function buildGaloisTables() {
  const exp = new Array(512);
  const log = new Array(256);
  let value = 1;

  for (let i = 0; i < 255; i += 1) {
    exp[i] = value;
    log[value] = i;
    value <<= 1;
    if ((value & 0x100) !== 0) {
      value ^= 0x11d;
    }
  }

  for (let i = 255; i < exp.length; i += 1) {
    exp[i] = exp[i - 255];
  }

  return { exp, log };
}

const gf = buildGaloisTables();

function gfMultiply(a, b) {
  if (a === 0 || b === 0) return 0;
  return gf.exp[gf.log[a] + gf.log[b]];
}

function multiplyPolynomials(left, right) {
  const result = new Array(left.length + right.length - 1).fill(0);
  for (let i = 0; i < left.length; i += 1) {
    for (let j = 0; j < right.length; j += 1) {
      result[i + j] ^= gfMultiply(left[i], right[j]);
    }
  }
  return result;
}

function buildGeneratorPolynomial(degree) {
  let result = [1];
  for (let i = 0; i < degree; i += 1) {
    result = multiplyPolynomials(result, [1, gf.exp[i]]);
  }
  return result;
}

function buildErrorCorrectionCodewords(data) {
  const generator = buildGeneratorPolynomial(eccCodewords);
  const remainder = new Array(eccCodewords).fill(0);

  for (const byte of data) {
    const factor = byte ^ remainder.shift();
    remainder.push(0);

    for (let i = 0; i < eccCodewords; i += 1) {
      remainder[i] ^= gfMultiply(generator[i + 1], factor);
    }
  }

  return remainder;
}

function createMatrix() {
  return Array.from({ length: size }, () => new Array(size).fill(false));
}

const modules = createMatrix();
const reserved = createMatrix();

function setFunctionModule(x, y, dark) {
  if (x < 0 || y < 0 || x >= size || y >= size) return;
  modules[y][x] = dark;
  reserved[y][x] = true;
}

function drawFinderPattern(left, top) {
  for (let dy = -1; dy <= 7; dy += 1) {
    for (let dx = -1; dx <= 7; dx += 1) {
      const x = left + dx;
      const y = top + dy;
      const isFinder =
        dx >= 0 &&
        dx <= 6 &&
        dy >= 0 &&
        dy <= 6 &&
        (dx === 0 ||
          dx === 6 ||
          dy === 0 ||
          dy === 6 ||
          (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4));

      setFunctionModule(x, y, isFinder);
    }
  }
}

function drawAlignmentPattern(centerX, centerY) {
  for (let dy = -2; dy <= 2; dy += 1) {
    for (let dx = -2; dx <= 2; dx += 1) {
      const distance = Math.max(Math.abs(dx), Math.abs(dy));
      setFunctionModule(centerX + dx, centerY + dy, distance === 0 || distance === 2);
    }
  }
}

function drawTimingPatterns() {
  for (let i = 0; i < size; i += 1) {
    if (!reserved[6][i]) setFunctionModule(i, 6, i % 2 === 0);
    if (!reserved[i][6]) setFunctionModule(6, i, i % 2 === 0);
  }
}

function formatBits(levelBits, mask) {
  const data = (levelBits << 3) | mask;
  let value = data << 10;
  const divisor = 0x537;

  for (let i = 14; i >= 10; i -= 1) {
    if (((value >>> i) & 1) !== 0) {
      value ^= divisor << (i - 10);
    }
  }

  return ((data << 10) | value) ^ 0x5412;
}

function bit(value, index) {
  return ((value >>> index) & 1) !== 0;
}

function drawFormatBits(mask) {
  const bits = formatBits(0b01, mask);

  for (let i = 0; i <= 5; i += 1) setFunctionModule(8, i, bit(bits, i));
  setFunctionModule(8, 7, bit(bits, 6));
  setFunctionModule(8, 8, bit(bits, 7));
  setFunctionModule(7, 8, bit(bits, 8));
  for (let i = 9; i < 15; i += 1) setFunctionModule(14 - i, 8, bit(bits, i));

  for (let i = 0; i < 8; i += 1) setFunctionModule(size - 1 - i, 8, bit(bits, i));
  for (let i = 8; i < 15; i += 1) setFunctionModule(8, size - 15 + i, bit(bits, i));

  setFunctionModule(8, size - 8, true);
}

function drawFunctionPatterns() {
  drawFinderPattern(0, 0);
  drawFinderPattern(size - 7, 0);
  drawFinderPattern(0, size - 7);
  drawAlignmentPattern(18, 18);
  drawTimingPatterns();
  drawFormatBits(0);
}

function placeDataBits(codewords) {
  const dataBits = [];
  for (const codeword of codewords) appendBits(dataBits, codeword, 8);

  let bitIndex = 0;
  let upward = true;

  for (let right = size - 1; right >= 1; right -= 2) {
    if (right === 6) right -= 1;

    for (let vertical = 0; vertical < size; vertical += 1) {
      const y = upward ? size - 1 - vertical : vertical;

      for (let offset = 0; offset < 2; offset += 1) {
        const x = right - offset;
        if (reserved[y][x]) continue;

        modules[y][x] = bitIndex < dataBits.length ? dataBits[bitIndex] === 1 : false;
        bitIndex += 1;
      }
    }

    upward = !upward;
  }
}

function applyMask0() {
  for (let y = 0; y < size; y += 1) {
    for (let x = 0; x < size; x += 1) {
      if (!reserved[y][x] && (x + y) % 2 === 0) {
        modules[y][x] = !modules[y][x];
      }
    }
  }
}

function buildSvg() {
  const quietZone = 4;
  const moduleSize = 16;
  const fullSize = (size + quietZone * 2) * moduleSize;
  const rects = [];

  for (let y = 0; y < size; y += 1) {
    for (let x = 0; x < size; x += 1) {
      if (!modules[y][x]) continue;
      rects.push(
        `<rect x="${(x + quietZone) * moduleSize}" y="${(y + quietZone) * moduleSize}" width="${moduleSize}" height="${moduleSize}"/>`,
      );
    }
  }

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${fullSize}" height="${fullSize}" viewBox="0 0 ${fullSize} ${fullSize}" shape-rendering="crispEdges" role="img" aria-label="QR code for ${payload}">
  <title>RetroAR ${objectSlug} test QR</title>
  <desc>${payload}</desc>
  <rect width="100%" height="100%" fill="#fff"/>
  <g fill="#000">
    ${rects.join('\n    ')}
  </g>
</svg>
`;
}

function buildHtml(svg) {
  return `<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RetroAR test QR</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #f5f0e8;
      color: #1f1f1f;
      font-family: Arial, sans-serif;
    }
    main {
      width: min(92vw, 760px);
      text-align: center;
    }
    svg {
      width: min(92vw, 620px);
      height: auto;
      background: white;
      box-shadow: 0 10px 32px rgba(0, 0, 0, 0.18);
    }
    code {
      display: inline-block;
      margin-top: 18px;
      padding: 10px 14px;
      border-radius: 8px;
      background: white;
      font-size: 18px;
    }
  </style>
</head>
<body>
  <main>
    ${svg.replace('<?xml version="1.0" encoding="UTF-8"?>', '')}
    <div><code>${payload}</code></div>
  </main>
</body>
</html>
`;
}

drawFunctionPatterns();

const data = buildDataCodewords(payload);
const ecc = buildErrorCorrectionCodewords(data);
placeDataBits([...data, ...ecc]);
applyMask0();
drawFormatBits(0);

const svg = buildSvg();
const html = buildHtml(svg);

await mkdir(outputDir, { recursive: true });
await writeFile(resolve(outputDir, `${outputBaseName}.svg`), svg, 'utf8');
await writeFile(resolve(outputDir, `${outputBaseName}.html`), html, 'utf8');

console.log(`Generated QR for ${payload}`);
console.log(resolve(outputDir, `${outputBaseName}.svg`));
console.log(resolve(outputDir, `${outputBaseName}.html`));
