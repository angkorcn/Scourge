package net.rezmason.scourge.textview.core;

import nme.display.BitmapData;
import nme.display.Sprite;
import nme.events.EventDispatcher;
import nme.events.MouseEvent;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
import nme.Vector;

typedef InteractFunction = Int->Int->Float->Float->Interaction->Void;

class MouseSystem {

    inline static var NULL_ID:Int = -1;

    public var bitmapData(default, null):BitmapData;
    public var view(get, null):Sprite;
    var _view:MouseView;

    var interact:InteractFunction;
    var hoverRawID:Int;
    var pressRawID:Int;
    var pixRect:Rectangle;
    var pixBytes:ByteArray;

    public function new(target:EventDispatcher, interact:InteractFunction):Void {
        _view = new MouseView(0.2);
        this.interact = interact;

        target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        target.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);

        hoverRawID = NULL_ID;
        pressRawID = NULL_ID;

        pixRect = new Rectangle(0, 0, 3, 3);
        pixBytes = new ByteArray();
    }

    public function setSize(width:Int, height:Int):Void {
        if (bitmapData != null) bitmapData.dispose();
        bitmapData = new BitmapData(width, height, false, 0x0);
        _view.bitmap.bitmapData = bitmapData;
    }

    function getRawID(x:Float, y:Float):Int {

        if (bitmapData == null) return NULL_ID;

        pixRect.x = Std.int(x) - 1;
        pixRect.y = Std.int(y) - 1;

        pixBytes.position = 0;
        bitmapData.copyPixelsToByteArray(pixRect, pixBytes);
        pixBytes.position = 0;

        var rawID:UInt = pixBytes.readUnsignedInt();
        while (pixBytes.bytesAvailable > 0) if (pixBytes.readUnsignedInt() != rawID) return NULL_ID;

        _view.update(x, y, rawID);

        return rawID;
    }

    function onMouseMove(event:MouseEvent):Void {
        var rawID:Int = getRawID(event.stageX, event.stageY);
        if (rawID == hoverRawID) {
            sendInteraction(rawID, event, MOVE);
        } else {
            sendInteraction(hoverRawID, event, EXIT);
            hoverRawID = rawID;
            sendInteraction(hoverRawID, event, ENTER);
        }
    }

    function onMouseDown(event:MouseEvent):Void {
        pressRawID = getRawID(event.stageX, event.stageY);
        sendInteraction(pressRawID, event, DOWN);
    }

    function onMouseUp(event:MouseEvent):Void {
        var rawID:Int = getRawID(event.stageX, event.stageY);
        sendInteraction(rawID, event, UP);
        sendInteraction(pressRawID, event, rawID == pressRawID ? CLICK : DROP);
        pressRawID = NULL_ID;
    }

    inline function sendInteraction(rawID:Int, event:MouseEvent, interaction:Interaction):Void {
        var bodyID:Int = rawID >> 16 & 0xFF;
        var glyphID:Int = rawID & 0xFFFF;
        if (bodyID >= 0) interact(bodyID, glyphID, event.stageX, event.stageY, interaction);
    }

    function get_view():Sprite {
        return _view;
    }

}