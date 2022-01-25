

--[[ Team Audio -- Multiuse button popup window to return values based on user button press selection]]--

if not (GUI and GUI.Window and GUI.Textbox and GUI.Button) then
	reaper.ShowMessageBox(  "Couldn't access some functions.\n\nUserInputs requires the Lokasenna_GUI "..
                            "Core script and the Window, Textbox, and Button classes.", 
                            "Library Error", 0)
	missing_lib = true
	return 0
end

local ref_txt = {x = 128, y = 16, w = 128, h = 20, off = 24}
local button_names = {}
local button_pad
local button_w

local function check_window_size(w, h)
    
		-- If the window's size has been changed, reopen it
		-- at the current position with the size we specified
		local dock,wnd_x,wnd_y,wnd_w,wnd_h = gfx.dock(-1,0,0,0,0)
        
        if wnd_w < w or wnd_h < h then
            return {dock, wnd_x, wnd_y, wnd_w, wnd_h}
        end
        
end


local function resize_window(dock, x, y, w, h)

    gfx.quit()
    gfx.init(GUI.name, w + 32, h + 32, dock, x, y)
    GUI.redraw_z[0] = true
    GUI.cur_w, GUI.cur_h = w, h
    
end

local function return_values(apply, func, retval)
    
    if apply then
        local val 
        val = retval
        func(val)
        
    else
        func(nil)
        
    end    
    
end

local function clear_UserInputs()
    
    -- Return the buffers we borrowed for our z_set
    GUI.FreeBuffer(GUI.elms.ActivateProductUserInput_wnd.z_set)
    
    -- Delete any elms with "UserInput" in their name
    for k in pairs(GUI.elms) do
        if string.match(k, "ActivateProductUserInputUser") then
            GUI.elms[k]:delete()
        end
    end
    
end


local function wnd_open(self)

    self:adjustchildelms()
    
    -- Place the buttons appropriately
    local button_x_pos = 0
    for bn =1, #button_names do
        local button_element = GUI.elms["ActivateProductUserInput_Button_"..bn]
        button_element.x = self.x + (self.w/#button_names) -225 + button_x_pos
        button_x_pos = button_x_pos + (button_pad + button_w)
    end
end
    
local function wnd_close(self, apply, retval)
    
    self:showlayers()
    
    return_values(apply, self.ret_func, retval)
    
    GUI.escape_bypass = false

    if self.resize then
        
        -- Reopen window with initial size
        resize_window( table.unpack(self.resize) )       
        
    end

    clear_UserInputs()
    
end

local function wnd_send_value(self, apply, retval)
    
    return_values(apply, self.ret_func, retval)
    
end

function GUI.ActivateProductGetUserInputs(title, input_button_names, ret_func, extra_width, button_width, button_padding)

    button_names = input_button_names
    button_pad = button_padding 
    button_w = button_width   
	-- Figure out the window dimensions
    local w = ref_txt.x + ref_txt.w + (extra_width or 0) + 16
    local h = 16 + 0 * (ref_txt.off) + 140

-- Resize the script window if the GUI window is larger (it'll be reset after)
    local resize = check_window_size(w, h)
    
    if resize then
        
        -- Reopen the window
        resize_window(resize[1], resize[2], resize[3], w + 32, h + 32)
        
    end


    local z_set = GUI.GetBuffer(2)
    table.sort(z_set)

    -- Set up the window
    --	name, z, x, y, w, h, caption, z_set[, center]
    local elms = {}
    elms.ActivateProductUserInput_wnd = {
        type = "Window",
        z = z_set[2],
        x = 0,
        y = 0,
        w = w,
        h = h,
        caption = title or "",
        z_set = z_set,
        num_inputs = #button_names-1,
        ret_func = ret_func,
        resize = resize,
        noclose = true
    }

     elms.ActivateProductUserInput_keybox = {
        type ="Textbox",    
        z = z_set[1],
        x = 128,
        y = 32,
        w = 150,
        h = 24,
        placeholder = '',
        caption = "Enter Product Key"
    }

       elms.ActivateProductUserInput_label = {
        type ="Label",    
        z = z_set[1],
        x = 85,
        y = 64,
        w = 150,
        h = 10,
        placeholder = '',
        caption = ""
    }
    
    for i = 1, #button_names do
        local name = button_names[i]
         -- Set up the OK/Cancel buttons
        elms["ActivateProductUserInput_Button_"..i] = {
            type = "Button",
            z = z_set[1],
            x = 0,
            y = h -50,
            w = button_width,
            h = 16,
            caption = name,
            retval = i,
            ret_func=ret_func
    }
    end

  -- Create the window and elements
    GUI.CreateElms(elms)
    
    -- Our elms need to be in the master list for the Window's adjustment function to see them
    GUI.update_elms_list()

     -- Method overrides so we can return values and whatnot
    GUI.elms.ActivateProductUserInput_wnd.onopen = wnd_open
    
    GUI.newfocus = GUI.elms.Window

    for bn =1, #button_names do
        local button_element = GUI.elms["ActivateProductUserInput_Button_"..bn]
        button_element.onmousedown = wnd_send_value
        button_element.func = function() button_element:onmousedown(true,button_element.retval)end
    end

    GUI.elms.ActivateProductUserInput_wnd:open()
    --Dont escape window close app if activation windows is escaped
    GUI.escape_bypass = false

end
