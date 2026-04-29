const GRID_SIZE = 16;
const DEFAULT_CANVAS_HEIGHT = 960;
const PROJECT_JSON_PATH = "../../datafiles/infiniteRunner/world1_chunks.json";

const OBJECT_LIBRARY = [
    { name: "objSolid", category: "Terrain", color: "#8bc34a", baseWidth: 16, baseHeight: 16 },
    { name: "objSolid1", category: "Terrain", color: "#7cc95b", baseWidth: 16, baseHeight: 16 },
    { name: "objSolid6", category: "Terrain", color: "#62b058", baseWidth: 16, baseHeight: 16 },
    { name: "objSolidInvisible", category: "Terrain", color: "#4d6b7f", baseWidth: 16, baseHeight: 16 },
    { name: "obj_Wall", category: "Terrain", color: "#6aa84f", baseWidth: 16, baseHeight: 16 },
    { name: "objSloped", category: "Slopes", color: "#5bc0de", baseWidth: 32, baseHeight: 16 },
    { name: "objSloped45", category: "Slopes", color: "#4db6ac", baseWidth: 16, baseHeight: 16 },
    { name: "objSloped45Left", category: "Slopes", color: "#26a69a", baseWidth: 16, baseHeight: 16 },
    { name: "objSloped_1", category: "Slopes", color: "#00acc1", baseWidth: 32, baseHeight: 16 },
    { name: "objSloped_2", category: "Slopes", color: "#039be5", baseWidth: 32, baseHeight: 16 },
    { name: "objSloped_3", category: "Slopes", color: "#1e88e5", baseWidth: 32, baseHeight: 16 },
    { name: "objSloped_4", category: "Slopes", color: "#3f51b5", baseWidth: 32, baseHeight: 16 },
    { name: "objBouncyBottom", category: "Bounce", color: "#f8b94a", baseWidth: 16, baseHeight: 16 },
    { name: "objBouncyTop", category: "Bounce", color: "#f5a623", baseWidth: 16, baseHeight: 16 },
    { name: "objBouncyLeft", category: "Bounce", color: "#ff9800", baseWidth: 16, baseHeight: 16 },
    { name: "objBouncyRight", category: "Bounce", color: "#ffb300", baseWidth: 16, baseHeight: 16 },
    { name: "objSlopBot", category: "Enemies", color: "#ef5350", baseWidth: 16, baseHeight: 16 },
    { name: "objSlopBotGunner", category: "Enemies", color: "#e53935", baseWidth: 16, baseHeight: 16 },
    { name: "objSlopBotSlacker", category: "Enemies", color: "#c62828", baseWidth: 16, baseHeight: 16 },
];

const objectByName = new Map(OBJECT_LIBRARY.map((entry) => [entry.name, entry]));

const state = {
    doc: null,
    currentChunkIndex: -1,
    selectedElementIndex: -1,
    selectedPaletteObject: "objSolid",
    zoom: 1,
    drag: null,
};

const els = {
    status: document.getElementById("status-text"),
    importJson: document.getElementById("import-json"),
    loadProjectJson: document.getElementById("load-project-json"),
    saveJson: document.getElementById("save-json"),
    copyJson: document.getElementById("copy-json"),
    chunkFilter: document.getElementById("chunk-filter"),
    chunkList: document.getElementById("chunk-list"),
    palette: document.getElementById("palette"),
    zoomRange: document.getElementById("zoom-range"),
    zoomLabel: document.getElementById("zoom-label"),
    addSelectedType: document.getElementById("add-selected-type"),
    duplicateSelected: document.getElementById("duplicate-selected"),
    deleteSelected: document.getElementById("delete-selected"),
    chunkTitle: document.getElementById("chunk-title"),
    chunkSubtitle: document.getElementById("chunk-subtitle"),
    chunkWidth: document.getElementById("chunk-width"),
    chunkSourceRoom: document.getElementById("chunk-source-room"),
    chunkSourceStart: document.getElementById("chunk-source-start"),
    chunkElementCount: document.getElementById("chunk-element-count"),
    elementObject: document.getElementById("element-object"),
    elementDx: document.getElementById("element-dx"),
    elementDy: document.getElementById("element-dy"),
    elementScaleX: document.getElementById("element-scale-x"),
    elementScaleY: document.getElementById("element-scale-y"),
    elementRotation: document.getElementById("element-rotation"),
    jsonPreview: document.getElementById("json-preview"),
    canvasScroll: document.getElementById("canvas-scroll"),
    canvas: document.getElementById("chunk-canvas"),
};

const ctx = els.canvas.getContext("2d");

function chunkList() {
    return state.doc?.chunks ?? [];
}

function currentChunk() {
    return chunkList()[state.currentChunkIndex] ?? null;
}

function currentElement() {
    const chunk = currentChunk();
    if (!chunk) return null;
    return chunk.elements?.[state.selectedElementIndex] ?? null;
}

function deepClone(value) {
    return JSON.parse(JSON.stringify(value));
}

function normalizeDoc(doc) {
    const clone = deepClone(doc);
    clone.chunk_set = clone.chunk_set ?? "world1";
    clone.chunk_width = Number(clone.chunk_width ?? 640);
    clone.source_rooms = Array.isArray(clone.source_rooms) ? clone.source_rooms : [];
    clone.chunks = Array.isArray(clone.chunks) ? clone.chunks : [];

    clone.chunks.forEach((chunk) => {
        chunk.width = Number(chunk.width ?? clone.chunk_width ?? 640);
        chunk.platforms = Array.isArray(chunk.platforms) ? chunk.platforms : [];
        chunk.hazards = Array.isArray(chunk.hazards) ? chunk.hazards : [];
        chunk.elements = Array.isArray(chunk.elements) ? chunk.elements : [];

        chunk.elements = chunk.elements.map((element) => ({
            object_name: String(element.object_name ?? "objSolid"),
            dx: Number(element.dx ?? 0),
            dy: Number(element.dy ?? 0),
            scale_x: Number(element.scale_x ?? 1),
            scale_y: Number(element.scale_y ?? 1),
            rotation: Number(element.rotation ?? 0),
        }));
    });

    return clone;
}

function prettyJson() {
    return JSON.stringify(state.doc, null, 4);
}

function setStatus(text, isError = false) {
    els.status.textContent = text;
    els.status.style.color = isError ? "#ff8a80" : "";
}

function selectChunk(index) {
    state.currentChunkIndex = index;
    state.selectedElementIndex = -1;
    refreshAll();
}

function selectElement(index) {
    state.selectedElementIndex = index;
    refreshInspector();
    redrawCanvas();
}

function metadataForObject(name) {
    return objectByName.get(name) ?? {
        name,
        category: "Custom",
        color: "#90a4ae",
        baseWidth: 16,
        baseHeight: 16,
    };
}

function worldHeightForChunk(chunk) {
    if (!chunk) return DEFAULT_CANVAS_HEIGHT;

    let maxY = 0;
    for (const element of chunk.elements) {
        const meta = metadataForObject(element.object_name);
        const h = Math.max(GRID_SIZE, Math.abs(element.scale_y) * meta.baseHeight);
        maxY = Math.max(maxY, element.dy + h + GRID_SIZE * 2);
    }

    return Math.max(DEFAULT_CANVAS_HEIGHT, Math.ceil(maxY / GRID_SIZE) * GRID_SIZE);
}

function elementRect(element) {
    const meta = metadataForObject(element.object_name);
    const width = Math.max(GRID_SIZE, Math.abs(element.scale_x) * meta.baseWidth);
    const height = Math.max(GRID_SIZE, Math.abs(element.scale_y) * meta.baseHeight);
    return {
        x: element.dx,
        y: element.dy,
        width,
        height,
        meta,
    };
}

function snapValue(value) {
    return Math.round(value / GRID_SIZE) * GRID_SIZE;
}

function formatChunkLabel(chunk, index) {
    const room = chunk.source_room ?? "custom";
    const source = chunk.source_start ?? 0;
    return `#${index} • ${room} @ ${source}`;
}

function refreshChunkList() {
    const filter = els.chunkFilter.value.trim().toLowerCase();
    els.chunkList.innerHTML = "";

    chunkList().forEach((chunk, index) => {
        const label = formatChunkLabel(chunk, index);
        const haystack = `${label} ${chunk.width}`.toLowerCase();
        if (filter && !haystack.includes(filter)) return;

        const button = document.createElement("button");
        button.className = "chunk-item" + (index === state.currentChunkIndex ? " active" : "");
        button.innerHTML = `<strong>${label}</strong><small>${chunk.elements.length} elements • width ${chunk.width}</small>`;
        button.addEventListener("click", () => selectChunk(index));
        els.chunkList.appendChild(button);
    });
}

function refreshPalette() {
    els.palette.innerHTML = "";
    const categories = new Map();

    for (const entry of OBJECT_LIBRARY) {
        if (!categories.has(entry.category)) categories.set(entry.category, []);
        categories.get(entry.category).push(entry);
    }

    for (const [category, entries] of categories.entries()) {
        const heading = document.createElement("div");
        heading.className = "muted";
        heading.textContent = category;
        els.palette.appendChild(heading);

        for (const entry of entries) {
            const button = document.createElement("button");
            button.className = "palette-item" + (entry.name === state.selectedPaletteObject ? " active" : "");
            button.innerHTML = `<strong>${entry.name}</strong><small>${entry.baseWidth}×${entry.baseHeight} base</small>`;
            button.style.borderLeft = `5px solid ${entry.color}`;
            button.addEventListener("click", () => {
                state.selectedPaletteObject = entry.name;
                refreshPalette();
                if (currentElement()) {
                    els.elementObject.value = entry.name;
                }
            });
            els.palette.appendChild(button);
        }
    }
}

function refreshChunkFields() {
    const chunk = currentChunk();
    if (!chunk) {
        els.chunkTitle.textContent = "No chunk selected";
        els.chunkSubtitle.textContent = "";
        els.chunkWidth.value = "";
        els.chunkSourceRoom.value = "";
        els.chunkSourceStart.value = "";
        els.chunkElementCount.value = "";
        return;
    }

    els.chunkTitle.textContent = formatChunkLabel(chunk, state.currentChunkIndex);
    els.chunkSubtitle.textContent = "Edit geometry on the canvas or tweak values here.";
    els.chunkWidth.value = chunk.width;
    els.chunkSourceRoom.value = chunk.source_room ?? "";
    els.chunkSourceStart.value = chunk.source_start ?? 0;
    els.chunkElementCount.value = String(chunk.elements.length);
}

function populateObjectSelect() {
    els.elementObject.innerHTML = "";
    for (const entry of OBJECT_LIBRARY) {
        const option = document.createElement("option");
        option.value = entry.name;
        option.textContent = entry.name;
        els.elementObject.appendChild(option);
    }
}

function refreshInspector() {
    refreshChunkFields();

    const element = currentElement();
    const disabled = !element;
    for (const input of [
        els.elementObject,
        els.elementDx,
        els.elementDy,
        els.elementScaleX,
        els.elementScaleY,
        els.elementRotation,
        els.duplicateSelected,
        els.deleteSelected,
    ]) {
        input.disabled = disabled;
    }

    if (!element) {
        els.elementObject.value = state.selectedPaletteObject;
        els.elementDx.value = "";
        els.elementDy.value = "";
        els.elementScaleX.value = "";
        els.elementScaleY.value = "";
        els.elementRotation.value = "";
        els.jsonPreview.value = state.doc ? prettyJson() : "";
        return;
    }

    els.elementObject.value = element.object_name;
    els.elementDx.value = element.dx;
    els.elementDy.value = element.dy;
    els.elementScaleX.value = element.scale_x;
    els.elementScaleY.value = element.scale_y;
    els.elementRotation.value = element.rotation;
    els.jsonPreview.value = JSON.stringify(element, null, 4);
}

function redrawCanvas() {
    const chunk = currentChunk();
    const width = chunk?.width ?? 640;
    const height = worldHeightForChunk(chunk);

    els.canvas.width = width;
    els.canvas.height = height;
    els.canvas.style.transform = `scale(${state.zoom})`;
    els.zoomLabel.textContent = `${Math.round(state.zoom * 100)}%`;

    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = "#0f171d";
    ctx.fillRect(0, 0, width, height);

    for (let x = 0; x <= width; x += GRID_SIZE) {
        ctx.strokeStyle = x % (GRID_SIZE * 4) === 0 ? "rgba(255,255,255,0.16)" : "rgba(255,255,255,0.08)";
        ctx.beginPath();
        ctx.moveTo(x + 0.5, 0);
        ctx.lineTo(x + 0.5, height);
        ctx.stroke();
    }

    for (let y = 0; y <= height; y += GRID_SIZE) {
        ctx.strokeStyle = y % (GRID_SIZE * 4) === 0 ? "rgba(255,255,255,0.16)" : "rgba(255,255,255,0.08)";
        ctx.beginPath();
        ctx.moveTo(0, y + 0.5);
        ctx.lineTo(width, y + 0.5);
        ctx.stroke();
    }

    if (!chunk) return;

    chunk.elements.forEach((element, index) => {
        const rect = elementRect(element);
        ctx.save();
        ctx.translate(rect.x + rect.width / 2, rect.y + rect.height / 2);
        ctx.rotate((element.rotation * Math.PI) / 180);

        ctx.fillStyle = rect.meta.color;
        ctx.globalAlpha = 0.82;
        ctx.fillRect(-rect.width / 2, -rect.height / 2, rect.width, rect.height);

        ctx.globalAlpha = 1;
        ctx.strokeStyle = index === state.selectedElementIndex ? "#ffffff" : "rgba(0,0,0,0.45)";
        ctx.lineWidth = index === state.selectedElementIndex ? 3 : 1.5;
        ctx.strokeRect(-rect.width / 2, -rect.height / 2, rect.width, rect.height);

        ctx.fillStyle = "#081118";
        ctx.font = "11px Segoe UI";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(rect.meta.name.replace("obj", ""), 0, 0, Math.max(42, rect.width - 4));
        ctx.restore();
    });
}

function refreshAll() {
    refreshChunkList();
    refreshPalette();
    refreshInspector();
    redrawCanvas();
}

function updateChunkField(field, value) {
    const chunk = currentChunk();
    if (!chunk) return;
    chunk[field] = value;
    refreshAll();
}

function updateElementField(field, value) {
    const element = currentElement();
    if (!element) return;
    element[field] = value;
    refreshInspector();
    redrawCanvas();
}

function addElementAt(dx, dy) {
    const chunk = currentChunk();
    if (!chunk) return;

    const next = {
        object_name: state.selectedPaletteObject,
        dx,
        dy,
        scale_x: 1,
        scale_y: 1,
        rotation: 0,
    };

    chunk.elements.push(next);
    selectElement(chunk.elements.length - 1);
    refreshAll();
}

function duplicateSelectedElement() {
    const chunk = currentChunk();
    const element = currentElement();
    if (!chunk || !element) return;

    const clone = deepClone(element);
    clone.dx += GRID_SIZE;
    clone.dy += GRID_SIZE;
    chunk.elements.push(clone);
    selectElement(chunk.elements.length - 1);
    refreshAll();
}

function deleteSelectedElement() {
    const chunk = currentChunk();
    if (!chunk || state.selectedElementIndex < 0) return;
    chunk.elements.splice(state.selectedElementIndex, 1);
    state.selectedElementIndex = Math.min(state.selectedElementIndex, chunk.elements.length - 1);
    refreshAll();
}

function hitTestElement(worldX, worldY) {
    const chunk = currentChunk();
    if (!chunk) return -1;

    for (let i = chunk.elements.length - 1; i >= 0; i -= 1) {
        const rect = elementRect(chunk.elements[i]);
        if (
            worldX >= rect.x &&
            worldX <= rect.x + rect.width &&
            worldY >= rect.y &&
            worldY <= rect.y + rect.height
        ) {
            return i;
        }
    }

    return -1;
}

function canvasPointFromEvent(event) {
    const rect = els.canvas.getBoundingClientRect();
    return {
        x: (event.clientX - rect.left) / state.zoom,
        y: (event.clientY - rect.top) / state.zoom,
    };
}

function openDocument(doc, sourceLabel) {
    state.doc = normalizeDoc(doc);
    state.currentChunkIndex = state.doc.chunks.length > 0 ? 0 : -1;
    state.selectedElementIndex = -1;
    setStatus(`Loaded ${sourceLabel}. ${state.doc.chunks.length} chunks ready.`);
    refreshAll();
}

async function loadProjectJson() {
    try {
        const response = await fetch(PROJECT_JSON_PATH, { cache: "no-store" });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const doc = await response.json();
        openDocument(doc, "project JSON");
    } catch (error) {
        setStatus("Could not load project JSON directly. Try Import JSON instead.", true);
    }
}

function downloadJson() {
    if (!state.doc) return;
    const blob = new Blob([prettyJson()], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "world1_chunks.json";
    anchor.click();
    URL.revokeObjectURL(url);
    setStatus("Downloaded world1_chunks.json");
}

async function copyJson() {
    if (!state.doc) return;
    try {
        await navigator.clipboard.writeText(prettyJson());
        setStatus("Copied JSON to clipboard.");
    } catch (error) {
        setStatus("Clipboard copy failed in this browser context.", true);
    }
}

function installEventHandlers() {
    els.loadProjectJson.addEventListener("click", loadProjectJson);
    els.saveJson.addEventListener("click", downloadJson);
    els.copyJson.addEventListener("click", copyJson);
    els.chunkFilter.addEventListener("input", refreshChunkList);
    els.zoomRange.addEventListener("input", () => {
        state.zoom = Number(els.zoomRange.value);
        redrawCanvas();
    });

    els.importJson.addEventListener("change", async (event) => {
        const [file] = event.target.files;
        if (!file) return;
        const text = await file.text();
        try {
            const doc = JSON.parse(text);
            openDocument(doc, file.name);
        } catch (error) {
            setStatus("That file is not valid JSON.", true);
        }
    });

    els.chunkWidth.addEventListener("input", () => updateChunkField("width", Number(els.chunkWidth.value || 640)));
    els.chunkSourceRoom.addEventListener("input", () => updateChunkField("source_room", els.chunkSourceRoom.value));
    els.chunkSourceStart.addEventListener("input", () => updateChunkField("source_start", Number(els.chunkSourceStart.value || 0)));

    els.elementObject.addEventListener("input", () => updateElementField("object_name", els.elementObject.value));
    els.elementDx.addEventListener("input", () => updateElementField("dx", Number(els.elementDx.value || 0)));
    els.elementDy.addEventListener("input", () => updateElementField("dy", Number(els.elementDy.value || 0)));
    els.elementScaleX.addEventListener("input", () => updateElementField("scale_x", Number(els.elementScaleX.value || 1)));
    els.elementScaleY.addEventListener("input", () => updateElementField("scale_y", Number(els.elementScaleY.value || 1)));
    els.elementRotation.addEventListener("input", () => updateElementField("rotation", Number(els.elementRotation.value || 0)));

    els.addSelectedType.addEventListener("click", () => {
        const chunk = currentChunk();
        if (!chunk) return;
        addElementAt(snapValue(chunk.width * 0.5), snapValue(worldHeightForChunk(chunk) * 0.5));
    });
    els.duplicateSelected.addEventListener("click", duplicateSelectedElement);
    els.deleteSelected.addEventListener("click", deleteSelectedElement);

    window.addEventListener("keydown", (event) => {
        if (!currentChunk()) return;

        if (event.key === "Delete" || event.key === "Backspace") {
            if (currentElement()) {
                deleteSelectedElement();
                event.preventDefault();
            }
            return;
        }

        const element = currentElement();
        if (!element) return;

        let moved = false;
        const step = event.shiftKey ? 1 : GRID_SIZE;
        if (event.key === "ArrowLeft") {
            element.dx -= step;
            moved = true;
        } else if (event.key === "ArrowRight") {
            element.dx += step;
            moved = true;
        } else if (event.key === "ArrowUp") {
            element.dy -= step;
            moved = true;
        } else if (event.key === "ArrowDown") {
            element.dy += step;
            moved = true;
        }

        if (moved) {
            refreshInspector();
            redrawCanvas();
            event.preventDefault();
        }
    });

    els.canvas.addEventListener("mousedown", (event) => {
        const point = canvasPointFromEvent(event);
        const hit = hitTestElement(point.x, point.y);

        if (hit >= 0) {
            selectElement(hit);
            const element = currentElement();
            state.drag = {
                index: hit,
                offsetX: point.x - element.dx,
                offsetY: point.y - element.dy,
                snap: !event.shiftKey,
            };
            return;
        }

        if (!currentChunk()) return;
        const x = event.shiftKey ? point.x : snapValue(point.x);
        const y = event.shiftKey ? point.y : snapValue(point.y);
        addElementAt(x, y);
        state.drag = {
            index: state.selectedElementIndex,
            offsetX: 0,
            offsetY: 0,
            snap: !event.shiftKey,
        };
    });

    window.addEventListener("mousemove", (event) => {
        if (!state.drag) return;
        const element = currentElement();
        if (!element) return;

        const point = canvasPointFromEvent(event);
        let nextX = point.x - state.drag.offsetX;
        let nextY = point.y - state.drag.offsetY;

        if (state.drag.snap) {
            nextX = snapValue(nextX);
            nextY = snapValue(nextY);
        }

        element.dx = Math.max(-GRID_SIZE * 4, nextX);
        element.dy = Math.max(-GRID_SIZE * 4, nextY);
        refreshInspector();
        redrawCanvas();
    });

    window.addEventListener("mouseup", () => {
        state.drag = null;
    });
}

function boot() {
    populateObjectSelect();
    installEventHandlers();
    refreshPalette();
    refreshInspector();
    redrawCanvas();
    setStatus("Load project JSON or import a chunk file to start editing.");
}

boot();
