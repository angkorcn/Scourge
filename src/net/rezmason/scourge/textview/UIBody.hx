package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.system.Capabilities;
import flash.ui.Keyboard;

import haxe.Utf8;
import openfl.Assets;

import net.rezmason.gl.utils.BufferUtil;
import net.rezmason.scourge.textview.TestStrings;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.AnimatedStyle;
import net.rezmason.scourge.textview.text.Sigil.STYLE;
import net.rezmason.scourge.textview.text.Style;
import net.rezmason.scourge.textview.text.StyleSet;
import net.rezmason.scourge.textview.text.TextRegion;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIBody extends Body {

    inline static var glideEase:Float = 0.6;
    inline static var NATIVE_DPI:Float = 96;
    inline static var GLYPH_HEIGHT_IN_POINTS:Float = 24;

    inline static var LINE_TOKEN:String = '¬¬¬';

    var styles:StyleSet;
    var region:TextRegion;

    var combinedText:String;
    var combinedTextLength:Int;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var glyphWidthInPixels :Float;
    var glyphHeightInPixels:Float;
    var baseTransform:Matrix3D;

    var currentScrollPos:Float;
    var glideGoal:Float;
    var gliding:Bool;
    var lastRedrawPos:Float;

    var dragging:Bool;
    var dragStartY:Float;
    var dragStartPos:Float;

    var numRows:Int;
    var numCols:Int;
    var numRowsForLayout:Int;
    var numGlyphsInLayout:Int;

    var time:Float;

    var blurb:String;
    var prompt:String;
    var caret:String;
    var systemInput:String;
    var systemOutput:String;
    var dirty:Bool;
    var caretStyle:AnimatedStyle;
    var interpret:String->String;

    public var numLines(get, null):Int;
    public var numScrollPositions(get, null):Int;
    public var bottomPos(get, null):Float;

    public function new(id:Int, bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void, interpret:String->String):Void {

        this.interpret = interpret;

        styles = new StyleSet();
        region = new TextRegion(styles);

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        glyphHeightInPixels = GLYPH_HEIGHT_IN_POINTS * getScreenDPI() / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        var numGlyphColumns:Int = Std.int(Capabilities.screenResolutionX / glyphWidthInPixels);
        var numGlyphRows:Int = Std.int(Capabilities.screenResolutionY / glyphHeightInPixels);

        var numGlyphs:Int = (numGlyphRows + 1) * numGlyphColumns;

        currentScrollPos = Math.NaN;
        gliding = false;

        numRows = 0;
        numCols = 0;
        numRowsForLayout = 0;
        numGlyphsInLayout = 0;

        time = 0;

        super(id, bufferUtil, numGlyphs, glyphTexture, redrawHitAreas);

        letterbox = false;

        for (ike in 0...numGlyphs) glyphs[ike].set_paint(id << 16);

        // blurb = [TestStrings.SYMBOLS + " " + TestStrings.WEIRD_SYMBOLS, TestStrings.SPLASH, TestStrings.BOARD].join("\n\n");
        // blurb = Assets.getText("assets/not plus.txt");
        // blurb = Assets.getText("assets/enterprise.txt");
        // blurb = Assets.getText("assets/acid2.txt");
        blurb = TestStrings.STYLED_TEXT;
        // blurb = "One. §{i:1}Two§{}.";

        styles.extract(TestStrings.BREATHING_PROMPT_STYLE);
        styles.extract(TestStrings.CARET_STYLE);

        caretStyle = cast styles.getStyleByName('caret');

        prompt = '§{breathingprompt}Ω_rezmason§{} => §{}';
        setCaret('|');
        systemInput = '';
        systemOutput = '\n';
        dirty = false;

        updateText(blurb + systemOutput + prompt + systemInput + caret);
    }

    override public function update(delta:Float):Void {
        if (dirty) {
            dirty = false;
            updateText(blurb + systemOutput + prompt + systemInput + caret);
            caretStyle.time = 0;
            glideTextToPos(bottomPos);
        }
        updateGlide();
        styles.updateGlyphs(delta);
        taperScrollEdges();
        super.update(delta);
    }

    public function setText(text:String):Void {
        blurb = text;
    }

    public function setPrompt(text:String):Void {
        prompt = text;
    }

    public function setCaret(text:String):Void {
        caret = '§{caret}$text§{}';
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);
        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        numRows = Std.int(rect.height * stageHeight / glyphHeightInPixels);
        numRowsForLayout = numRows;
        numRows++;

        numCols = Std.int(rect.width  * stageWidth  / glyphWidthInPixels );
        setGlyphScale(rect.width / numCols * 2, rect.height / numRowsForLayout * 2);

        lastRedrawPos = Math.NaN;
        reorderGlyphs();
        updateText(blurb + systemOutput + prompt + systemInput + caret);
    }

    public function glideTextToPos(pos:Float):Void {
        gliding = true;
        glideGoal = Math.round(Math.max(0, Math.min(bottomPos, pos)));
    }

    inline function padLine(line:String):String {

        var count:Int = 0;
        var right:String = line;
        while (Utf8.length(right) > 0) {
            var sigilIndex:Int = right.indexOf(STYLE);
            if (sigilIndex == -1) break;
            right = right.substr(sigilIndex, right.length);
            right = Utf8.sub(right, 1, Utf8.length(right));
            count++;
        }

        // Pads a string until its length, ignoring sigils, is numCols
        line = rpad(line, ' ', numCols + count);
        return line;
    }

    inline function wrapLines(s:String) {

        // Splits a line into an array of lines whose length, ignoring sigils, is numCols

        var left:String = '';
        var right:String = s;

        var wrappedLines:Array<String> = [];

        var count:Int = 0;
        while (right.length > 0) {
            var len:Int = right.length;
            var line:String = '';
            line = Utf8.sub(right, 0, numCols - count);
            var sigilIndex:Int = line.indexOf(STYLE);
            if (sigilIndex == -1) {
                left = left + line;
                wrappedLines.push(padLine(left));
                left = '';
                if (numCols - count < right.length) {
                    right = Utf8.sub(right, numCols - count, Utf8.length(right));
                    left = '';
                } else {
                    right = '';
                    left = null;
                }
                count = 0;
            } else {
                line = right.substr(0, sigilIndex);
                if (sigilIndex > 0) left = left + line;
                left = left + STYLE;
                right = right.substr(sigilIndex, right.length);
                if (Utf8.length(right) > 1) right = Utf8.sub(right, 1, Utf8.length(right));
                else right = '';
                count += Utf8.length(line);
            }
        }

        if (left != null) wrappedLines.push(padLine(left));

        return wrappedLines.join(LINE_TOKEN);
    }

    public function updateText(combinedText:String, refreshStyles:Bool = false):Void {

        if (combinedText == null) combinedText = '';
        this.combinedText = swapTabsWithSpaces(combinedText);

        if (numGlyphsInLayout == 0) return;

        // Simplify the combinedText and wrap it to new lines as we construct the page

        page = region.extractFromText(this.combinedText, refreshStyles).split('\n').map(wrapLines).join(LINE_TOKEN).split(LINE_TOKEN);

        // Add blank lines to the end, to reach the minimum page length (numRows)

        var blankParagraph:String = rpad('', ' ', numCols);
        combinedTextLength = page.length;
        while (page.length < numRows) page.push(blankParagraph);

        // Count the sigils in each line, for style lookup

        var lineStyleIndex:Int = 0;
        lineStyleIndices = [lineStyleIndex];
        for (line in page) {
            lineStyleIndex += line.split(STYLE).length - 1;
            lineStyleIndices.push(lineStyleIndex);
        }

        setScrollPos(Math.isNaN(currentScrollPos) ? bottomPos : currentScrollPos);
    }

    inline function swapTabsWithSpaces(input:String):String {
        var left:String = '';
        var right:String = input;

        while (Utf8.length(right) > 0) {
            var tabIndex:Int = right.indexOf('\t');
            if (tabIndex == -1) {
                left = left + right;
                right = '';
            } else {
                left = left + right.substr(0, tabIndex) + '    ';
                right = right.substr(tabIndex, right.length);
                right = Utf8.sub(right, 1, Utf8.length(right));
            }
        }

        return left;
    }

    inline function reorderGlyphs():Void {
        var id:Int = 0;
        for (row in 0...numRows) {
            for (col in 0...numCols) {
                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / numRowsForLayout - 0.5);
                var glyph:Glyph = glyphs[id++];
                glyph.set_pos(x, y, 0);
            }
        }

        numGlyphsInLayout = numRows * numCols;
        toggleGlyphs(glyphs.slice(0, numGlyphsInLayout), true);
        toggleGlyphs(glyphs.slice(numGlyphsInLayout), false);
    }

    inline function setScrollPos(pos:Float):Void {

        currentScrollPos = pos;

        var scrollStartIndex:Int = Std.int(currentScrollPos);
        var id:Int = 0;
        var pageSegment:Array<String> = page.slice(scrollStartIndex, scrollStartIndex + numRows);
        var styleIndex:Int = lineStyleIndices[scrollStartIndex];

        styles.removeAllGlyphs();

        var styleCode:Int = Utf8.charCodeAt(STYLE, 0);

        var currentStyle:Style = region.getStyleByIndex(styleIndex);
        for (line in pageSegment) {
            var index:Int = 0;
            for (index in 0...Utf8.length(line)) {
                var charCode:Int = Utf8.charCodeAt(line, index);
                if (charCode == styleCode) {
                    currentStyle = region.getStyleByIndex(++styleIndex);
                } else {
                    var glyph:Glyph = glyphs[id++];
                    glyph.set_char(charCode, glyphTexture.font);
                    currentStyle.addGlyph(glyph);
                    glyph.set_z(0);
                }
            }
        }

        styles.updateGlyphs(0);

        taperScrollEdges();

        transform.identity();
        transform.append(baseTransform);
        transform.appendTranslation(0, (currentScrollPos - scrollStartIndex) / numRowsForLayout, 0);
    }

    inline function taperScrollEdges():Void {
        var offset:Float = ((currentScrollPos % 1) + 1) % 1;
        var lastRow:Int = (numRows - 1) * numCols;
        var glyph:Glyph;
        for (col in 0...numCols) {
            glyph = glyphs[col];
            glyph.set_color(glyph.get_r() * (1 - offset), glyph.get_g() * (1 - offset), glyph.get_b() * (1 - offset));

            glyph = glyphs[lastRow + col];
            glyph.set_color(glyph.get_r() * offset, glyph.get_g() * offset, glyph.get_b() * offset);
        }
    }

    inline function updateGlide():Void {
        if (gliding) {
            gliding = Math.abs(glideGoal - currentScrollPos) > 0.001;
            if (gliding) {
                setScrollPos(currentScrollPos * glideEase + glideGoal * (1 - glideEase));
            } else {
                setScrollPos(glideGoal);
                if (lastRedrawPos != glideGoal) {
                    lastRedrawPos = glideGoal;
                    redrawHitAreas();
                }
            }
        }
    }

    override public function interact(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y):
                if (dragging) {
                    switch (type) {
                        case DROP, CLICK:
                            dragging = false;
                        case ENTER, EXIT, MOVE:
                            glideTextToPos(dragStartPos + (dragStartY - y) * numRowsForLayout);
                        case _:
                    }
                } else if (id == 0) {
                    if (type == MOUSE_DOWN) {
                        dragging = true;
                        dragStartY = y;
                        dragStartPos = currentScrollPos;
                    }
                } else {
                    var targetStyle:Style = styles.getStyleByMouseID(id);
                    if (targetStyle != null) {
                        targetStyle.interact(type);
                        if (type == CLICK) trace('${targetStyle.name} clicked!');
                    }
                }
            case KEYBOARD(type, key, char, shift, alt, ctrl):
                if (type == KEY_DOWN || type == KEY_REPEAT) {
                    switch (key) {
                        case Keyboard.BACKSPACE:
                            // delete command
                            if (systemInput.length > 0) {
                                var lim:Int = -1;

                                if (ctrl) lim = 0;
                                else if (alt) lim = systemInput.lastIndexOf(' ');
                                else lim = systemInput.length - 1;

                                if (lim == -1) lim = 0;

                                systemInput = systemInput.substr(0, lim);
                            }
                            dirty = true;
                        case Keyboard.ENTER:
                            blurb += systemOutput + prompt + systemInput;
                            if (systemInput.length == 0) systemOutput = '\n';
                            else systemOutput = '\n' + interpret(systemInput) + '\n';
                            systemInput = '';
                            dirty = true;
                        case Keyboard.ESCAPE:
                            if (systemInput.length > 0) {
                                dirty = true;
                                systemInput = '';
                            }
                        case Keyboard.RIGHT:
                            if (type == KEY_DOWN) trace("Auto complete");
                        case _:
                            if (char > 0) {
                                systemInput += String.fromCharCode(char);
                                dirty = true;
                            }
                    }
                }
        }
    }

    inline function rpad(input:String, pad:String, len:Int):String {
        len = len - Utf8.length(input);
        var str:String = '';
        while (str.length < len) str = str + pad;
        return input + str;
    }

    inline function get_numLines():Int { return page.length; }

    inline function get_numScrollPositions():Int {
        return combinedTextLength < numRowsForLayout ? 1 : combinedTextLength - numRowsForLayout + 1;
    }

    inline function get_bottomPos():Float { return numScrollPositions - 1; }

    inline function getScreenDPI():Float {
        #if flash
            var dpi:Null<Float> = Reflect.field(flash.Lib.current.loaderInfo.parameters, 'dpi');
            if (dpi == null) dpi = NATIVE_DPI;
            return dpi;
        #elseif js
            return Capabilities.screenDPI;
        #else
            return NATIVE_DPI;
        #end
    }
}
