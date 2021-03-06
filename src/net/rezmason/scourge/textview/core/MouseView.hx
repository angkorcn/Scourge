package net.rezmason.scourge.textview.core;

import flash.display.Bitmap;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.text.TextField;


class MouseView extends Sprite {
    public var bitmap(default, null):Bitmap;
    var cursor:Shape;
    var textField:TextField;

    public function new(size:Float, mag:Float = 1, alpha:Float = 1):Void {
        super();

        bitmap = new Bitmap();
        bitmap.scaleX = bitmap.scaleY = size;
        bitmap.transform.colorTransform = new ColorTransform(mag, mag, mag);
        this.alpha = alpha;
        cursor = new Shape();
        cursor.graphics.beginFill(0xFF0000);
        cursor.graphics.lineTo(0, 20);
        cursor.graphics.lineTo(10, 16);
        cursor.graphics.endFill();
        textField = new TextField();
        textField.background = true;
        textField.height = 30;
        textField.selectable = false;

        addChild(bitmap);
        addChild(cursor);
        addChild(textField);
    }

    public function update(x:Float, y:Float, val:Int):Void {
        cursor.x = x * bitmap.scaleX;
        cursor.y = y * bitmap.scaleY;

        if (val != 0xFFFFFF) {
            cursor.alpha = 1;
            textField.text = StringTools.hex(val);
        } else {
            cursor.alpha = 0.5;
            textField.text = '---';
        }
    }

}
