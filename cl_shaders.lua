--[[
    Code by Nogitsu, all my small libs available here: https://github.com/Nogitsu/Small-libs
    Please do not remove these lines, I am using my time for these libs, so consider it.
]]

if not CLIENT then return end

--  > For shaders
local shaders = {
    g_colourmodify = {
        mat = Material( "pp/colour" ),
        parameters = {
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1,
            ["$pp_colour_brightness"] = 0,
        
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0,
            
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
        }
    },

    g_sharpen = {
        mat = Material( "pp/sharpen" ),
        parameters = {
            ["$contrast"] = 1,
            ["$distance"] = 1,
        }
    },

    sobel = {
        mat = Material( "pp/sobel" ),
        parameters = {
            ["$threshold"] = 0.11,
        }
    },

    g_blurx = {
        mat = Material( "pp/blurx" ),
        parameters = {
            ["$size"] = 1
        }
    },

    g_blury = {
        mat = Material( "pp/blury" ),
        parameters = {
            ["$size"] = 1
        }
    },

    g_texturize = {
        mat = Material( "pp/texturize" ),
        parameters = {
            ["$scalex"] = 1,
            ["$scaley"] = 1,
            ["$basetexture"] = "pp/texturize/plain.png",
        }
    }
}

local shaders_queue = {}

function AddShaderToQueue( x, y, w, h, shader, params )
    shaders_queue[ #shaders_queue + 1 ] = { x, y, w, h, shader, params }
end

function ModifyScreenShader( x, y, w, h, shader, params )
    if not shaders[ shader ] then error( "Unknown shader '" .. shader .. "'" ) return end

    local shader = shaders[ shader ]

    render.UpdateScreenEffectTexture()

    for k, v in pairs( shader.parameters ) do
        if isnumber( v ) then
		    shader.mat:SetFloat( k, v )
        elseif isstring( v ) then
		    shader.mat:SetTexture( k, v )
        end
    end
    
    for k, v in pairs( params or {} ) do
        if isnumber( v ) then
            shader.mat:SetFloat( k:StartWith( "$" ) and k or ( "$" .. k ), v )
        elseif isstring( v ) then
            shader.mat:SetTexture( k:StartWith( "$" ) and k or ( "$" .. k ), v )
        end
	end

    render.SetMaterial( shader.mat )
    
    x = x or 0
    y = y or 0
    w = w or 16
    h = h or 16

    render.SetScissorRect( x, y, x + w, y + h, true )
        render.DrawScreenQuad()
    render.SetScissorRect( 0, 0, 0, 0, false )
end

--  > Color modifier
function ModifyScreenColor( x, y, w, h, params )
    AddShaderToQueue( x, y, w, h, "g_colourmodify", params )
end

function DrawBlackAndWhite( x, y, w, h )
    ModifyScreenColor( x, y, w, h, {
        pp_colour_colour = 0,
    } )
end

--  > Sharpen
function ModifyScreenSharp( x, y, w, h, contrast, distance )
    AddShaderToQueue( x, y, w, h, "g_sharpen", {
        contrast = contrast,
        distance = distance and distance / ScrW()
    } )
end

--  > Sobel
function ModifyScreenSobel( x, y, w, h, threshold )
    AddShaderToQueue( x, y, w, h, "sobel", {
        threshold = threshold
    } )
end

--  > Blur
function DrawScreenBlur( x, y, w, h, size )
    AddShaderToQueue( x, y, w, h, "g_blurx", {
        size = size
    } )

    AddShaderToQueue( x, y, w, h, "g_blury", {
        size = size
    } )
end

--  > Texturize
function ModifyScreenTexture( x, y, w, h, texture )
    AddShaderToQueue( x, y, w, h, "g_texturize", {
        basetexture = texture
    } )
end

--  > Testing
hook.Add( "HUDPaint", "Shaders:Test", function()
    local w, h = ScrW(), ScrH()
    local box_w, box_h = w / 3, h / 3

    --ModifyScreenSobel( w - math.cos( CurTime() ) * ( w + box_w ), 0, box_w, h, 0.02 )

--[[     DrawBlackAndWhite( 0, 0, w, box_h )
    ModifyScreenSharp( 0, box_h, w, box_h, 1, 5 )
    ModifyScreenSobel( 0, box_h * 2, w, box_h, 0.2 ) ]]

--[[     DrawBlackAndWhite( 0, 0, box_w, h )
    ModifyScreenSharp( box_w, 0, box_w, h, 1, 5 )
    ModifyScreenSobel( box_w * 2, 0, box_w, h, 0.02 ) ]]

    DrawBlackAndWhite( 0, 0, w * math.abs( math.cos( CurTime() ) ), h )
end )

hook.Add( "RenderScreenspaceEffects", "Shaders:QueueThreat", function()
    for k, v in ipairs( shaders_queue ) do
        ModifyScreenShader( unpack( v ) )
    end

    shaders_queue = {}
end )
