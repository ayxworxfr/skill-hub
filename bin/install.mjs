#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const SKILLS = [
  'planning',
  'reading-code',
  'designing-frontend',
  'debugging',
  'refactoring',
  'building',
  'reviewing-code',
  'git-safety',
  'verifying',
  'engineering-skills',
];

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, '..');
const skillsRoot = join(repoRoot, 'cursor');

const args = process.argv.slice(2);
const isProject = args.includes('--project');
const isCursor = args.includes('--cursor');
const force = args.includes('--force');

let baseDir;
if (isCursor) {
  baseDir = join(isProject ? process.cwd() : homedir(), '.cursor', 'skills');
} else {
  baseDir = join(isProject ? process.cwd() : homedir(), '.claude', 'skills');
}

mkdirSync(baseDir, { recursive: true });

console.log(`Installing skills from ${skillsRoot}`);
console.log(`Target directory: ${baseDir}`);

let installed = 0;
let skipped = 0;
const conflicts = [];

for (const skill of SKILLS) {
  const src = join(skillsRoot, skill);
  const dst = join(baseDir, skill);

  if (!existsSync(src)) {
    console.warn(`  ! ${skill} (source missing, skipping)`);
    skipped++;
    continue;
  }

  if (existsSync(dst) && !force) {
    conflicts.push(skill);
    console.warn(`  ! ${skill} (already exists, use --force to overwrite)`);
    skipped++;
    continue;
  }

  if (existsSync(dst)) {
    rmSync(dst, { recursive: true, force: true });
  }
  cpSync(src, dst, { recursive: true });
  console.log(`  ✓ ${skill}`);
  installed++;
}

console.log(`\nDone. installed: ${installed}, skipped: ${skipped}`);
if (conflicts.length && !force) {
  console.log(`\nConflicts: ${conflicts.join(', ')}`);
  console.log('Re-run with --force to overwrite.');
  process.exit(1);
}
