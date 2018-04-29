require 'utils'
require 'action'
require 'hardware'

cfg = require 'config'

---------------------
--  Reload config  --
---------------------

function reloadConfig(files)
  doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then

    if hardware then
      hardware.stop()
    end
    if screenWatcher then
      screenWatcher:stop()
    end
    if appWatcher then
      appWatcher:stop()
    end
    configWatcher:stop()

    hs.reload()
    hs.notify.new( {title='Hammerspoon', subTitle='Configuration reloaded'} ):send()
  end
end
configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
configWatcher:start()

if not cfg then
  error("Missing 'config.lua'. Copy and edit 'example-config.lua' to create your own configuration.")
end

---------------------------
--  Application Watcher  --
---------------------------

function arrangeOrWait(app, layout, tries)
  return function()
    if tries > 0 and #app:allWindows() == 0 then
      hs.timer.doAfter(0.1, arrangeOrWait(app, layout, tries -1 ))
    else
      arrange(app, layout)
    end
  end
end

function applicationWatcher(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    if (appName == "Finder") then
      appObject:selectMenuItem({"Window", "Bring All to Front"})
    end
  end

  -- layout a launched app if it's in the layout list
  if (eventType == hs.application.watcher.launched) then
    local layout = currentLayout()
    if layout[appName] then
      local app = hs.application.find(appName)
      arrangeOrWait(app, layout, 30)() -- will wait for max 3 seconds
    end
  end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

--------------------
--  Window Layout --
--------------------

function arrange(app, layout)
  local actions = layout[app:title()]
  local mainWindow = app:mainWindow()
  if not actions or not mainWindow or not mainWindow:isStandard() then return end

  for _, action in pairs(actions) do action(mainWindow) end
end

function currentLayout()
  local layout = cfg.singleLayout
  if (#hs.screen.allScreens() > 1) then
    layout = cfg.dualLayout
  end
  return layout
end

function layout()
  for _, app in pairs(hs.application.runningApplications()) do arrange(app, currentLayout()) end
end


function dumpLayout()
  local layout = "local myLayout = {\n"
  local first = true
  for _, app in pairs(hs.application.runningApplications()) do
    local mainWindow = app:mainWindow()
    if mainWindow and mainWindow:isStandard() then
      if not first then
        layout = layout .. ",\n"
      end
      first = false
      local frame = mainWindow:frame()
      layout = layout .. string.format("  [\"%s\"] = { Action.Frame(%d, %d, %d, %d) }", app:title(), frame.x, frame.y, frame.w, frame.h)
    end
  end
  layout = layout .. "\n}"
  hs.pasteboard.setContents(layout)
  print(layout)
end

----------------------
--  Screen Watcher  --
----------------------

function screenWatcher()
  if cfg.manageBluetooth then
    local blueutil = "/usr/local/bin/blueutil"
    if (#hs.screen.allScreens() == 1) then
      os.execute(blueutil .. " -p 0")
    else
      os.execute(blueutil .. " -p 1")
    end
  end
  layout()
end
screenWatcher = hs.screen.watcher.new(screenWatcher)
screenWatcher:start()

---------------------------------------------
--  hammerspoon://devopen?url=http://....  --
---------------------------------------------

hs.urlevent.bind("devopen", function(event, params)
  local url = params.url
  local browser = utils.focusBrowser()
  hs.eventtap.keyStroke({ "cmd" }, "n")
  hs.timer.doAfter(1.0, function()
    browser:activate()
    hs.eventtap.keyStroke({ "cmd" }, "l")
    hs.eventtap.keyStrokes(url)
    hs.eventtap.keyStroke( {}, "return")
    local window = browser:focusedWindow()
    window:moveOneScreenWest() window:moveToUnit(hs.layout.right75)
  end)
end)


------------------------------------------------------------
--  hammerspoon://notify?title=...&subtitle=...&info=...  --
------------------------------------------------------------

hs.urlevent.bind("notify", function(event, params)
  utils.notify(params.title, params.subtitle, params.info)
end)


------------------
--  Keymapings  --
------------------

hs.hotkey.bind(cfg.mash, 'l', layout)
hs.hotkey.bind(cfg.mash, 'r', hs.reload)
hs.hotkey.bind(cfg.mash, 'd', dumpLayout)
hs.hotkey.bind(cfg.mash, 'b', function() hardware.showBatteryStatus(true) end)
hs.hotkey.bind(cfg.mash, "h", hs.hints.windowHints)
hs.hotkey.bind(cfg.mash, "m", function() 
  -- insert email address at current cursor position
  hs.eventtap.keyStrokes(cfg.email)
end)

hardware.start() -- enable hardware notifications
layout() -- layout windows after start
