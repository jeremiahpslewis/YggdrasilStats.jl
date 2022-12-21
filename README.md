# YggdrasilStats.jl

## Purpose

Make Yggdrasil binary statistics easily available.

**Note: This is very much a work in progress**

This repository collects metadata about binaries available via Julia's Yggdrasil.

This metadata can be used to optimize Yggdrasil as well as a source for Repology's binary package index.


TODO:

Special case 100 * x versions...
Autocommit JSON / CSV output
Ensure all requirements covered https://repology.org/docs/requirements
Spot-check for accuracy
Filter out implausible versions (via comparison / dropping * 100 versions)
Debug Openresty, why version info not collected
Capture time series aspect / earlier versions
Go through binaries with multiple 'version' variables in build_tarballs.jl, select 'correct' variable name and add to config file, use this to expand 'version verified' binaries
