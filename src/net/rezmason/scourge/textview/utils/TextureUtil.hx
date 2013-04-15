package net.rezmason.scourge.textview.utils;

import nme.display.BitmapData;
import nme.display3D.Context3DTextureFormat;
import nme.display3D.textures.Texture;
import nme.geom.Matrix;

class TextureUtil extends Util {

    public function createTexture(src:BitmapData):Texture {
        var size:Int = src.width;
        var texture:Texture = context.createTexture(size, size, Context3DTextureFormat.BGRA, false);
        var lev:Int = 0;
        while (size > 0) {
            texture.uploadFromBitmapData(getResizedBitmapData(src, size), lev);
            lev++;
            size = Std.int(size / 2);
        }

        return texture;
    }

    inline function getResizedBitmapData(bmp:BitmapData, width:UInt):BitmapData {
        var mat:Matrix = new Matrix();
        mat.scale(width / bmp.width, width / bmp.width);

        var bd:BitmapData = new BitmapData(width, width, bmp.transparent, 0x00FFFFFF);
        bd.draw(bmp, mat);

        return bd;
    }

}