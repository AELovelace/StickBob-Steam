# Infinite Runner Chunk Editor

This is a lightweight browser editor for `datafiles/infiniteRunner/world1_chunks.json`.

## What It Does

- Loads the current runner chunk JSON
- Lets you browse chunks one at a time
- Renders chunk `elements` on a 16px grid
- Supports click-to-select, drag-to-move, duplicate, delete, and property editing
- Exports valid JSON back out

## Current Scope

This first version is focused on the chunk format you are actually using right now:

- `width`
- `source_room`
- `source_start`
- `elements[]`

It preserves `platforms` and `hazards`, but the visual editing workflow is centered on `elements`.

## Usage

From the project root, serve the repo locally with something simple like:

```powershell
python -m http.server 8765
```

Then open:

```text
http://localhost:8765/tools/infiniteRunnerEditor/
```

Inside the editor:

1. Click `Load Project JSON` to load `datafiles/infiniteRunner/world1_chunks.json`.
2. Edit chunks visually.
3. Click `Download JSON` when you want to save.
4. Replace `datafiles/infiniteRunner/world1_chunks.json` with the exported file.

## Notes

- Dragging snaps to the 16px grid.
- Hold `Shift` while dragging for unsnapped movement.
- Arrow keys move the selected element by 16px.
- `Shift` + arrow keys move by 1px.

## Next Good Upgrades

- Add chunk creation / deletion / reordering
- Visual editing for `platforms` and `hazards`
- Sprite previews pulled from GameMaker assets
- Direct save-back instead of download/export
- Validation against the runtime asset list
