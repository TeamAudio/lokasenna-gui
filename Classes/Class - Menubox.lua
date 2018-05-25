--[[	Lokasenna_GUI - MenuBox class
	
	---- User parameters ----
	
	(name, z, x, y, w, h, caption, opts[, pad, noarrow])
	
Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
w, h
caption			Label displayed to the left of the menu box
opts			Comma-separated string of options. As with gfx.showmenu, there are
				a few special symbols that can be added at the beginning of an option:
				
                    ! : Checked
					# : grayed out
					> : this menu item shows a submenu
					< : last item in the current submenu
					An empty field will appear as a separator in the menu.
					
				
				
Optional:
pad				Padding between the label and the box
noarrow         Boolean. Removes the arrow from the menubox.


Additional:
col_txt         Value color
col_cap         Caption color
bg				Color to be drawn underneath the label. Defaults to "wnd_bg"
font_a			Font for the menu's label
font_b			Font for the menu's current value
align           Flags for gfx.drawstr:

                    flags&1: center horizontally
                    flags&2: right justify
                    flags&4: center vertically
                    flags&8: bottom justify
                    flags&256: ignore right/bottom, 
                    otherwise text is clipped to (gfx.x, gfx.y, right, bottom)
                    

Extra methods:



GUI.Val()		Returns the current menu option, numbered from 1. Numbering does include
				separators and submenus:
				
					New					1
					--					
					Open				3
					Save				4
					--					
					Recent	>	a.txt	7
								b.txt	8
								c.txt	9
					--
					Options				11
					Quit				12
										
GUI.Val(new)	Sets the current menu option, numbered as above.


]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


GUI.Menubox = GUI.Element:new()
function GUI.Menubox:new(name, z, x, y, w, h, caption, opts, pad, noarrow)
	
	local menu = {}
	
	menu.name = name
	menu.type = "Menubox"
	
	menu.z = z
	GUI.redraw_z[z] = true	
	
	menu.x, menu.y, menu.w, menu.h = x, y, w, h

	menu.caption = caption
	menu.bg = "wnd_bg"
	
	menu.font_a = 3
	menu.font_b = 4
	
	menu.col_cap = "txt"
	menu.col_txt = "txt"
	
	menu.pad = pad or 4
    menu.noarrow = noarrow or false
    menu.align = 0
	
    if type(opts) == "string" then
        -- Parse the string of options into a table
        menu.optarray = {}

        for word in string.gmatch(opts, '([^,]+)') do
            menu.optarray[#menu.optarray+1] = word
        end
    elseif type(opts) == "table" then
        menu.optarray = opts
    end
	
	menu.retval = 1
	
	setmetatable(menu, self)
    self.__index = self 
    return menu
	
end


function GUI.Menubox:init()
	
	local w, h = self.w, self.h
	
	self.buff = GUI.GetBuffer()
	
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*w + 4, 2*h + 4)
	
    self:drawframe()
    
    if not self.noarrow then self:drawarrow() end

end


function GUI.Menubox:draw()	
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
	local caption = self.caption
	local focus = self.focus
	

	-- Draw the caption
	if caption and caption ~= "" then self:drawcaption() end
	
    
    -- Blit the shadow + frame
	for i = 1, GUI.shadow_dist do
		gfx.blit(self.buff, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)	
	end
	
	gfx.blit(self.buff, 1, 0, 0, (focus and (h + 2) or 0) , w + 2, h + 2, x - 1, y - 1) 	
	

    -- Draw the text
    self:drawtext()
	
end


function GUI.Menubox:val(newval)
	
	if newval then
		self.retval = newval
		self:redraw()		
	else
		return math.floor(self.retval)
	end
	
end


------------------------------------
-------- Input methods -------------
------------------------------------


function GUI.Menubox:onmouseup()

    -- Bypass option for GUI Builder
    if not self.focus then
        self:redraw()
        return
    end
    
	-- The menu doesn't count separators in the returned number,
	-- so we'll do it here
	local menu_str, sep_arr = self:prepmenu()
	
	gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y	
	local curopt = gfx.showmenu(menu_str)
	
	if #sep_arr > 0 then curopt = self:stripseps(curopt, sep_arr) end	
	if curopt ~= 0 then self.retval = curopt end

	self.focus = false
	self:redraw()	
    
end


-- This is only so that the box will light up
function GUI.Menubox:onmousedown()
	self:redraw()
end


function GUI.Menubox:onwheel()
	
	-- Avert a crash if there aren't at least two items in the menu
	--if not self.optarray[2] then return end	
	
	-- Check for illegal values, separators, and submenus
    self.retval = self:validateoption(  GUI.round(self.retval - GUI.mouse.inc),
                                        GUI.round((GUI.mouse.inc > 0) and 1 or -1) )

	self:redraw()	
    
end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function GUI.Menubox:drawframe()

    local x, y, w, h = self.x, self.y, self.w, self.h
	local r, g, b, a = table.unpack(GUI.colors["shadow"])
	gfx.set(r, g, b, 1)
	gfx.rect(w + 3, 1, w, h, 1)
	gfx.muladdrect(w + 3, 1, w + 2, h + 2, 1, 1, 1, a, 0, 0, 0, 0 )
	
	GUI.color("elm_bg")
	gfx.rect(1, 1, w, h)
	gfx.rect(1, w + 3, w, h)
	
	GUI.color("elm_frame")
	gfx.rect(1, 1, w, h, 0)
	if not self.noarrow then gfx.rect(1 + w - h, 1, h, h, 1) end
	
	GUI.color("elm_fill")
	gfx.rect(1, h + 3, w, h, 0)
	gfx.rect(2, h + 4, w - 2, h - 2, 0)

end


function GUI.Menubox:drawarrow()

    local x, y, w, h = self.x, self.y, self.w, self.h
    gfx.rect(1 + w - h, h + 3, h, h, 1)

    GUI.color("elm_bg")
    
    -- Triangle size
    local r = 5
    local rh = 2 * r / 5
    
    local ox = (1 + w - h) + h / 2
    local oy = 1 + h / 2 - (r / 2)

    local Ax, Ay = GUI.polar2cart(1/2, r, ox, oy)
    local Bx, By = GUI.polar2cart(0, r, ox, oy)
    local Cx, Cy = GUI.polar2cart(1, r, ox, oy)
    
    GUI.triangle(true, Ax, Ay, Bx, By, Cx, Cy)
    
    oy = oy + h + 2
    
    Ax, Ay = GUI.polar2cart(1/2, r, ox, oy)
    Bx, By = GUI.polar2cart(0, r, ox, oy)
    Cx, Cy = GUI.polar2cart(1, r, ox, oy)	
    
    GUI.triangle(true, Ax, Ay, Bx, By, Cx, Cy)	    
    
end


function GUI.Menubox:drawcaption()
 
    GUI.font(self.font_a)
    local str_w, str_h = gfx.measurestr(self.caption)    
    
    gfx.x = self.x - str_w - self.pad
    gfx.y = self.y + (self.h - str_h) / 2
    
    GUI.text_bg(self.caption, self.bg)
    GUI.shadow(self.caption, self.col_cap, "shadow")

end


function GUI.Menubox:drawtext()

    -- Make sure retval hasn't been accidentally set to something illegal
    self.retval = self:validateoption(tonumber(self.retval) or 1)

    -- Strip gfx.showmenu's special characters from the displayed value
	local text = string.match(self.optarray[self.retval], "^[<!#]?(.+)")

	-- Draw the text
	GUI.font(self.font_b)
	GUI.color(self.col_txt)
	
	--if self.output then text = self.output(text) end
    
    if self.output then
        local t = type(self.output)

        if t == "string" or t == "number" then
            text = self.output
        elseif t == "table" then
            text = self.output[text]
        elseif t == "function" then
            text = self.output(text)
        end
    end
    
    -- Avoid any crashes from weird user data
    text = tostring(text)


    str_w, str_h = gfx.measurestr(text)
	gfx.x = self.x + 4
	gfx.y = self.y + (self.h - str_h) / 2
    
    local r = gfx.x + self.w - 8 - (self.noarrow and 0 or self.h)
    local b = gfx.y + str_h
	gfx.drawstr(text, self.align, r, b)       
    
end


------------------------------------
-------- Input helpers -------------
------------------------------------


-- Put together a string for gfx.showmenu from the values in optarray
function GUI.Menubox:prepmenu()

	local str_arr = {}
    local sep_arr = {}    
    local menu_str = ""
    
	for i = 1, #self.optarray do
		
		-- Check off the currently-selected option
		if i == self.retval then menu_str = menu_str .. "!" end

        table.insert(str_arr, tostring( type(self.optarray[i]) == "table"
                                            and self.optarray[i][1]
                                            or  self.optarray[i]
                                      )
                    )

		if str_arr[#str_arr] == ""
		or string.sub(str_arr[#str_arr], 1, 1) == ">" then 
			table.insert(sep_arr, i) 
		end

		table.insert( str_arr, "|" )

	end
	
	menu_str = table.concat( str_arr )
	
	return string.sub(menu_str, 1, string.len(menu_str) - 1), sep_arr

end


-- Adjust the menu's returned value to ignore any separators ( --------- )
function GUI.Menubox:stripseps(curopt, sep_arr)

    for i = 1, #sep_arr do
        if curopt >= sep_arr[i] then
            curopt = curopt + 1
        else
            break
        end
    end
    
    return curopt
    
end    


function GUI.Menubox:validateoption(val, dir)
    
    dir = dir or 1
    
    while true do

        -- Past the first option, look upward instead
        if val < 1 then
            val = 1
            dir = 1        

        -- Past the last option, look downward instead
        elseif val > #self.optarray then
            val = #self.optarray
            dir = -1

        end
        
        -- Don't stop on separators, folders, or grayed-out options        
        local opt = string.sub(self.optarray[val], 1, 1)
        if opt == "" or opt == ">" or opt == "#" then
            val = val - dir
            
        -- This option is good
        else
            break
        end
    
    end
    
    return val    
    
end


-- Make sure the wheel hasn't taken us out of range,
-- and skip past any separators or folders
function GUI.Menubox:adjustwheel()
    
	local curopt = GUI.round(self.retval - GUI.mouse.inc)
	local inc = GUI.round((GUI.mouse.inc > 0) and 1 or -1)

--[[
	while true do
		
        -- Past the first option, look upward instead
		if curopt < 1 then 
			curopt = 1 
			inc = 1
            

            
        -- Past the last option, look downward instead
		elseif curopt > #self.optarray then 
			curopt = #self.optarray
			inc = -1
            

            
		end	

        -- Don't stop on separators, folders, or grayed-out options
		if self.optarray[curopt] == "" 
        or string.sub( self.optarray[curopt], 1, 1 ) == ">" 
        or string.sub( self.optarray[curopt], 1, 1 ) == "#" then 
        
			curopt = curopt - inc

        -- All good
		else
            GUI.Msg("landed on " .. self.optarray[curopt])
			break
		end
		
	end    
]]--    
    return curopt

end