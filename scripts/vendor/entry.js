// Bundle entry for the GUImorphWeb browser runtime.
//
// Everything the browser layer needs, in one classic script. three.js dropped
// its UMD build; 0.185.x ships ES modules only, and ES modules are blocked from
// file:// by CORS. Bundling to an IIFE keeps a plain HTML file openable with
// browseURL() while working identically when served over httpuv later.
//
// The BVH prototype patches are applied here so raycast acceleration is present
// from the moment the bundle loads; Phase 4 picking needs no extra wiring.

import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { PLYLoader } from 'three/examples/jsm/loaders/PLYLoader.js';
import {
  computeBoundsTree,
  disposeBoundsTree,
  acceleratedRaycast,
} from 'three-mesh-bvh';

THREE.BufferGeometry.prototype.computeBoundsTree = computeBoundsTree;
THREE.BufferGeometry.prototype.disposeBoundsTree = disposeBoundsTree;
THREE.Mesh.prototype.raycast = acceleratedRaycast;

export { THREE, OrbitControls, PLYLoader };
