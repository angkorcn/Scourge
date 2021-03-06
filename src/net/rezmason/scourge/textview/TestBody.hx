package net.rezmason.scourge.textview;

import flash.geom.Rectangle;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef RGB = {r:Float, g:Float, b:Float};

class TestBody extends Body {

    inline static var COLOR_RANGE:Int = 6;
    inline static var CHARS:String =
        TestStrings.ALPHANUMERICS +
    '';

    var time:Float;
    var hues:Array<Float>;

    public function new(id:Int, bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {
        time = 0;
        hues = [];

        var num:Int = 1200 /* 40000 */ ;
        super(id, bufferUtil, num, glyphTexture, redrawHitAreas);

        var dTheta:Float = Math.PI * (3 - Math.sqrt(5));
        var dZ:Float = 2 / (numGlyphs + 1);
        var theta:Float = 0;
        var _z:Float = 1 - dZ / 2;

        for (glyph in glyphs) {
            var hue:Float = (theta + _z * dTheta * 2) / (Math.PI * 2);
            hues.push(hue);
            /*
            var rgb:RGB = hsv2rgb(hue);
            /**/

            var i:Float = 0.2;

            var charCode:Int = CHARS.charCodeAt(glyph.id % CHARS.length);

            var rad:Float = Math.sqrt(1 - _z * _z);
            var x:Float = Math.cos(theta) * rad;
            var y:Float = Math.sin(theta) * rad;
            var z:Float = _z;

            x *= 0.6;
            y *= 0.6;
            z *= 0.6;

            var r:Float = ramp(x + 0.5);
            var g:Float = ramp(y + 0.5);
            var b:Float = ramp(z + 0.5);

            /*
            r = rgb.r;
            g = rgb.g;
            b = rgb.b;
            /**/

            glyph.set_shape(x, y, z, 1, 0);
            glyph.set_color(r, g, b);
            glyph.set_i(i);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(glyph.id | id << 16);

            _z -= dZ;
            theta += dTheta;
        }
    }

    inline function ramp(num:Float):Float {
        num = 1 - num;
        num = num * num;
        num = 1 - num;
        return num;
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);

        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;
        var glyphWidth:Float = rectSize * 0.03;
        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }

    override public function update(delta:Float):Void {
        time += delta;

        for (ike in 0...glyphs.length) {
            var glyph:Glyph = glyphs[ike];

            var d:Float = glyph.get_z();
            var p:Float = (Math.cos(time * 4 + d * 20) * 0.5 + 1) * 480  / numGlyphs;
            var s:Float = (Math.cos(time * 4 + d * 30) * 0.5 + 1) * 2400 / numGlyphs;

            //var rgb:RGB = hsv2rgb(hues[ike] + s * 0.1);

            glyph.set_p(p);
            glyph.set_s(s);

            //glyph.set_color(rgb.r, rgb.g, rgb.b);
        }

        super.update(delta);
    }

    override public function interact(id:Int, interaction:Interaction):Void {
        var glyph:Glyph = glyphs[id];
        switch (interaction) {
            case MOUSE(type, x, y):
                if (type == CLICK) setGlobalColor(Math.random(), Math.random(), Math.random());
            case KEYBOARD(type, key, char, shift, alt, ctrl):
                if (type == KEY_DOWN) setGlobalChar(char);
        }
    }

    inline function setGlobalColor(r:Float, g:Float, b:Float):Void {
        for (glyph in glyphs) glyph.set_color(r, g, b);
    }

    inline function setGlobalChar(charCode:Int):Void {
        if (charCode > 0) for (glyph in glyphs) glyph.set_char(charCode, glyphTexture.font);
    }

    /*
    inline function hsv2rgb(hue:Float, sat:Float = 1, val:Float = 1, oldRGB:RGB = null):RGB {
        var r:Float = 0;
        var g:Float = 0;
        var b:Float = 0;

        var chroma:Float = val * sat;

        hue = hue % 1;
        var hFrac:Float = (hue % (1 / 6)) * 6;

        switch (Math.floor(hue * 6)) {
            case 0:
                r = chroma;
                g = chroma * hFrac;
            case 1:
                g = chroma;
                r = chroma * (1 - hFrac);
            case 2:
                g = chroma;
                b = chroma * hFrac;
            case 3:
                b = chroma;
                g = chroma * (1 - hFrac);
            case 4:
                b = chroma;
                r = chroma * hFrac;
            case 5:
                r = chroma;
                b = chroma * (1 - hFrac);
        }

        var m:Float = val - chroma;

        r += m;
        g += m;
        b += m;

        var rgb:RGB = oldRGB;
        if (rgb == null) rgb = {r:0, g:0, b:0};

        rgb.r = r;
        rgb.g = g;
        rgb.b = b;

        return rgb;
    }
    /**/
}
