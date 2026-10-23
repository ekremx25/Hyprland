-- Window rules converted from custom/rules.conf.

local function floating_centered_rule(name, match, size)
  hl.window_rule({
    name = name,
    match = match,
    float = true,
    size = size,
    center = true,
  })
end

-- Normal kitty: keep tiled, only force opacity.
hl.window_rule({
  name = "kitty-opacity",
  match = { class = "^(kitty)$" },
  opacity = "1.0 1.0",
})

-- Special floating kitty. Launch with:
--   kitty --class kittyfloat
hl.window_rule({
  name = "kittyfloat-opacity",
  match = { class = "^(kittyfloat)$" },
  opacity = "1.0 1.0",
})

-- Kitty owns the initial size in the SUPER+Enter command. These rules only
-- make that window floating and center the size requested by Kitty.
hl.window_rule({
  name = "kittyfloat-main",
  match = { class = "^(kittyfloat)$" },
  float = true,
  center = true,
})

-- Some clients are matched more reliably by initial_class.
hl.window_rule({
  name = "kittyfloat-initial",
  match = { initial_class = "^(kittyfloat)$" },
  float = true,
  center = true,
})

floating_centered_rule(
  "picture-in-picture-initial-class",
  { initial_class = "^(Picture-in-Picture)$" },
  { "(monitor_w*0.4)", "(monitor_h*0.6)" }
)

floating_centered_rule(
  "smallWindow",
  { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|Zotero)$" },
  { "(monitor_w*0.45)", "(monitor_h*0.45)" }
)

hl.window_rule({
  name = "pictureInPicture-SecondMonitor",
  match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
  float = true,
  pin = true,
  size = { 1200, 675 },
  move = { 2860, 300 },
})

floating_centered_rule(
  "hyprpolkitagent",
  { class = "^(hyprpolkitagent)$" },
  { "(monitor_w*0.32)", "(monitor_h*0.28)" }
)

floating_centered_rule(
  "hyprpolkitagent-initial",
  { initial_class = "^(hyprpolkitagent)$" },
  { "(monitor_w*0.32)", "(monitor_h*0.28)" }
)

-- Edge-only saturation trial (removed 16 Oct 2026 to roll back).
-- Requires the saturation window rule from the hdr3.edge3 build.
hl.window_rule({
  name = "edge-saturation-trial",
  match = { class = "^(microsoft-edge)$" },
  saturation = "1.08",
})
