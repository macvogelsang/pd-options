local pd <const> = playdate
local gfx <const> = pd.graphics
pd.display.setRefreshRate(30)

-- Import and initialize the global Options class -----
import 'options'
local defs = {
    {
        header = 'Options Demo',
        options = {
            -- Standard list style options.
            {name='B button', key='bFunction', values={'add circle', 'add square', 'clear all'}, dirtyRead=false, tooltip='Change the function of the B button. Not a dirtyRead option as the value is checked on demand when b is pressed.'},
            {name='Background', key='bg', values={'no bg', 'bayer', 'vertical'}, default=1, preview=true, dirtyRead=true, tooltip='This option hides the menu when changed for a better look at the scene behind it', canFavorite=true},
            -- Toggle switch option. No values necessary. This option also locks the Background option.
            {name='Outlined', style=Options.TOGGLE, default=1, dirtyRead=true, tooltip='Example for a toggle switch. Controls whether the added shapes are outlined or not. Will lock the background setting to "bayer"', locks={lockedOption='bg', lockedValue=2, lockedWhen=true}},
            -- Slider option examples. No values are supplied, instead pass a min and max. Must use ints and the range is inclusive. No limit on size of range but visually it may look weird at 20 or more values.
            -- If you want to select between a lot of numbers, want a greater than 1 step size, or want float values, use a list option instead.
            -- The default in this case is NOT an index like in all other styles. Instead it is a value within the range.
            {name='X offset', key='xOffset', min=-2, max=2, default=0, style=Options.SLIDER, dirtyRead=true, showValue=true},
            {name='Y offset', key='yOffset', min=0, max=10, default=0, style=Options.SLIDER, dirtyRead=true, showValue=true},
            -- Example of reset button. Name can be whatever but key must be "RESET"
            {name='Reset to defaults', key='RESET'}
        }
    }
}

Opts = Options(defs, false)
----------------------------------------------

-- Setup variables for the test app, can ignore this stuff ------
local patterns = {gfx.image.kDitherTypeNone, gfx.image.kDitherTypeBayer4x4, gfx.image.kDitherTypeVerticalLine}
local bgSprite = nil
local shapes = {}
local SHAPE_MAX_SIZE = 40
local SHAPE_MID = SHAPE_MAX_SIZE / 2

local textImg = gfx.imageWithText(" Press Ⓐ to open Options, Ⓑ to do function. ", 400, 30, gfx.kColorWhite, nil, nil, kTextAlignment.left)
local textSprite = gfx.sprite.new(textImg)
textSprite:moveTo(10, 210)
textSprite:setCenter(0,0)
textSprite:add()
-----------------------------------------------------------------

-- Controls for the test app. The options class has its own self-contained input handlers which you shouldn't need to worry about.
local controls = {
    -- A button to show options
    AButtonDown = function()
        Opts:show()
    end,
    -- Up button to demonstrate "randomizer" method.
    upButtonDown = function()
        Opts:randomize({'bg', 'bFunction'})
    end,
    -- B button function is flexible depending on current setting
    BButtonDown = function()
        -- Read the outlined status
        -- pass true here to "force" a read, even if the option is not dirty
        local outlined = Opts:read('outlined', true)

        -- Read the current b button function. No force read necessary since this is not a
        -- "dirtyRead" option.
        local bfn = Opts:read('bFunction')

        -- Note that by default, reads return an index not a value. So we check for that index here.
        -- It may be helpful to define these as global constants in your Lua project.
        -- i.e. BFN_CIRCLE, BFN_SQUARE, BFN_CLEAR = 1, 2, 3
        -- The rest of this code is logic to draw the different shapes based on the option values. You can ignore it.
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

-- Background drawing function
function setBackground(bgIndex)
    local bgImg = gfx.image.new(400, 240, gfx.kColorWhite)
    gfx.pushContext(bgImg)
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5, patterns[bgIndex])
        gfx.fillRect(0, 0, 400, 240)
    gfx.popContext()

    if bgSprite then bgSprite:remove() end
    bgsprite = gfx.sprite.setBackgroundDrawingCallback(function() bgImg:draw(0,0) end)
end

-- Shape offsetting function
function offsetShapes(byX, byY)
    -- When an offset slider is changed, the other slider value will be nil since it hasn't
    -- changed. We can force of a read of its current value by passing "true" as the second param.
    byX = byX or Opts:read('xOffset', true, true)
    byY = byY or Opts:read('yOffset', true, true)

    for i, shape in ipairs(shapes)  do
        local ix, iy = shape.initX, shape.initY
        shape:moveTo(ix + byX * 20, iy + byY * 20)
    end

end

-- Most of the logic for reading option values happens here
function pd.update()
    -- Only change the background when the option value has changed (i.e. dirty)
    local newBg = Opts:read('bg')
    if newBg ~= nil then
        setBackground(newBg)
    end

    -- Read the shape offset positions. Since the second arg is false (the default) and this is a
    -- "dirtyRead" option, the result of the read will be nil if the value hasn't changed.
    -- This prevents unnecessary updates since iterating through many shapes is expensive.
    -- The third argument of "true" causes the read call to return the value of the slider,
    -- not the index into the slider values. We want to do math on the value, not the index.
    local xOffset = Opts:read('xOffset', false, true)
    local yOffset = Opts:read('yOffset', false, true)
    if xOffset ~= nil or yOffset ~= nil then
        offsetShapes(xOffset, yOffset)
    end

    -- Debug/Example logic to print the current user settings to console after any change
    if Opts:isOptsDirty() then
        print("OPTIONS CHANGED:")
        printTable(Opts.userOptions)
        Opts:markClean()
    end

    gfx.sprite.update()
    playdate.timer.updateTimers()
end

-- Example of how to add an 'options' item to system menu
pd.getSystemMenu():addMenuItem('options', function(value)
    -- Check current state of options sprite to determine whether to open or close the menu.
    if Opts:isVisible(true) then
        Opts:hide()
    else
        Opts:show()
    end
end)