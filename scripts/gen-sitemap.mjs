// Pre-build hook: writes public/sitemap.xml with a <lastmod> pulled from
// the latest git commit date. Falls back to the current UTC date when
// .git is not in the build context (the Docker builder stage excludes
// .git via .dockerignore, which is fine — build-time date is equally
// meaningful for a sitemap).
import { execSync } from 'node:child_process';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';

const OUT = 'public/sitemap.xml';
const SITE = 'https://hustlexp.app/';

let iso;
try {
  iso = execSync('git log -1 --format=%cI', { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }).trim();
} catch {
  iso = new Date().toISOString();
}
const date = iso.slice(0, 10);

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>${SITE}</loc>
    <lastmod>${date}</lastmod>
  </url>
</urlset>
`;

if (!existsSync('public')) mkdirSync('public', { recursive: true });
writeFileSync(OUT, xml);
console.log(`gen-sitemap: wrote ${OUT} (lastmod=${date})`);
