--[[	Lokasenna_GUI (Team Audio addition) - Image Button class

    Creation parameters:
        name, z, x, y, w, h[, pixels, scale, caption, func, params...]

]]--

if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end


GUI.ImageButton = GUI.Element:new()
function GUI.ImageButton:new(name, z, x, y, w, h, img_w, img_h, pixels, scale, caption, func, ...)

    local ImageButton = (not x and type(z) == "table") and z or {}

    ImageButton.name = name
    ImageButton.type = "ImageButton"

    ImageButton.z = ImageButton.z or z
    ImageButton.x = ImageButton.x or x
    ImageButton.y = ImageButton.y or y
    ImageButton.w = ImageButton.w or w
    ImageButton.h = ImageButton.h or h

    ImageButton.img_w = ImageButton.img_w or img_w
    ImageButton.img_h = ImageButton.img_h or img_h
    ImageButton.pixels = ImageButton.pixels or pixels
    ImageButton.scale = ImageButton.scale or scale or 1

    ImageButton.caption = ImageButton.caption or caption
    ImageButton.font = ImageButton.font or 3

    ImageButton.col_bg = ImageButton.col_bg or "wnd_bg"
    ImageButton.col_txt = ImageButton.col_txt or "txt"
    ImageButton.col_fill = ImageButton.col_fill or "elm_fill"
    ImageButton.col_frame = ImageButton.col_frame or "elm_frame"

    ImageButton.func = ImageButton.func or func or function () end
    ImageButton.params = ImageButton.params or {...}

    ImageButton.state = 0

    GUI.redraw_z[ImageButton.z] = true

    setmetatable(ImageButton, self)
    self.__index = self
    return ImageButton

end


function GUI.ImageButton:init()

    self.buffs = self.buffs or GUI.GetBuffer(2)

    -- Draw inactive button into buffs[1]

    gfx.dest = self.buffs[1]
    gfx.setimgdim(gfx.dest, -1, -1)
    gfx.setimgdim(gfx.dest, self.w / self.scale, self.h / self.scale)

    GUI.color(self.col_bg)
    gfx.rect(0, 0, self.w / self.scale, self.h / self.scale)
    GUI.color(self.col_frame)
    GUI.roundrect(0, 0, self.w / self.scale - 1, self.h / self.scale - 1, 8, 1, 1)

    self:drawpixels()

    -- Draw active button into buffs[2]

    gfx.dest = self.buffs[2]
    gfx.setimgdim(gfx.dest, -1, -1)
    gfx.setimgdim(gfx.dest, self.w / self.scale, self.h / self.scale)

    GUI.color(self.col_bg)
    gfx.rect(0, 0, self.w / self.scale, self.h / self.scale)
    GUI.color(self.col_fill)
    GUI.roundrect(0, 0, self.w / self.scale - 1, self.h / self.scale - 1, 8, 1, 1)

    self:drawpixels()

end


function GUI.ImageButton:ondelete()

    GUI.FreeBuffer(self.buffs)

end


function GUI.ImageButton:drawpixels()

    local p = self.pixels or {}

    GUI.font(self.font)
    local str = self.caption
    str = str:gsub([[\n]],"\n")
    local _, str_h = gfx.measurestr(str)

    local img_pad_x = (self.w / self.scale - self.img_w) / 2
    local img_pad_y = (self.h / self.scale - self.img_h - str_h / self.scale) / 2

    GUI.draw_rle_image(p, img_pad_x, img_pad_y)

end


function GUI.ImageButton:draw()

    local x, y, w, h = self.x, self.y, self.w, self.h
    local state = self.state

    local buff = self.buffs[1]
    if state == 1 then
        buff = self.buffs[2]
    end

    gfx.blit(buff, self.scale, 0, 0, 0, self.w, self.h, self.x, self.y)

    -- Draw the caption
    GUI.color(self.col_txt)
    GUI.font(self.font)

    local str = self.caption
    str = str:gsub([[\n]],"\n")

    local str_w, str_h = gfx.measurestr(str)
    gfx.x = x + ((w - str_w) / 2)
    gfx.y = y + h - str_h - 8 * self.scale
    gfx.drawstr(str)

end


function GUI.ImageButton:onmousedown()

	self.state = 1
	self:redraw()

end


function GUI.ImageButton:onmouseup()

	self.state = 0

	-- If the mouse was released on the button, run func
	if GUI.IsInside(self) then

		self.func(table.unpack(self.params))

	end
	self:redraw()

end

function GUI.ImageButton:onupdate()

	if self.state == 0 and GUI.IsInside(self) then
		self.state = 1
		self:redraw()
	elseif self.state == 1 and not GUI.IsInside(self) then
		self.state = 0
		self:redraw()
	end

end
