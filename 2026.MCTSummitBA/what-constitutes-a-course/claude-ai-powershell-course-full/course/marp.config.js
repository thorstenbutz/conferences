// marp.config.js
// MARP CLI configuration for the PowerShell 7 for IT Administrators course.
// Invoked automatically by `marp` when run from this directory.
// Docs: https://github.com/marp-team/marp-cli#configuration-file

/** @type {import('@marp-team/marp-cli').Config} */
module.exports = {
  // Path to our forked, code-friendly, Noble Blue theme.
  themeSet: ['./themes/noble-blue.css'],

  // Whether MARP may read local images (../images/*.jpg, *.svg).
  // Required because the decks reference files outside their own folder.
  allowLocalFiles: true,

  // PDF/PPTX/image rendering needs a browser; MARP finds it automatically
  // when CHROME_PATH is set by build.ps1.

  options: {
    // Use the v3 engine (MARP Core 4.x) — modern CSS features, advanced backgrounds.
    looseYAML: false,
  },
};
