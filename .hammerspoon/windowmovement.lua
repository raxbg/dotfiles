hs.hotkey.bind({"cmd", "alt"}, "Right", function()
    local win = hs.window.focusedWindow();
    win:moveOneScreenEast();
end)

hs.hotkey.bind({"cmd", "alt"}, "Left", function()
    local win = hs.window.focusedWindow();
    win:moveOneScreenWest();
end)
