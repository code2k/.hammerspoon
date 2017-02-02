require 'utils'

hardware = {}
hardware._index = hardware

hardwareWatchers = {
  battery = nil,
  volumes = nil,
  usb = nil,
  wifi = nil,
  network = nil
}


local log = hs.logger.new("hardware")

local currentWifi = hs.wifi.currentNetwork()

---------------
--  Helpers  --
---------------

local function basename(str)
  local name = string.gsub(str, "(.*/)(.*)", "%2")
  return name
end


local function timeRemainingString(minutes)
  local hours = math.floor(minutes/60)
  local rest = minutes % 60
  if hours == 0 then
    return string.format("%0.f minutes", rest)
  else
    return string.format("%d:%.2d hours", hours, rest)
  end
end


-----------------------------
--  Battery Notifications  --
-----------------------------

local batteryState = nil


local function initBattery()
  batteryState = hs.battery.getAll()
end


local function notifyBattery(showOnScreen)
  local chargeInfo
  if batteryState.isCharging then
    chargeInfo = "Charging"
  elseif batteryState.isCharged == true then
    chargeInfo = "Charged"
  else
    chargeInfo = ""
  end

  local subtitle = string.format("Battery: %s at %0.f%%", chargeInfo, batteryState.percentage)

  local additional
  if batteryState.timeRemaining > 0 then
    additional = string.format("Time remaining: %s", timeRemainingString(batteryState.timeRemaining))
  end

  if not showOnScreen then
    -- display system notification
    utils.notify("On " .. batteryState.powerSource, subtitle, additional)
  else
    -- display on screen notification
    local statusText = string.format("On %s\n%s", batteryState.powerSource, subtitle)
    if additional then
      statusText = string.format("%s\n%s", statusText, additional)
    end
    hs.alert(statusText, 4)
  end
end


local onBatteryChange = function()
  local oldState = batteryState
  batteryState = hs.battery.getAll()

  log.d(hs.inspect(batteryState))

  if oldState.powerSource ~= batteryState.powerSource then
    -- battery <> AC change
    notifyBattery()
  elseif oldState.isCharged == false and batteryState.isCharged then
    -- battery fully charged
    notifyBattery()
  elseif oldState.timeRemaining < 0 and batteryState.timeRemaining > 0 then
    -- battery remaining time calculation finished
    notifyBattery()
  end
end


----------------------------
--  Volume Notifications  --
----------------------------

local onVolumeChange = function(event, info)
  if event == hs.fs.volume.didMount then
    -- register callback for "Click to open"
    hs.notify.register(info.path, function() os.execute("open " .. info.path) end)

    utils.notify(basename(info.path) .. " Mounted", "Click to open", nil, info.path)
  elseif event == hs.fs.volume.didUnmount then
    -- remove callback for this path
    hs.notify.unregister(info.path)

    utils.notify(basename(info.path) .. " Unmounted")
  end
end


-------------------------
--  USB Notifications  --
-------------------------

local onUSBChange = function(info)
  if info.productName and info.productName ~= "" then
    local event = (info.eventType == "added") and "USB Connection" or "USB Disconnection"
    utils.notify(event, string.format("%s / %s", info.productName, info.vendorName))
  end
end


--------------------------
--  WiFi Notifications  --
--------------------------

local onWifiChange = function()
  if not hs.wifi.currentNetwork() then
    -- no wifi connection found
    if currentWifi then
      log.d("wifi disconnect: " .. currentWifi)
      utils.notify("WiFi Disconnection", currentWifi)
      currentWifi = nil
    end
  else
    local info = hs.wifi.interfaceDetails()
    currentWifi = string.format("%s (%s)", hs.wifi.currentNetwork(), info.bssid)
    log.d("wifi connect: " .. currentWifi)
    utils.notify("WiFi Connection", currentWifi, info.security)
  end
end


-----------------------------
--  Network Notifications  --
-----------------------------

local KEY_IPV4 = "State:/Network/Interface/en1/IPv4"

local onIPChange = function(configuration, keys)
  local ipv4Table = configuration:contents(KEY_IPV4)
  if next(ipv4Table) == nil then
    utils.notify("IP address released")
  else
    local ipv4 = ipv4Table[KEY_IPV4]
    local ip = ipv4.Addresses[1]
    utils.notify("IP address acquired", ip)
  end
end


-------------------------
--  Lifecycle Methods  --
-------------------------

local function startAll()
  for w,_ in pairs(hardwareWatchers) do
    if hardwareWatchers[w] then
      log.i("Starting watcher for " .. w)
      hardwareWatchers[w]:start()
    end
  end
end

local function stopAll()
  for w,_ in pairs(hardwareWatchers) do
    if hardwareWatchers[w] then
      log.i("Stopping watcher for " .. w)
      hardwareWatchers[w]:stop()
    end
  end
end

function hardware.start()
  local cfg = cfg.notifications

  if cfg.enableBattery then
    initBattery()
    hardwareWatchers.battery = hs.battery.watcher.new(onBatteryChange)
  end
  if cfg.enableVolumes then
    hardwareWatchers.volumes = hs.fs.volume.new(onVolumeChange)
  end
  if cfg.enableUsb then
    hardwareWatchers.usb = hs.usb.watcher.new(onUSBChange)
  end
  if cfg.enableWifi then
    hardwareWatchers.wifi = hs.wifi.watcher.new(onWifiChange)
  end
  if cfg.enableNetwork then
    hardwareWatchers.network = hs.network.configuration.open()
    hardwareWatchers.network:setCallback(onIPChange)
    hardwareWatchers.network:monitorKeys(KEY_IPV4)
  end

  startAll()
end

function hardware.stop()
  stopAll()
end


function hardware.showBatteryStatus(showOnScreen)
  notifyBattery(showOnScreen)
end

return hardware
