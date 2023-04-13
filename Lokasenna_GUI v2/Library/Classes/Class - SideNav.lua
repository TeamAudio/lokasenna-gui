-- NoIndex: true

--[[	Lokasenna_GUI (Team Audio addition) - SideNav class

    Creation parameters:
    name, z, x, y, tab_w, tab_h, opts[, pad_outer][, pad_inner]

]]--

if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end

GUI.SideNav = GUI.Element:new()
function GUI.SideNav:new(name, z, x, y, tab_w, tab_h, opts, pad_outer, pad_inner)

    local SideNav = (not x and type(z) == "table") and z or {}

    SideNav.name = name
    SideNav.type = "SideNav"

    SideNav.z = SideNav.z or z

    SideNav.x = SideNav.x or x
    SideNav.y = SideNav.y or y
    SideNav.tab_w = SideNav.tab_w or tab_w or 200
    SideNav.tab_h = SideNav.tab_h or tab_h or 36

    SideNav.font_a = SideNav.font_a or 3
    SideNav.font_b = SideNav.font_b or 4

    SideNav.bg = SideNav.bg or "elm_bg"
    SideNav.col_txt = SideNav.col_txt or "txt"
    SideNav.col_tab_a = SideNav.col_tab_a or "wnd_bg"
    SideNav.col_tab_b = SideNav.col_tab_b or "elm_bg"
    SideNav.col_active = SideNav.col_active or "elm_fill"

    SideNav.pad_outer = SideNav.pad_outer or pad_outer or 16
    SideNav.pad_inner = SideNav.pad_inner or pad_inner or 4

    -- Parse the string of options into a table
    if not SideNav.optarray then
        local opts = SideNav.opts or opts

        SideNav.optarray = {}
        if type(opts) == "string" then
            for word in string.gmatch(opts, '([^,]+)') do
                SideNav.optarray[#SideNav.optarray + 1] = word
            end
        elseif type(opts) == "table" then
            SideNav.optarray = opts
        end
    end

    SideNav.z_sets = {}
    for i = 1, #SideNav.optarray do
        SideNav.z_sets[i] = {}
    end

    -- Figure out the total size of the SideNav frame now that we know the
    -- number of buttons, so we can do the math for clicking on it
    SideNav.w = SideNav.tab_w + 2 * SideNav.pad_outer
    SideNav.h = (SideNav.tab_h + SideNav.pad_inner) * #SideNav.optarray - SideNav.pad_inner + 2 * SideNav.pad_outer

    if SideNav.fullheight == nil then
        SideNav.fullheight = true
    end

    -- Currently-selected option
    SideNav.retval = SideNav.retval or 1
    SideNav.state = SideNav.retval or 1

    -- Index of the last mouse hover and mouse down event
    SideNav.hover_at = nil
    SideNav.down_at = nil

    GUI.redraw_z[SideNav.z] = true

    setmetatable(SideNav, self)
    self.__index = self
    return SideNav

end


function GUI.SideNav:init()

    self:update_sets()

end


function GUI.SideNav:draw()

    local x, y = self.x, self.y
    local tab_w, tab_h = self.tab_w, self.tab_h
    local pad_outer = self.pad_outer
    local pad_inner = self.pad_inner
    local state = self.state
    local hover_at = self.hover_at

    -- Make sure h is at least the size of the tabs.
    self.h = self.fullheight and (GUI.cur_h - self.y) or math.max(self.h, (tab_h + pad_inner) * #self.optarray - pad_inner + 2 * pad_outer)

    GUI.color(self.bg)
    gfx.rect(x, y, self.w, self.h, true)
    gfx.muladdrect(self.w - 1, y, 1, self.h, 0, 0, 0, GUI.colors["shadow"][4])

    local tab_x = x + pad_outer
    local tab_y = y + pad_outer

    for i = 1, #self.optarray do
        local active = i == state
        local hover = i == hover_at
        local col_tab = self.col_tab_b
        local font = self.font_b

        if active or hover then
            col_tab = self.col_tab_a
            font = self.font_a
        end

        self:draw_tab(tab_x, tab_y, tab_w, tab_h, font, self.col_txt, col_tab, self.optarray[i])

        if active then
            GUI.color(self.col_active)
            GUI.roundrect(tab_x, tab_y + 10, 4, tab_h - 20, 2, 1, 1)
        end

        tab_y = tab_y + tab_h + pad_inner
    end

end


-- Returns the index into optarray corresponding to the current mouse
-- position, or nil if the mouse is not over an item
function GUI.SideNav:mouse_at()

    local tab_x = self.x + self.pad_outer
    local tab_y = self.y + self.pad_outer

    for i = 1, #self.optarray do
        if GUI.IsInside({
            x = tab_x,
            y = tab_y,
            w = self.tab_w,
            h = self.tab_h
        }) then
            return i
        end
        tab_y = tab_y + self.tab_h + self.pad_inner
    end

    return nil

end


function GUI.SideNav:val(newval)

    if newval then
        self.state = newval
        self.retval = self.state

        self:update_sets()
        self:onchange()
        self:redraw()
    else
        return self.state
    end

end


function GUI.SideNav:onresize()

    if self.fullheight then self:redraw() end

end


------------------------------------
-------- Input methods -------------
------------------------------------


function GUI.SideNav:onmousedown()

    self.down_at = self:mouse_at()
    self:redraw()

end


function GUI.SideNav:onmouseup()

    if self.down_at ~= nil and self.down_at == self:mouse_at() then
        self.state = self.down_at
        self.retval = self.state
        self:update_sets()
        self:onchange()
    end

    self.down_at = nil
    self:redraw()

end

function GUI.SideNav:onupdate()

    local prev_hover_at = self.hover_at
    self.hover_at = self:mouse_at()

    if self.hover_at ~= prev_hover_at then
        self:redraw()
    end

end




------------------------------------
-------- Drawing helpers -----------
------------------------------------


function GUI.SideNav:draw_tab(x, y, w, h, font, col_txt, col_bg, lbl)

    GUI.color(col_bg)

    GUI.roundrect(x, y, w, h, 4, 1, 1)

    -- Draw the tab's label
    GUI.color(col_txt)
    GUI.font(font)

    local str_w, str_h = gfx.measurestr(lbl)
    gfx.x = x + 18
    gfx.y = y + ((h - str_h) / 2)
    gfx.drawstr(lbl)

end




------------------------------------
-------- SideNav helpers -----------
------------------------------------


-- Updates visibility for any layers assigned to the tabs
function GUI.SideNav:update_sets(init)

    local state = self.state

    if init then
        self.z_sets = init
    end

    local z_sets = self.z_sets

    if not z_sets or #z_sets[1] < 1 then
        --reaper.ShowMessageBox("GUI element '"..self.name.."':\nNo z sets found.", "Library error", 0)
        --GUI.quit = true
        return 0
    end

    for i = 1, #z_sets do

        if i ~= state then
            for _, z in pairs(z_sets[i]) do

                GUI.elms_hide[z] = true

            end
        end

    end

    for _, z in pairs(z_sets[state]) do

        GUI.elms_hide[z] = false

    end

end
