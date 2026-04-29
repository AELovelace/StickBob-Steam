import json
import math
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk


GRID_SIZE = 16
DEFAULT_JSON_PATH = Path(__file__).resolve().parent.parent / "datafiles" / "infiniteRunner" / "world1_chunks.json"
DEFAULT_CANVAS_HEIGHT = 960


OBJECT_LIBRARY = [
    {"name": "objSolid", "category": "Terrain", "color": "#8bc34a", "w": 16, "h": 16},
    {"name": "objSolid1", "category": "Terrain", "color": "#7cc95b", "w": 16, "h": 16},
    {"name": "objSolid6", "category": "Terrain", "color": "#62b058", "w": 16, "h": 16},
    {"name": "objSolidInvisible", "category": "Terrain", "color": "#4d6b7f", "w": 16, "h": 16},
    {"name": "obj_Wall", "category": "Terrain", "color": "#6aa84f", "w": 16, "h": 16},
    {"name": "objSloped", "category": "Slopes", "color": "#5bc0de", "w": 32, "h": 16},
    {"name": "objSloped45", "category": "Slopes", "color": "#4db6ac", "w": 16, "h": 16},
    {"name": "objSloped45Left", "category": "Slopes", "color": "#26a69a", "w": 16, "h": 16},
    {"name": "objSloped_1", "category": "Slopes", "color": "#00acc1", "w": 32, "h": 16},
    {"name": "objSloped_2", "category": "Slopes", "color": "#039be5", "w": 32, "h": 16},
    {"name": "objSloped_3", "category": "Slopes", "color": "#1e88e5", "w": 32, "h": 16},
    {"name": "objSloped_4", "category": "Slopes", "color": "#3f51b5", "w": 32, "h": 16},
    {"name": "objBouncyBottom", "category": "Bounce", "color": "#f8b94a", "w": 16, "h": 16},
    {"name": "objBouncyTop", "category": "Bounce", "color": "#f5a623", "w": 16, "h": 16},
    {"name": "objBouncyLeft", "category": "Bounce", "color": "#ff9800", "w": 16, "h": 16},
    {"name": "objBouncyRight", "category": "Bounce", "color": "#ffb300", "w": 16, "h": 16},
    {"name": "objSlopBot", "category": "Enemies", "color": "#ef5350", "w": 16, "h": 16},
    {"name": "objSlopBotGunner", "category": "Enemies", "color": "#e53935", "w": 16, "h": 16},
    {"name": "objSlopBotSlacker", "category": "Enemies", "color": "#c62828", "w": 16, "h": 16},
]

OBJECT_MAP = {entry["name"]: entry for entry in OBJECT_LIBRARY}


def snap(value):
    return round(value / GRID_SIZE) * GRID_SIZE


def deep_copy_json(data):
    return json.loads(json.dumps(data))


def normalize_doc(data):
    doc = deep_copy_json(data)
    doc.setdefault("chunk_set", "world1")
    doc["chunk_width"] = int(doc.get("chunk_width", 640))
    doc["source_rooms"] = list(doc.get("source_rooms", []))
    doc["chunks"] = list(doc.get("chunks", []))

    for chunk in doc["chunks"]:
        chunk["width"] = int(chunk.get("width", doc["chunk_width"]))
        chunk["platforms"] = _normalize_arrayish(chunk.get("platforms", []))
        chunk["hazards"] = _normalize_arrayish(chunk.get("hazards", []))
        chunk["elements"] = _normalize_arrayish(chunk.get("elements", []))

        normalized_elements = []
        for element in chunk["elements"]:
            normalized_elements.append(
                {
                    "object_name": str(element.get("object_name", "objSolid")),
                    "dx": float(element.get("dx", 0)),
                    "dy": float(element.get("dy", 0)),
                    "scale_x": float(element.get("scale_x", 1)),
                    "scale_y": float(element.get("scale_y", 1)),
                    "rotation": float(element.get("rotation", 0)),
                }
            )
        chunk["elements"] = normalized_elements

    return doc


def _normalize_arrayish(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, dict):
        return [value]
    return []


class ChunkEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("Infinite Runner Chunk Editor")
        self.root.geometry("1480x920")

        self.file_path = DEFAULT_JSON_PATH
        self.doc = None
        self.current_chunk_index = -1
        self.selected_element_index = -1
        self.selected_palette = tk.StringVar(value="objSolid")
        self.zoom = tk.DoubleVar(value=1.0)
        self.dragging = None
        self.canvas_items = {}
        self.updating_fields = False

        self._build_ui()
        self._bind_events()
        self.load_file(self.file_path)

    def _build_ui(self):
        self.root.columnconfigure(1, weight=1)
        self.root.rowconfigure(0, weight=1)

        self.left = ttk.Frame(self.root, padding=10)
        self.left.grid(row=0, column=0, sticky="nsew")
        self.left.columnconfigure(0, weight=1)

        self.main = ttk.Frame(self.root, padding=10)
        self.main.grid(row=0, column=1, sticky="nsew")
        self.main.columnconfigure(0, weight=1)
        self.main.columnconfigure(1, weight=0)
        self.main.rowconfigure(1, weight=1)

        ttk.Label(self.left, text="Runner Chunk Editor", font=("Segoe UI", 15, "bold")).grid(row=0, column=0, sticky="w")
        self.status_var = tk.StringVar(value="Loading...")
        ttk.Label(self.left, textvariable=self.status_var, foreground="#4a6a7f", wraplength=300).grid(row=1, column=0, sticky="ew", pady=(4, 10))

        file_frame = ttk.LabelFrame(self.left, text="File", padding=10)
        file_frame.grid(row=2, column=0, sticky="ew", pady=(0, 10))
        ttk.Button(file_frame, text="Open JSON", command=self.open_file_dialog).grid(row=0, column=0, sticky="ew")
        ttk.Button(file_frame, text="Reload Default", command=lambda: self.load_file(DEFAULT_JSON_PATH)).grid(row=1, column=0, sticky="ew", pady=(6, 0))
        ttk.Button(file_frame, text="Save", command=self.save_file).grid(row=2, column=0, sticky="ew", pady=(6, 0))
        ttk.Button(file_frame, text="Save As", command=self.save_file_as).grid(row=3, column=0, sticky="ew", pady=(6, 0))

        chunk_frame = ttk.LabelFrame(self.left, text="Chunks", padding=10)
        chunk_frame.grid(row=3, column=0, sticky="nsew", pady=(0, 10))
        chunk_frame.columnconfigure(0, weight=1)
        chunk_frame.rowconfigure(1, weight=1)
        self.left.rowconfigure(3, weight=1)

        self.chunk_filter_var = tk.StringVar()
        ttk.Entry(chunk_frame, textvariable=self.chunk_filter_var).grid(row=0, column=0, sticky="ew", pady=(0, 8))
        self.chunk_list = tk.Listbox(chunk_frame, exportselection=False, height=16)
        self.chunk_list.grid(row=1, column=0, sticky="nsew")

        palette_frame = ttk.LabelFrame(self.left, text="Palette", padding=10)
        palette_frame.grid(row=4, column=0, sticky="nsew")
        palette_frame.columnconfigure(0, weight=1)
        palette_frame.rowconfigure(0, weight=1)
        self.left.rowconfigure(4, weight=1)

        self.palette_list = tk.Listbox(palette_frame, exportselection=False, height=12)
        self.palette_list.grid(row=0, column=0, sticky="nsew")
        for idx, entry in enumerate(OBJECT_LIBRARY):
            self.palette_list.insert("end", f'{entry["category"]}: {entry["name"]}')
            if entry["name"] == self.selected_palette.get():
                self.palette_list.selection_set(idx)

        toolbar = ttk.Frame(self.main)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 10))
        ttk.Button(toolbar, text="Add", command=self.add_element).pack(side="left")
        ttk.Button(toolbar, text="Duplicate", command=self.duplicate_element).pack(side="left", padx=(6, 0))
        ttk.Button(toolbar, text="Delete", command=self.delete_element).pack(side="left", padx=(6, 0))
        ttk.Label(toolbar, text="Zoom").pack(side="left", padx=(16, 6))
        ttk.Scale(toolbar, from_=0.5, to=2.5, variable=self.zoom, command=lambda _v: self.redraw_canvas()).pack(side="left", fill="x", expand=True)

        canvas_frame = ttk.Frame(self.main)
        canvas_frame.grid(row=1, column=0, sticky="nsew")
        canvas_frame.columnconfigure(0, weight=1)
        canvas_frame.rowconfigure(0, weight=1)
        self.main.rowconfigure(1, weight=1)

        self.canvas = tk.Canvas(canvas_frame, bg="#11161c", highlightthickness=1, highlightbackground="#2f404d")
        self.canvas.grid(row=0, column=0, sticky="nsew")

        yscroll = ttk.Scrollbar(canvas_frame, orient="vertical", command=self.canvas.yview)
        yscroll.grid(row=0, column=1, sticky="ns")
        xscroll = ttk.Scrollbar(canvas_frame, orient="horizontal", command=self.canvas.xview)
        xscroll.grid(row=1, column=0, sticky="ew")
        self.canvas.configure(yscrollcommand=yscroll.set, xscrollcommand=xscroll.set)

        inspector = ttk.Frame(self.main)
        inspector.grid(row=1, column=1, sticky="ns", padx=(12, 0))
        inspector.columnconfigure(0, weight=1)

        chunk_props = ttk.LabelFrame(inspector, text="Chunk", padding=10)
        chunk_props.grid(row=0, column=0, sticky="ew")
        chunk_props.columnconfigure(1, weight=1)

        ttk.Label(chunk_props, text="Width").grid(row=0, column=0, sticky="w")
        self.chunk_width_var = tk.StringVar()
        ttk.Entry(chunk_props, textvariable=self.chunk_width_var).grid(row=0, column=1, sticky="ew", pady=2)
        ttk.Label(chunk_props, text="Source Room").grid(row=1, column=0, sticky="w")
        self.chunk_room_var = tk.StringVar()
        ttk.Entry(chunk_props, textvariable=self.chunk_room_var).grid(row=1, column=1, sticky="ew", pady=2)
        ttk.Label(chunk_props, text="Source Start").grid(row=2, column=0, sticky="w")
        self.chunk_start_var = tk.StringVar()
        ttk.Entry(chunk_props, textvariable=self.chunk_start_var).grid(row=2, column=1, sticky="ew", pady=2)

        element_props = ttk.LabelFrame(inspector, text="Selected Element", padding=10)
        element_props.grid(row=1, column=0, sticky="ew", pady=(10, 0))
        element_props.columnconfigure(1, weight=1)

        self.element_object_var = tk.StringVar()
        self.element_object_combo = ttk.Combobox(
            element_props,
            textvariable=self.element_object_var,
            state="readonly",
            values=[entry["name"] for entry in OBJECT_LIBRARY],
        )
        self.element_dx_var = tk.StringVar()
        self.element_dy_var = tk.StringVar()
        self.element_scale_x_var = tk.StringVar()
        self.element_scale_y_var = tk.StringVar()
        self.element_rotation_var = tk.StringVar()

        fields = [
            ("Object", self.element_object_combo),
            ("dx", ttk.Entry(element_props, textvariable=self.element_dx_var)),
            ("dy", ttk.Entry(element_props, textvariable=self.element_dy_var)),
            ("scale_x", ttk.Entry(element_props, textvariable=self.element_scale_x_var)),
            ("scale_y", ttk.Entry(element_props, textvariable=self.element_scale_y_var)),
            ("rotation", ttk.Entry(element_props, textvariable=self.element_rotation_var)),
        ]

        for row, (label, widget) in enumerate(fields):
            ttk.Label(element_props, text=label).grid(row=row, column=0, sticky="w")
            widget.grid(row=row, column=1, sticky="ew", pady=2)

        preview = ttk.LabelFrame(inspector, text="Chunk JSON Preview", padding=10)
        preview.grid(row=2, column=0, sticky="nsew", pady=(10, 0))
        inspector.rowconfigure(2, weight=1)
        preview.columnconfigure(0, weight=1)
        preview.rowconfigure(0, weight=1)

        self.preview_text = tk.Text(preview, width=40, height=24, wrap="none")
        self.preview_text.grid(row=0, column=0, sticky="nsew")
        self.preview_text.configure(state="disabled")

    def _bind_events(self):
        self.chunk_filter_var.trace_add("write", lambda *_: self.refresh_chunk_list())
        self.chunk_list.bind("<<ListboxSelect>>", self.on_chunk_selected)
        self.palette_list.bind("<<ListboxSelect>>", self.on_palette_selected)

        self.chunk_width_var.trace_add("write", lambda *_: self.update_chunk_property("width", self.chunk_width_var.get()))
        self.chunk_room_var.trace_add("write", lambda *_: self.update_chunk_property("source_room", self.chunk_room_var.get()))
        self.chunk_start_var.trace_add("write", lambda *_: self.update_chunk_property("source_start", self.chunk_start_var.get()))

        self.element_object_combo.bind("<<ComboboxSelected>>", lambda _e: self.update_element_property("object_name", self.element_object_var.get()))
        self.element_dx_var.trace_add("write", lambda *_: self.update_element_property("dx", self.element_dx_var.get()))
        self.element_dy_var.trace_add("write", lambda *_: self.update_element_property("dy", self.element_dy_var.get()))
        self.element_scale_x_var.trace_add("write", lambda *_: self.update_element_property("scale_x", self.element_scale_x_var.get()))
        self.element_scale_y_var.trace_add("write", lambda *_: self.update_element_property("scale_y", self.element_scale_y_var.get()))
        self.element_rotation_var.trace_add("write", lambda *_: self.update_element_property("rotation", self.element_rotation_var.get()))

        self.canvas.bind("<Button-1>", self.on_canvas_click)
        self.canvas.bind("<B1-Motion>", self.on_canvas_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_canvas_release)
        self.root.bind("<Delete>", lambda _e: self.delete_element())
        self.root.bind("<BackSpace>", lambda _e: self.delete_element())
        self.root.bind("<Up>", lambda _e: self.nudge_selected(0, -GRID_SIZE))
        self.root.bind("<Down>", lambda _e: self.nudge_selected(0, GRID_SIZE))
        self.root.bind("<Left>", lambda _e: self.nudge_selected(-GRID_SIZE, 0))
        self.root.bind("<Right>", lambda _e: self.nudge_selected(GRID_SIZE, 0))

    def set_status(self, text):
        self.status_var.set(text)

    def load_file(self, path):
        try:
            with open(path, "r", encoding="utf-8-sig") as handle:
                data = json.load(handle)
        except FileNotFoundError:
            self.doc = normalize_doc({"chunk_set": "world1", "chunk_width": 640, "source_rooms": [], "chunks": []})
            self.file_path = Path(path)
            self.set_status(f"File not found yet: {path}. Started with an empty document.")
        except Exception as exc:
            messagebox.showerror("Load Failed", f"Could not load JSON:\n\n{exc}")
            return
        else:
            self.doc = normalize_doc(data)
            self.file_path = Path(path)
            self.set_status(f"Loaded {self.file_path} with {len(self.doc['chunks'])} chunks.")

        self.current_chunk_index = 0 if self.doc["chunks"] else -1
        self.selected_element_index = -1
        self.refresh_all()

    def save_file(self):
        if not self.file_path:
            self.save_file_as()
            return
        self._write_json(self.file_path)

    def save_file_as(self):
        path = filedialog.asksaveasfilename(
            title="Save chunk JSON",
            defaultextension=".json",
            initialfile="world1_chunks.json",
            filetypes=[("JSON Files", "*.json")],
        )
        if path:
            self.file_path = Path(path)
            self._write_json(self.file_path)

    def _write_json(self, path):
        try:
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(self.doc, handle, indent=4)
        except Exception as exc:
            messagebox.showerror("Save Failed", f"Could not save JSON:\n\n{exc}")
            return
        self.set_status(f"Saved {path}")

    def open_file_dialog(self):
        path = filedialog.askopenfilename(
            title="Open chunk JSON",
            initialdir=str(DEFAULT_JSON_PATH.parent),
            filetypes=[("JSON Files", "*.json")],
        )
        if path:
            self.load_file(path)

    def current_chunk(self):
        if self.doc is None:
            return None
        chunks = self.doc["chunks"]
        if 0 <= self.current_chunk_index < len(chunks):
            return chunks[self.current_chunk_index]
        return None

    def current_element(self):
        chunk = self.current_chunk()
        if chunk is None:
            return None
        elements = chunk["elements"]
        if 0 <= self.selected_element_index < len(elements):
            return elements[self.selected_element_index]
        return None

    def refresh_all(self):
        self.refresh_chunk_list()
        self.refresh_fields()
        self.redraw_canvas()
        self.refresh_preview()

    def refresh_chunk_list(self):
        current_selection = self.current_chunk_index
        self.chunk_list.delete(0, "end")
        query = self.chunk_filter_var.get().strip().lower()

        if not self.doc:
            return

        visible_index = None
        for index, chunk in enumerate(self.doc["chunks"]):
            label = f'#{index} {chunk.get("source_room", "custom")} @ {chunk.get("source_start", 0)} • width {chunk["width"]} • {len(chunk["elements"])} elements'
            if query and query not in label.lower():
                continue
            if index == current_selection:
                visible_index = self.chunk_list.size()
            self.chunk_list.insert("end", label)

        if visible_index is not None:
            self.chunk_list.selection_set(visible_index)

    def refresh_fields(self):
        self.updating_fields = True
        chunk = self.current_chunk()
        element = self.current_element()

        if chunk:
            self.chunk_width_var.set(str(chunk.get("width", "")))
            self.chunk_room_var.set(str(chunk.get("source_room", "")))
            self.chunk_start_var.set(str(chunk.get("source_start", 0)))
        else:
            self.chunk_width_var.set("")
            self.chunk_room_var.set("")
            self.chunk_start_var.set("")

        if element:
            self.element_object_var.set(element["object_name"])
            self.element_dx_var.set(self._num_to_text(element["dx"]))
            self.element_dy_var.set(self._num_to_text(element["dy"]))
            self.element_scale_x_var.set(self._num_to_text(element["scale_x"]))
            self.element_scale_y_var.set(self._num_to_text(element["scale_y"]))
            self.element_rotation_var.set(self._num_to_text(element["rotation"]))
        else:
            self.element_object_var.set(self.selected_palette.get())
            self.element_dx_var.set("")
            self.element_dy_var.set("")
            self.element_scale_x_var.set("")
            self.element_scale_y_var.set("")
            self.element_rotation_var.set("")

        self.updating_fields = False

    def refresh_preview(self):
        self.preview_text.configure(state="normal")
        self.preview_text.delete("1.0", "end")
        chunk = self.current_chunk()
        if chunk:
            self.preview_text.insert("1.0", json.dumps(chunk, indent=4))
        elif self.doc:
            self.preview_text.insert("1.0", json.dumps(self.doc, indent=4))
        self.preview_text.configure(state="disabled")

    def world_height(self, chunk):
        if not chunk:
            return DEFAULT_CANVAS_HEIGHT
        max_y = DEFAULT_CANVAS_HEIGHT
        for element in chunk["elements"]:
            meta = OBJECT_MAP.get(element["object_name"], {"w": 16, "h": 16})
            height = max(GRID_SIZE, abs(element["scale_y"]) * meta["h"])
            max_y = max(max_y, element["dy"] + height + GRID_SIZE * 2)
        return int(math.ceil(max_y / GRID_SIZE) * GRID_SIZE)

    def redraw_canvas(self):
        self.canvas.delete("all")
        self.canvas_items.clear()

        chunk = self.current_chunk()
        width = int(chunk["width"]) if chunk else 640
        height = self.world_height(chunk)
        zoom = self.zoom.get()
        self.canvas.configure(scrollregion=(0, 0, width * zoom, height * zoom))

        for x in range(0, width + GRID_SIZE, GRID_SIZE):
            color = "#32424f" if x % (GRID_SIZE * 4) == 0 else "#24323d"
            self.canvas.create_line(x * zoom, 0, x * zoom, height * zoom, fill=color)
        for y in range(0, height + GRID_SIZE, GRID_SIZE):
            color = "#32424f" if y % (GRID_SIZE * 4) == 0 else "#24323d"
            self.canvas.create_line(0, y * zoom, width * zoom, y * zoom, fill=color)

        if not chunk:
            return

        for index, element in enumerate(chunk["elements"]):
            meta = OBJECT_MAP.get(element["object_name"], {"color": "#90a4ae", "w": 16, "h": 16})
            rect_w = max(GRID_SIZE, abs(element["scale_x"]) * meta["w"])
            rect_h = max(GRID_SIZE, abs(element["scale_y"]) * meta["h"])
            x1 = element["dx"] * zoom
            y1 = element["dy"] * zoom
            x2 = (element["dx"] + rect_w) * zoom
            y2 = (element["dy"] + rect_h) * zoom

            outline = "#ffffff" if index == self.selected_element_index else "#0c1217"
            line_width = 3 if index == self.selected_element_index else 1
            tag = f"element_{index}"
            self.canvas.create_rectangle(x1, y1, x2, y2, fill=meta["color"], outline=outline, width=line_width, tags=(tag, "element"))
            self.canvas.create_text((x1 + x2) / 2, (y1 + y2) / 2, text=element["object_name"], width=max(70, rect_w * zoom - 6), fill="#081118", tags=(tag, "element"))
            self.canvas_items[tag] = index

    def element_at_point(self, x, y):
        chunk = self.current_chunk()
        if not chunk:
            return None
        for index in range(len(chunk["elements"]) - 1, -1, -1):
            element = chunk["elements"][index]
            meta = OBJECT_MAP.get(element["object_name"], {"w": 16, "h": 16})
            rect_w = max(GRID_SIZE, abs(element["scale_x"]) * meta["w"])
            rect_h = max(GRID_SIZE, abs(element["scale_y"]) * meta["h"])
            if element["dx"] <= x <= element["dx"] + rect_w and element["dy"] <= y <= element["dy"] + rect_h:
                return index
        return None

    def on_canvas_click(self, event):
        zoom = self.zoom.get()
        world_x = self.canvas.canvasx(event.x) / zoom
        world_y = self.canvas.canvasy(event.y) / zoom
        hit = self.element_at_point(world_x, world_y)

        if hit is not None:
            self.selected_element_index = hit
            element = self.current_element()
            self.dragging = {
                "offset_x": world_x - element["dx"],
                "offset_y": world_y - element["dy"],
                "snap": not bool(event.state & 0x0001),
            }
        else:
            self.add_element(dx=snap(world_x), dy=snap(world_y))
            self.dragging = {
                "offset_x": 0,
                "offset_y": 0,
                "snap": True,
            }

        self.refresh_all()

    def on_canvas_drag(self, event):
        if not self.dragging:
            return
        element = self.current_element()
        if not element:
            return

        zoom = self.zoom.get()
        world_x = self.canvas.canvasx(event.x) / zoom
        world_y = self.canvas.canvasy(event.y) / zoom
        dx = world_x - self.dragging["offset_x"]
        dy = world_y - self.dragging["offset_y"]

        if self.dragging["snap"]:
            dx = snap(dx)
            dy = snap(dy)

        element["dx"] = dx
        element["dy"] = dy
        self.refresh_fields()
        self.redraw_canvas()
        self.refresh_preview()

    def on_canvas_release(self, _event):
        self.dragging = None

    def on_chunk_selected(self, _event):
        visible = self.chunk_list.curselection()
        if not visible or not self.doc:
            return

        query = self.chunk_filter_var.get().strip().lower()
        actual_index = None
        current_visible = -1
        for index, chunk in enumerate(self.doc["chunks"]):
            label = f'#{index} {chunk.get("source_room", "custom")} @ {chunk.get("source_start", 0)} • width {chunk["width"]} • {len(chunk["elements"])} elements'
            if query and query not in label.lower():
                continue
            current_visible += 1
            if current_visible == visible[0]:
                actual_index = index
                break

        if actual_index is None:
            return

        self.current_chunk_index = actual_index
        self.selected_element_index = -1
        self.refresh_all()

    def on_palette_selected(self, _event):
        selection = self.palette_list.curselection()
        if not selection:
            return
        self.selected_palette.set(OBJECT_LIBRARY[selection[0]]["name"])
        if not self.current_element():
            self.refresh_fields()

    def add_element(self, dx=None, dy=None):
        chunk = self.current_chunk()
        if not chunk:
            return

        if dx is None:
            dx = snap(chunk["width"] * 0.5)
        if dy is None:
            dy = snap(self.world_height(chunk) * 0.5)

        chunk["elements"].append(
            {
                "object_name": self.selected_palette.get(),
                "dx": dx,
                "dy": dy,
                "scale_x": 1.0,
                "scale_y": 1.0,
                "rotation": 0.0,
            }
        )
        self.selected_element_index = len(chunk["elements"]) - 1
        self.refresh_all()

    def duplicate_element(self):
        element = self.current_element()
        chunk = self.current_chunk()
        if not element or not chunk:
            return
        clone = deep_copy_json(element)
        clone["dx"] += GRID_SIZE
        clone["dy"] += GRID_SIZE
        chunk["elements"].append(clone)
        self.selected_element_index = len(chunk["elements"]) - 1
        self.refresh_all()

    def delete_element(self):
        chunk = self.current_chunk()
        if not chunk or self.selected_element_index < 0:
            return
        del chunk["elements"][self.selected_element_index]
        self.selected_element_index = min(self.selected_element_index, len(chunk["elements"]) - 1)
        self.refresh_all()

    def update_chunk_property(self, key, value):
        if self.updating_fields:
            return
        chunk = self.current_chunk()
        if not chunk:
            return

        if key == "width":
            parsed = self._parse_int(value)
            if parsed is None:
                return
            chunk[key] = parsed
        elif key == "source_start":
            parsed = self._parse_int(value)
            if parsed is None:
                return
            chunk[key] = parsed
        else:
            chunk[key] = value

        self.refresh_chunk_list()
        self.redraw_canvas()
        self.refresh_preview()

    def update_element_property(self, key, value):
        if self.updating_fields:
            return
        element = self.current_element()
        if not element:
            return

        if key == "object_name":
            element[key] = value
        else:
            parsed = self._parse_float(value)
            if parsed is None:
                return
            element[key] = parsed

        self.redraw_canvas()
        self.refresh_preview()

    def nudge_selected(self, dx, dy):
        element = self.current_element()
        if not element:
            return
        element["dx"] += dx
        element["dy"] += dy
        self.refresh_fields()
        self.redraw_canvas()
        self.refresh_preview()

    @staticmethod
    def _parse_int(value):
        if value == "":
            return None
        try:
            return int(float(value))
        except ValueError:
            return None

    @staticmethod
    def _parse_float(value):
        if value == "":
            return None
        try:
            return float(value)
        except ValueError:
            return None

    @staticmethod
    def _num_to_text(value):
        if abs(value - round(value)) < 0.0001:
            return str(int(round(value)))
        return f"{value:.3f}".rstrip("0").rstrip(".")


def main():
    root = tk.Tk()
    try:
        style = ttk.Style(root)
        if "vista" in style.theme_names():
            style.theme_use("vista")
    except Exception:
        pass
    editor = ChunkEditor(root)
    root.mainloop()
    return editor


if __name__ == "__main__":
    main()
