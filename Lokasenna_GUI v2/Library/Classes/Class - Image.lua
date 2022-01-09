-- We'll be reusing a couple of methods from this
GUI.req("Classes/Class - Button.lua")()

-- We'll keep the loaded images here so we don't keep loading existing files
local images = {}

-- Loads the specified image from script_path/images/[image].png
-- If successful, returns a buffer number for retrieving it
local function loadImage(image_src)
  -- If we've already got this file...
  if images[image_srce] then return images[image_src] end

  -- Have the GUI assign a buffer for our image to live in
  local buffer = GUI.GetBuffer()

  -- Attempt to load the given image from our ./images
  local ret = gfx.loadimg(buffer, GUI.script_path.."/images/"..image_src..".png")

  -- If we're good, store the buffer number and return it
  if ret > -1 then
    images[image_src] = buffer
    return buffer
  -- If not, release the buffer
  else
    GUI.FreeBuffer(buffer)
  end
end

-- Create a new element class
local Image = GUI.Element:new()
GUI.Image = Image
Image.__index = Image

-- Required properties: z, w, h, image, func, params
-- w and h must be the size of one "frame" of the image
function Image:new(name, props)
  local new_image = props

  new_image.name = name
  new_image.type = "Image"

  if not new_image.src then error("Image: Missing 'image' property") end

  new_image.state = 0

  GUI.redraw_z[new_image.z] = true

  return setmetatable(new_image, self)
end

-- Make sure we have the image specified for this button
function Image:init()
  self.imageBuffer = loadImage(self.src)
  if not self.imageBuffer then 
    --error("IButton: The specified image was not found") 
  end
end

-- Draw from our buffer to the current layer
-- This setup expects three button states, laid out left to right: Normal, Hover, Down
function Image:draw()
  gfx.mode = 0
    gfx.blit(self.imageBuffer, 1, 0, 0, 0, self.w, self.h, self.x, self.y, self.w, self.h)
  --gfx.blit(self.imageBuffer, 1, 0, self.state * self.w, 0, self.w, self.h, self.x, self.y, self.w, self.h)
end

-- Check to see if the mouse has left the button and update accordingly
function Image:onupdate()
end
