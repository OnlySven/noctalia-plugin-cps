--!nonstrict
-- CPS Counter - left/right mouse clicks per second, always visible in the bar.
--
-- scripts/cps.py reads every mouse evdev node and streams "<left> <right>" lines
-- whenever the 1-second sliding-window counts change; this widget only renders.
-- The stream callback just records the counts: a render() tree is only redrawn
-- from update() (or on hover/click), so update() polls a dirty flag instead.
-- Click the widget to reset the session peak shown in the tooltip. On a vertical
-- bar the glyph and the two counts are stacked so they fit the bar width.

local left, right = 0, 0
local peakLeft, peakRight = 0, 0
local dirty = true

local function render()
  if barWidget.isVertical() then
    -- A side bar is only a few characters wide, so stack the counts.
    barWidget.render(ui.column({ gap = 2, align = "center" }, {
      ui.glyph({ name = "mouse" }),
      ui.label({ text = `L{left}`, maxLines = 1 }),
      ui.label({ text = `R{right}`, maxLines = 1 }),
    }))
  else
    barWidget.setGlyph("mouse")
    barWidget.setText(`L {left}  R {right}`)
  end
  barWidget.setTooltip(`CPS - left {left}, right {right}\nPeak: left {peakLeft}, right {peakRight}\nClick to reset peak`)
end

local function onLine(line)
  local l, r = line:match("^(%d+) (%d+)")
  if l == nil then
    return
  end
  left, right = tonumber(l), tonumber(r)
  peakLeft = math.max(peakLeft, left)
  peakRight = math.max(peakRight, right)
  dirty = true
end

local script = (noctalia.pluginDir() or ".") .. "/scripts/cps.py"
local command = "exec python3 -I -u '" .. script:gsub("'", "'\\''") .. "'"
if not noctalia.runStream(command, onLine) then
  noctalia.notifyError("CPS Counter", "Unable to start the mouse reader")
end

noctalia.setUpdateInterval(100)

function update()
  if dirty then
    dirty = false
    render()
  end
end

function onClick()
  peakLeft, peakRight = left, right
  dirty = true
end
