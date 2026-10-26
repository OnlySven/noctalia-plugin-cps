--!nonstrict
-- CPS Counter - left/right mouse clicks per second, always visible in the bar.
--
-- scripts/cps.py reads every mouse evdev node and streams "<left> <right>" lines
-- whenever the 1-second sliding-window counts change; this widget only renders.
-- Click the widget to reset the session peak shown in the tooltip.

local left, right = 0, 0
local peakLeft, peakRight = 0, 0

local function render()
  barWidget.setGlyph("mouse")
  barWidget.setText(`L {left}  R {right}`)
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
  render()
end

local script = (noctalia.pluginDir() or ".") .. "/scripts/cps.py"
local command = "exec python3 -I -u '" .. script:gsub("'", "'\\''") .. "'"
if not noctalia.runStream(command, onLine) then
  noctalia.notifyError("CPS Counter", "Unable to start the mouse reader")
end

render()

function update()
  noctalia.setUpdateInterval(60000)
end

function onClick()
  peakLeft, peakRight = left, right
  render()
end
