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

hl.window_rule({
  name = "windowrule-2",
  match = { class = "^(kitty)$" },
  opacity = "1.0 1.0",
})

hl.window_rule({
  name = "kittyfloat-opacity",
  match = { class = "^(kittyfloat)$" },
  opacity = "1.0 1.0",
})

floating_centered_rule(
  "kittyfloat-main",
  { class = "^(kittyfloat)$" },
  { "monitor_w*0.4", "monitor_h*0.6" }
)

floating_centered_rule(
  "windowrule-1b",
  { class = "^(kitty)$" },
  { "monitor_w*0.4", "monitor_h*0.6" }
)

floating_centered_rule(
  "windowrule-1",
  { initial_class = "^(kitty)$" },
  { "monitor_w*0.4", "monitor_h*0.6" }
)

floating_centered_rule(
  "picture-in-picture-initial-class",
  { initial_class = "^(Picture-in-Picture)$" },
  { "monitor_w*0.4", "monitor_h*0.6" }
)

floating_centered_rule(
  "smallWindow",
  { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|Zotero)$" },
  { "monitor_w*0.45", "monitor_h*0.45" }
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
  { "monitor_w*0.32", "monitor_h*0.28" }
)

floating_centered_rule(
  "hyprpolkitagent-initial",
  { initial_class = "^(hyprpolkitagent)$" },
  { "monitor_w*0.32", "monitor_h*0.28" }
)
