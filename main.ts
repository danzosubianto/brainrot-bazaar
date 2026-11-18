// Brainrot Bazaar — the make.fun hand-in program for roblox-brainrot-01.
//
// The game itself is a Rojo project in this repository: the Luau sources live
// under src/, and `rojo build default.project.json --output game.rbxl` folds
// them into the binary place file. This program does no building; it hands in.
// It copies game.rbxl, PLAY.json, src/ and screenshots/ from beside itself to
// the output directory and writes dossier.json there with buildDossier from
// the vendored make.fun library, byte for byte as the gate rebuilds it.
//
// Run it the way the kit prescribes:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
// MAKEFUN_OUTPUT_DIR stands in for /output outside the grader's container.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoDir = fileURLToPath(new URL('.', import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The grader refuses an output name that starts with a dot, so the copy drops
// every dotted name (.gitkeep, .DS_Store and friends) at any depth.
const keepName = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(outDir, { recursive: true });
copyFileSync(join(repoDir, 'game.rbxl'), join(outDir, 'game.rbxl'));
copyFileSync(join(repoDir, 'PLAY.json'), join(outDir, 'PLAY.json'));
cpSync(join(repoDir, 'src'), join(outDir, 'src'), { recursive: true, filter: keepName });
if (existsSync(join(repoDir, 'screenshots'))) {
  cpSync(join(repoDir, 'screenshots'), join(outDir, 'screenshots'), { recursive: true, filter: keepName });
}

// The caps are the scorer's own: at most 4 screenshots of at most 256 KiB, a
// place of at most 500,000 instances whose script sources total at most
// 8 MiB and whose script paths total at most 1,048,576 characters.
const dossier = buildDossier(outDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(outDir, 'dossier.json'), dossier);
