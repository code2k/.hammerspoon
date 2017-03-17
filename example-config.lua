--
-- copy this file fo 'config.lua' and edit as needed
--

local cfg = {}


cfg.mash = {'ctrl', 'alt', 'cmd'}


----------------------------
--  Hammerspoon settings  --
----------------------------

hs.window.animationDuration = 0 -- disable animations
hs.menuIcon(false)
hs.consoleOnTop(true)

--hs.hints.fontName = "DejaVu Sans Mono"
hs.hints.fontSize = 14
hs.hints.showTitleThresh = 8


---------------------
--  EMail address  --
---------------------

cfg.email = "jsmith@example.com"


---------------
--  Layouts  --
---------------

cfg.dualLayout = {
  ["Safari"] = { Action.MoveToScreen(1), Action.MoveToUnit(0.125, 0, 0.75, 1) },
  ["iTunes"] = { Action.MoveToScreen(2), Action.Maximize() },
  ["iTerm2"] = {  Action.MoveToScreen(2), Action.MoveToUnit(0.05, 0.04, 0.9, 0.9)  },
  ["Mail"] = { Action.MoveToScreen(2), Action.Maximize() },
  ["Twitter"] = {  Action.MoveToScreen(1), Action.MoveToUnit(hs.layout.left25)  },
  ["VLC"] = { Action.MoveToScreen(1), Action.Resize(200, 150), Action.PositionBottomRight() },
  ["Xcode"] = { Action.MoveToScreen(1), Action.Maximize() }
}

cfg.singleLayout = {
  ["Safari"] = { Action.MoveToScreen(1), Action.Maximize() },
  ["iTunes"] = { Action.MoveToScreen(1), Action.Maximize() },
  ["Mail"] = { Action.MoveToScreen(1), Action.Maximize() },
  ["Things"] = { Action.MoveToScreen(1), Action.MoveToUnit(hs.layout.right75) },
  ["Twitter"] = { Action.MoveToScreen(1), Action.MoveToUnit(hs.layout.left25)  },
  ["VLC"] = { Action.MoveToScreen(1), Action.Resize(200, 150), Action.PositionBottomRight() },
  ["Xcode"] = { Action.MoveToScreen(1), Action.Maximize() }
}


------------------------------
--  Hardware Notifications  --
------------------------------

cfg.notifications = {
  enableBattery = true,
  enableVolumes = true,
  enableUsb = true,
  enableWifi = true,
  enableNetwork = true
}


----------------------------------------------------------------------
--  Automatically enable / disable Bluetooth on monitor connection  --
--  Requires https://github.com/toy/blueutil                        --
----------------------------------------------------------------------

cfg.manageBluetooth = false


return cfg
