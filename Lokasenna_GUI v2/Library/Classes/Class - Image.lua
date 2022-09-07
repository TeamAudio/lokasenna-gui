--[[	Lokasenna_GUI (Team Audio addition) - Image class

    Creation parameters:
        name, z, x, y, w, h[, pixels]

]]--

if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end


GUI.Image = GUI.Element:new()
function GUI.Image:new(name, z, x, y, w, h, pixels)

    local Image = (not x and type(z) == "table") and z or {}
    Image.name = name
    Image.type = "Image"

    Image.z = Image.z or z
    Image.x = Image.x or x
    Image.y = Image.y or y
    Image.w = Image.w or w
    Image.h = Image.h or h

    Image.pixels = Image.pixels or pixels

    Image.bg = Image.bg or "wnd_bg"

    GUI.redraw_z[Image.z] = true

    setmetatable(Image, self)
    self.__index = self
    return Image

end


function GUI.Image:init()

    self.buff = self.buff or GUI.GetBuffer()

    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    gfx.setimgdim(self.buff, self.w, self.h)

    GUI.color(self.bg)
    gfx.rect(0, 0, self.w, self.h, true)

    self:drawpixels()

end


function GUI.Image:ondelete()

    GUI.FreeBuffer(self.buff)

end


function GUI.Image:drawpixels()

    local p = self.pixels or {}
    GUI.draw_rle_image(p)

end


function GUI.Image:draw()

    gfx.blit(self.buff, 1, 0, 0, 0, self.w, self.h, self.x, self.y)

end
