# Gamejam template

A small Heaps project template for web-based games.

## Instructions

### Setup

* Install [Haxe](https://haxe.org/)
* Install [Git Bash](https://gitforwindows.org/) if you are on Windows
* Optional: install Python and livereload `pip install livereload`
* Optional: install [Git LFS](https://git-lfs.github.com/)
  * `git lfs install` once on the repo to set up
* Optional: install Visual Studio Code
* Optional: enable GitHub pages in the repto settings (`/settings/pages`)

### Building

* Install dependencies: `haxelib install build-js.hxml`
* Build the assets package: `bash run buildres`
* Compile the project: `bash run compile` (or Ctrl+Shift+B in vscode)

## TODO

* Automatically publish to GitHub pages
* Add a save game template (e.g. highscore)
* Add sound template
* Add credits button
* Easily support query params for debugging