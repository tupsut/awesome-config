-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local vicious = require("vicious")

local debug = false

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Errors during startup:",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Error:",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey = "Mod4"

function run_once(prg,arg_string,pname,screen)
    if not prg then
        do return nil end
    end

    if not pname then
       pname = prg
    end

    if not arg_string then 
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. ")",screen)
    else
        awful.util.spawn.with_shell("pgrep -f -u $USER -x '" .. pname .. " ".. arg_string .."' || (" .. prg .. " " .. arg_string .. ")",screen)
    end
end

--run_once("xbindkeys")

-- {{{ Autostart (only for processes with a unique proc id)
run_once("cbatticon")
run_once("dropbox")
run_once("nm-applet")
run_once("keepass")
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/home/tupsu/.config/awesome/themes/zenburn/theme.lua")

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,         --1
    awful.layout.suit.tile,             --2
    --awful.layout.suit.tile.left,
    --awful.layout.suit.tile.bottom,
    --awful.layout.suit.tile.top,
    --awful.layout.suit.corner.nw,
    --awful.layout.suit.fair,           
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,              --3
    --awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper_space then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper_space, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which holds all screen tags.
local tags
do
    local l = layouts
    local tile = awful.layout.suit.tile
    local lmax = awful.layout.suit.max
    -- The ordering of these items determines layout and client priority
    tags = {
        -- layouts in top-bar have to come first in indices (depends on hotkey-stuff)
        names = {
            "A",
            "Toggle",
            "1",        "2",        "3",    "4-www",
            "Q",        "W",        "E",
                        "S",       "D",    "G-stash" },
        layout = {
            lmax,
            tile,
            tile,       lmax,       lmax,   lmax,
            tile,       lmax,       lmax,
            lmax,       lmax,   lmax },
        wibox_id = {
            "bottom",
            "top_2_r",
            "top_1",    "top_1",    "top_1",    "top_1",
            "top_2",    "top_2",    "top_2",
            "bottom",   "bottom",   "bottom" },
        bg = beautiful.wallpaper_space
    }
end

-- Create a tag table for every screen
for s = 1, screen.count() do
    tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
    { "manual", terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. "~/.config/awesome/rc.lua" },
    { "suspend", function() awful.util.spawn.with_shell("pm-suspend") end },
    { "restart", awesome.restart },
    { "quit", awesome.quit }
}
-- Create a application startup menu

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
top_wibox = {}
bottom_wibox = {}
mypromptbox = {}
mylayoutbox = {}
top_taglist_1 = {}
top_taglist_2 = {}
top_taglist_2_r = {}
bottom_taglist = {}
taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))
-- Custom function for filtering tags
function filter_wibox_id(t, args, wibox_id)
    for i = 1, #tags.names do
        if (tags.names[i] == t.name) then
            if (tags.wibox_id[i] == wibox_id) then
                return true;
            end
            return false
        end
    end
    return false
end
function filter_wibox_bottom(t, args)
    return filter_wibox_id(t, args, "bottom")
end
function filter_wibox_top_1(t, args)
    return filter_wibox_id(t, args, "top_1")
end
function filter_wibox_top_2(t, args)
    return filter_wibox_id(t, args, "top_2")
end
function filter_wibox_top_2_right(t, args)
    return filter_wibox_id(t, args, "top_2_r")
end

-- Create widgets in all screens
for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create taglist widgets
    top_taglist_1[s] = awful.widget.taglist(s, filter_wibox_top_1, taglist_buttons)
    top_taglist_2[s] = awful.widget.taglist(s, filter_wibox_top_2, taglist_buttons)
    top_taglist_2_r[s] = awful.widget.taglist(s, filter_wibox_top_2_right, taglist_buttons)
    bottom_taglist[s] = awful.widget.taglist(s, filter_wibox_bottom, taglist_buttons)
    --top_taglist_1[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibars
    top_wibox[s] = awful.wibar({ position = "top", height = 25, screen = s })
    bottom_wibox[s] = awful.wibar({ position = "bottom", screen = s })

    -- Create the textboxes for the tasks (<tt> == monospace)
    local task1_tb = wibox.widget.textbox("<tt>Code 1: </tt>")
    local task2_tb = wibox.widget.textbox("<tt>Task 2: </tt>")
    local task3_tb = wibox.widget.textbox("<tt>Task 3: </tt>")

    -- Create two layouts at the top-left corner of the screen...
    local upper_left_layout_1 = wibox.layout.fixed.horizontal()
    upper_left_layout_1:add(task1_tb)
    upper_left_layout_1:add(top_taglist_1[s])

    local upper_left_layout_2 = wibox.layout.fixed.horizontal()
    upper_left_layout_2:add(task2_tb)
    upper_left_layout_2:add(top_taglist_2[s])
    upper_left_layout_2:add(top_taglist_2_r[s])

    -- ... and set them up in a vertical layout ...
    local upper_left_vlayout = wibox.layout.fixed.vertical()
    upper_left_vlayout:add(upper_left_layout_1)
    upper_left_vlayout:add(upper_left_layout_2)

    -- ... and set that up in a horizontal layout
    local upper_left_hlayout = wibox.layout.fixed.horizontal()
    upper_left_hlayout:add(upper_left_vlayout)
    upper_left_hlayout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Combine top wibar layout
    local top_wibox_layout = wibox.layout.align.horizontal()
    top_wibox_layout:set_left(upper_left_hlayout)
    top_wibox_layout:set_right(right_layout)
    top_wibox[s]:set_widget(top_wibox_layout)

    -- Lowbox widgets that are aligned to the left
    local lower_left_layout = wibox.layout.fixed.horizontal()
    lower_left_layout:add(task3_tb)
    lower_left_layout:add(bottom_taglist[s])
    
    local right_layout_bot = wibox.layout.fixed.horizontal()
    right_layout_bot:add(mylauncher)
    
    local layout_bot = wibox.layout.align.horizontal()
    layout_bot:set_left(lower_left_layout)
    layout_bot:set_middle(mytasklist[s])
    layout_bot:set_right(right_layout_bot)

    bottom_wibox[s]:set_widget(layout_bot)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    --awful.key({ modkey,           }, "w", function () mymainmenu:show() end), -- mod+w replaced by tag W hotkeys

    -- Layout manipulation
    awful.key({ modkey, "Control"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Control"   }, "k", function () awful.client.swap.byidx( -1)    end),
    --awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    --awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "space",  function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Control", "Shift" }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "x",     function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey,           }, "z",     function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Brightness keys
    awful.key({ }, "XF86MonBrightnessDown" , function () awful.util.spawn("xbacklight -dec 5") end),
    awful.key({ }, "XF86MonBrightnessUp" , function () awful.util.spawn("xbacklight -inc 5") end),

    -- Volume keys
    awful.key({ }, "XF86AudioRaiseVolume" , function () awful.util.spawn("amixer sset Master 2%+ ") end),
    awful.key({ }, "XF86AudioLowerVolume" , function () awful.util.spawn("amixer sset Master 2%-") end),
    awful.key({ }, "XF86AudioMute" , function () awful.util.spawn("amixer sset Master toggle") end),

    -- Spawn a new firefox window
    awful.key({ modkey,           }, "i", function() awful.util.spawn_with_shell("firefox -new-window") end),

    -- Unminimize a random client on the current tag
    awful.key({ modkey, "Shift"   }, "n", function() awful.client.restore(s) end),

    -- Prompt
	-- HACK: mouse.screen is nil => replaced it with 1
    awful.key({ modkey,           }, "r", function() mypromptbox[1]:run() end),

    --[[ -- mod+x replaced by awful.tag.viewnext
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    --]]
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
--    awful.key({ "Alt"             }, "F4",     function (c) c:kill()                         end), -- This is not working, unfortunately 31.09.-16
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    --awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    -- Originally 't'
    awful.key({ modkey,           }, "o",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Create table of tags by name
tag_by_name = {}
-- A table of tags that get auto toggled on default 'viewonly' key behavior
toggle_tags = {}

--- {{{ Bind tag-keys
function bind_default_keys(key, screen, tag, background)
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, key,
                  function ()
                        local screen = mouse.screen
                        if tag then
                            local tags = {}
                            -- Add the activated tag
                            table.insert(tags, tag)
                            -- Add all toggles that are on
                            for toggle, on in pairs(toggle_tags) do
                                if on then
                                    table.insert(tags, toggle)
                                end
                            end
                            awful.tag.viewmore(tags)
                        end
                  end),
        awful.key({ modkey, "Control" }, key,
                  function ()
                      local screen = mouse.screen
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, key,
                  function ()
                      if client.focus then
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, key,
                  function ()
                      if client.focus then
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end
function bind_toggle_keys(key, screen, tag, background)
    globalkeys = awful.util.table.join(globalkeys,
        -- Bind toggle action to (modkey + key)
        awful.key({ modkey }, key,
                  function ()
                        local screen = mouse.screen
                        if tag then
                            -- HACK: save toggle state to the workaround until the callback has run
                            local on = toggle_tags[tag]
                            toggle_tags[tag] = true
                            awful.tag.viewonly(tag)
                            -- Restore original status
                            toggle_tags[tag] = on
                        end
                  end),
        -- Bind tag swap to (modkey + ctrl + key)
        awful.key({ modkey, "Control" }, key,
                  function ()
                        local screen = mouse.screen
                        if tag then
                            -- Save toggle state to the workaround
                            local on = toggle_tags[tag]
                            toggle_tags[tag] = not on
                            -- Activate
                            awful.tag.viewtoggle(tag)
                        end
                  end),
        awful.key({ modkey, "Shift" }, key,
                  function ()
                      if client.focus then
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, key,
                  function ()
                      if client.focus then
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
    -- Add the tag to the toggle-tag list for hack add
    toggle_tags[tag] = false
end
for s = 1, screen.count() do
    for idx, tag in pairs(awful.tag.gettags(s)) do
        tag_by_name[tag.name] = tag
    end
end
-- Bind QWE, ASD to tags
bind_default_keys("q", s, tag_by_name["Q"], tags.bg)
bind_default_keys("w", s, tag_by_name["W"], tags.bg)
bind_default_keys("e", s, tag_by_name["E"], tags.bg)
bind_default_keys("a", s, tag_by_name["A"], tags.bg)
bind_default_keys("s", s, tag_by_name["S"], tags.bg)
bind_default_keys("d", s, tag_by_name["D"], tags.bg)
-- Bind 1, 2, 3 to tags
bind_default_keys("#" .. "1" + 9, s, tag_by_name["1"], tags.bg)
bind_default_keys("#" .. "2" + 9, s, tag_by_name["2"], tags.bg)
bind_default_keys("#" .. "3" + 9, s, tag_by_name["3"], tags.bg)
-- Bind 4-www
bind_default_keys("#" .. "4" + 9, s, tag_by_name["4-www"], tags.bg)
bind_default_keys("#" .. "5" + 9, s, tag_by_name["4-www"], tags.bg)
-- Bind Toggle
bind_toggle_keys("t", s, tag_by_name["Toggle"], tags.bg)
-- Bind G-stash
bind_default_keys("g", s, tag_by_name["G-stash"], tags.bg)

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
					 maximized_vertical = false,
					 maximized_horizontal = false,
                     ontop = false,
                     buttons = clientbuttons } },
    -- Define some applications as floating by default
    { rule_any = { class = { "MPlayer", "pinentry", "gimp" } },
      properties = { floating = true } },
    -- Put memo on A
    -- TODO: this puts all things with memo in name to the tag (like vim-fast-memo things)
    { rule = { name = "memo" },
      properties = { tag = "A" }
    },
    -- Put evo on T-toggle
    { rule = { name = "evo" },
      properties = { tag = "T-toggle" }
    },
    -- Put saskia-irc on T-toggle, as minimized
    { rule = { name = "saskia-irc" },
      properties = { tag = "T-toggle", minimized = true }
    },
	-- Prevent some applications from doing stupid shit
	{ rule_any = { class = { "chromium", "firefox", "Firefox", "Telegram", "urxvt" } }, properties = {opacity = 1, maximized = false, floating = false} },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    c:connect_signal("property::hide",
        function(c)
            if beautiful.wallpaper then
                for s = 1, screen.count() do
                    gears.wallpaper.maximized(beautiful.wallpaper, s, true)
                end
            end
        end
    )

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local upper_left_layout = wibox.layout.fixed.horizontal()
        upper_left_layout:add(awful.titlebar.widget.iconwidget(c))
        upper_left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(upper_left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
    
    -- Toggle the new client out of all toggle-tags where it is visible, unless the toggle tag is explicitly the only selected tag
    if #awful.tag.selectedlist() ~= 1 then
        for tag, on in pairs(toggle_tags) do
            if on then
                c:toggle_tag(tag)
            end
        end
    end
end)

-- Don't let new clients be urgent by default
client.disconnect_signal("request::activate", awful.ewmh.activate)
function awful.ewmh.activate(c)
    if c:isvisible() then
        client.focus = c
        c:raise()
    end
end
client.connect_signal("request::activate", awful.ewmh.activate)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- Do things when a tag gets selected or deselected
awful.screen.connect_for_each_screen(function(s)
    awful.tag.attached_connect_signal(s, "property::selected", function(tag)
        if debug then
            naughty.notify({ preset = naughty.config.presets.info,
                             title = "tag state changed",
                             text = tag.name .. " -> " .. tostring(tag.selected)})
        end

        -- If any effect tries to activate the T-toggle, enable it
        --[[
        for toggle, on in pairs(toggle_tags) do
            if toggle.name == tag.name then
                toggle_tags[toggle] = true
            end
        end
        --]]

        -- Set toggle states based on the workaround
        for toggle, on in pairs(toggle_tags) do
            toggle.selected = on
        end
    end)
end)
-- }}}

-- Set the "1" tag as the startup tag
awful.tag.viewonly(tag_by_name["1"])
tag_by_name["Toggle"].master_width_factor = 0.7

-- Screen lock management
-- Run automatic screen locker
awful.util.spawn_with_shell('~/.config/awesome/locker')

-- Keypress screen lock
awful.key({ modkey }, "l",
    function ()
        awful.util.spawn("sync")
        awful.util.spawn("xautolock -locknow")
    end)
