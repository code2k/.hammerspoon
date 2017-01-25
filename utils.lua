utils = {}
utils.__index = utils

local fixBundle = {
  ["com.google.chrome"] = "com.google.Chrome",
  ["com.apple.safari"] = "com.apple.Safari",
}


-- Open and focus the default browser.
-- @return browser instance
function utils.focusBrowser()
  local defaultBrowser = hs.urlevent.getDefaultHandler("http")
  -- Bundle ID returned for Chrome and Safari is wrong
  -- Use fixBundle table to correct it.
  browserBundleID = fixBundle[defaultBrowser]
  if not browserBundleID then
    browserBundleID = defaultBrowser
  end
  local browser = hs.application.open(browserBundleID, 1, true)
  browser:activate()
  return browser
end


function utils.notify(title, subTitle, info, tag)
  local params = {
    title = title,
    subTitle= subTitle,
    informativeText = info
  }
  local notify = hs.notify.new(tag, params)
  notify:send()
end


function utils.pushToScreen(win, screen)
  local screen = screen or win:screen()
  if screen == win:screen() then return end

  local fullscreenChange = win:isFullScreen()
  if fullscreenChange then
    id = win:id()
    win:toggleFullScreen()
    os.execute('sleep 3')
    win = hs.window.windowForID(id)
    if not win then return end
  end

  win:moveToScreen(screen)

  if fullscreenChange then win:toggleFullScreen() end
end


return utils
