// Vendors the browser runtime into inst/htmlwidgets/.
//
//   cd scripts/vendor && npm install && npm run vendor
//
// Maintainer-only, run once per three.js upgrade. The output is committed, so
// installing or running GUImorphWeb never needs Node.

import { build } from 'esbuild';
import { createHash } from 'node:crypto';
import { readFile, writeFile, copyFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');
const dest = resolve(
  repo,
  'integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/htmlwidgets'
);

const pkg = JSON.parse(await readFile(resolve(here, 'package.json'), 'utf8'));
const versionOf = async (name) =>
  JSON.parse(
    await readFile(resolve(here, 'node_modules', name, 'package.json'), 'utf8')
  ).version;

await mkdir(dest, { recursive: true });

const outfile = resolve(dest, 'guimorphweb-three.js');
await build({
  entryPoints: [resolve(here, 'entry.js')],
  bundle: true,
  minify: true,
  format: 'iife',
  globalName: 'GMW',
  target: ['chrome100', 'firefox100', 'safari15'],
  outfile,
  legalComments: 'none',
});

await copyFile(
  resolve(here, 'node_modules/three/LICENSE'),
  resolve(dest, 'LICENSE.three.txt')
);
await copyFile(
  resolve(here, 'node_modules/three-mesh-bvh/LICENSE'),
  resolve(dest, 'LICENSE.three-mesh-bvh.txt')
);

const bytes = await readFile(outfile);
const sha = createHash('sha256').update(bytes).digest('hex');

const manifest = {
  generated: new Date().toISOString().slice(0, 10),
  generator: 'scripts/vendor/build.mjs',
  output: 'guimorphweb-three.js',
  globalName: 'GMW',
  format: 'iife',
  bytes: bytes.length,
  sha256: sha,
  packages: {
    three: await versionOf('three'),
    'three-mesh-bvh': await versionOf('three-mesh-bvh'),
  },
  builtWith: {
    esbuild: pkg.devDependencies.esbuild,
    node: process.version,
  },
  exports: ['THREE', 'OrbitControls', 'PLYLoader'],
  notes: [
    'Classic script, no top-level import/export, so it loads from file:// as well as http://.',
    'three-mesh-bvh prototype patches are applied at bundle time; Mesh.raycast is already accelerated.',
    'three.js ships ES modules only from 0.160; this bundle exists because ES modules are CORS-blocked on file://.',
  ],
};

await writeFile(
  resolve(dest, 'VENDOR-MANIFEST.json'),
  JSON.stringify(manifest, null, 2) + '\n'
);

console.log(`wrote ${outfile}`);
console.log(`  ${(bytes.length / 1024).toFixed(0)} KB  sha256 ${sha.slice(0, 16)}...`);
console.log(`  three ${manifest.packages.three}, three-mesh-bvh ${manifest.packages['three-mesh-bvh']}`);
