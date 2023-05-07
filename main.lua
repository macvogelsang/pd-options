local pd <const> = playdate
local gfx <const> = pd.graphics
pd.display.setRefreshRate(0)

import 'options'
Opts = Options()

local patterns = {gfx.image.kDitherTypeNone, gfx.image.kDitherTypeBayer4x4, gfx.image.kDitherTypeVerticalLine}
local bgSprite = nil
local shapes = {}
local SHAPE_MAX_SIZE = 40
local SHAPE_MID = SHAPE_MAX_SIZE / 2

local textImg = gfx.imageWithText("*Press A to open Options*", 210, 30, gfx.kColorWhite, nil, nil, kTextAlignment.left)
local textSprite = gfx.sprite.new(textImg)
textSprite:moveTo(10, 210)
textSprite:setCenter(0,0)
textSprite:add()

local controls = {
    -- A button to show options
    AButtonDown = function()
        Opts:show()
    end,
    -- B button function is flexible depending on current setting
    BButtonDown = function()
        -- Read the outlined status
        -- pass true here to "force" a read, even if the option is not dirty
        local outlined = Opts:read('outlined', true)

        -- Read the current b button function
        local bfn = Opts:read('bFunction')

        if bfn == 3 then -- clear all shapes
            for i, shape in ipairs(shapes) do
                shape:remove()
            end
            shapes = {}
        else
            local img = gfx.image.new(SHAPE_MAX_SIZE,SHAPE_MAX_SIZE)
            local randX, randY, size = math.random(20, 380), math.random(20, 220), math.random(5,SHAPE_MID-1)
            gfx.pushContext(img)
                if outlined then
                    gfx.setColor(gfx.kColorWhite)
                    gfx.setLineWidth(2)
                    if bfn == 1 then -- draw circle
                        gfx.fillCircleAtPoint(SHAPE_MID, SHAPE_MID, size)
                        gfx.setColor(gfx.kColorBlack)
                        gfx.drawCircleAtPoint(SHAPE_MID, SHAPE_MID, size)
                    elseif bfn == 2 then -- draw square
                        gfx.fillRect(SHAPE_MID-size, SHAPE_MID-size, size*2, size*2)
                        gfx.setColor(gfx.kColorBlack)
                        gfx.drawRect(SHAPE_MID-size, SHAPE_MID-size, size*2, size*2)
                    end
                else
                   gfx.setColor(gfx.kColorBlack)
                   if bfn == 1 then -- draw circle
                       gfx.fillCircleAtPoint(SHAPE_MID, SHAPE_MID, size)
                   elseif bfn == 2 then -- draw square
                       gfx.fillRect(SHAPE_MID-size, SHAPE_MID-size, size*2, size*2)
                   end
                end
            gfx.popContext()
            local shape = gfx.sprite.new(img)
            shape:setCenter(0.5,0.5)
            shape.initX = randX
            shape.initY = randY
            shape:moveTo(randX, randY)
            shape:add()
            table.insert(shapes, shape)
        end
    end
}
pd.inputHandlers.push(controls)

function setBackground(bgIndex)
    local bgImg = gfx.image.new(400, 240, gfx.kColorWhite)
    gfx.pushContext(bgImg)
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5, patterns[bgIndex])
        print('bgIndex', bgIndex)
        gfx.fillRect(0, 0, 400, 240)
    gfx.popContext()

    if bgSprite then bgSprite:remove() end
    bgsprite = gfx.sprite.setBackgroundDrawingCallback(function() bgImg:draw(0,0) end)
end

function offsetShapes(byX, byY)
    -- For any offset that is nil, force a read of its current value ignoring the dirty flag.
    byX = byX or Opts:read('xOffset', true, true)
    byY = byY or Opts:read('yOffset', true, true)

    for i, shape in ipairs(shapes)  do
        local ix, iy = shape.initX, shape.initY
        shape:moveTo(ix + byX * 20, iy + byY * 20)
    end

end

function pd.update()
    -- Only change the background when the option value has changed (i.e. dirty)
    local newBg = Opts:read('bg')
    if newBg ~= nil then
        setBackground(newBg)
    end

    -- Only change the shape positions when one of the offsets is dirty.
    -- Shouldn't do this every update since it may take a lot of time with many shapes.
    local xOffset = Opts:read('xOffset', false, true)
    local yOffset = Opts:read('yOffset', false, true)
    if xOffset ~= nil or yOffset ~= nil then
        offsetShapes(xOffset, yOffset)
    end

    gfx.sprite.update()
end

-- Example of adding options item to system menu
pd.getSystemMenu():addMenuItem('options', function(value)
    if Opts:isVisible(true) then
        Opts:hide()
    else
        Opts:show()
    end
end)