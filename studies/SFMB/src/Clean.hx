package ;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.Shape;
import flash.filters.BlurFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.Lib;
import flash.Memory;
import flash.utils.ByteArray;
import haxe.macro.Expr;

/**
 * ...
 * @author 
 */

class Clean 
{
	private inline static var TEX_WID:Int = 40;
	private inline static var BLUR:Float = 0.4;
	private inline static var FRAME_WID:Int = 600;
	
	private inline static var BLUR_AMT:Int = Std.int(BLUR * TEX_WID);
	private inline static var GRAD_WID:Int = TEX_WID - BLUR_AMT;

	var screen:Bitmap;
	public function new(
		_rez:Int, 
		_state:Array<Int>, 
		_index:Int, 
		_frames:Int, 
		_frameSpacing:Int, 
		r:Float, g:Float, b:Float,
		?baseTex:BitmapData
	):Void {
		//Tests
		new TDD ();
		
		screen = new Bitmap (new BitmapData (FRAME_WID, FRAME_WID, true, 0x00000000));
		Lib.current.addChild (screen);
		
		
		
		runApp ();	//Matt is dumb.
	}
	
	function runApp ()
	{
		var mb:Shape = new Shape( );
		var mat:Matrix = new Matrix();
		mat.createGradientBox(GRAD_WID, GRAD_WID, 0, BLUR_AMT / 2, BLUR_AMT / 2);
		mb.graphics.beginGradientFill(GradientType.RADIAL, [0x0, 0x0], [1, 0], [0x0, 0xFF], mat);
		mb.graphics.drawCircle( TEX_WID / 2, TEX_WID / 2, TEX_WID / 2 );
		mb.graphics.endFill();
		
		var ball_bmd:BitmapData = new BitmapData( TEX_WID, TEX_WID, true, 0x00000000 );
		ball_bmd.draw(mb);
		ball_bmd.applyFilter(ball_bmd, ball_bmd.rect, ball_bmd.rect.topLeft, new BlurFilter(BLUR_AMT, BLUR_AMT, 1));
		
		var ball:Buffer = Buffer.allocate (TEX_WID * TEX_WID);
		var frameBuffer:Buffer = Buffer.allocate (FRAME_WID * FRAME_WID * 4);
		var intermediateBufferWithLongNameThatGetsFiltered:Buffer = Buffer.allocate (FRAME_WID * FRAME_WID * 4);
		var LUT:Buffer = Buffer.allocate (25600);
		genLookupTable (LUT, 0x20);
		
		//clearBuffer (frameBuffer, 0x0000FF00);		
		//clearBuffer (ball, 0x33333333);	//Never exceed 0xFF
		ball = bitmapToAlphaBuffer (ball_bmd);
		
		//addBlendBlit (intermediateBufferWithLongNameThatGetsFiltered, FRAME_WID, FRAME_WID, ball, TEX_WID, TEX_WID, 0, 0);
		var tm:Int = Lib.getTimer ();
		clearBuffer (intermediateBufferWithLongNameThatGetsFiltered, 0x00000000);
		var DIST:Int = 25;
		var cy:Int = 0;
		while (cy < 22) {
			var cx:Int = 0;
			while (cx < 22) {
				addBlendBlitAlphaChannel (intermediateBufferWithLongNameThatGetsFiltered, FRAME_WID, FRAME_WID, ball, TEX_WID, TEX_WID, cx * DIST, cy * DIST);
				cx++;
			}
			cy++;
		}
		tm = Lib.getTimer () - tm;
		trace (tm + " ms");
		
		intermediateFilterProcess (intermediateBufferWithLongNameThatGetsFiltered, frameBuffer, LUT);
		
		Buffer.draw (screen.bitmapData, frameBuffer);
	}
	
	static function bitmapToAlphaBuffer (bmd:BitmapData):Buffer
	{
		var width:Int = Std.int (bmd.width);
		var height:Int = Std.int (bmd.height);
		
		var buffer:Buffer = Buffer.allocate (width * height);
		var addr:Int = buffer.start;
		
		for (y in 0...height)
		{
			for (x in 0...width)
			{
				var val:UInt = bmd.getPixel32 (x, y);
				var alpha:Int = (val >>> 24);
				buffer.setByte (addr++, alpha);
			}
		}
		
		return buffer;
	}
	
	static function bitmapToBuffer (bmd:BitmapData):Buffer
	{
		var width:Int = Std.int (bmd.width);
		var height:Int = Std.int (bmd.height);
		
		var buffer:Buffer = Buffer.allocate (width * height);
		var addr:Int = buffer.start;
		
		for (y in 0...height)
		{
			for (x in 0...width)
			{
				var val:UInt = bmd.getPixel32 (x, y);
				buffer.setI32 (addr, alpha);
				addr+=4;
			}
		}
		
		return buffer;
	}
	
	static inline function addBlendBlitAlphaChannel (
							buffer:Buffer, fbrWidth:Int, fbrHeight:Int, 
							sprite:Buffer, sprWidth:Int, sprHeight:Int, 
							x:Int, y:Int)
	{
		
		var start_addr:Int = buffer.start + ((y * fbrWidth) + x) * 4;	//argb
		var fb_jump:Int = (fbrWidth - sprWidth) * 4;
		var end_addr:Int = ( (sprHeight * fbrWidth) * 4 ) + start_addr;
		var spr_addr:Int = sprite.start;
		
		while ( start_addr < end_addr )
		{
			var row_end_addr:Int = start_addr + (sprWidth * 4);
			
			while ( start_addr < row_end_addr )
			{
				var spv:Int;
				spv = sprite.getByte (spr_addr);
				var bpv:Int = buffer.getI32 (start_addr);
				
				var comb:Int = spv + bpv;
				buffer.setI32 (start_addr, comb);
				
				
				start_addr += 4;  spr_addr ++;
				
			}
			
			start_addr += fb_jump;
		}
	}
	
	
	static function addBlendBlit (
							buffer:Buffer, fbrWidth:Int, fbrHeight:Int, 
							sprite:Buffer, sprWidth:Int, sprHeight:Int, 
							x:Int, y:Int)
	{
		
		var start_addr:Int = buffer.start + ((y * fbrWidth) + x) * 4;	//argb
		var fb_jump:Int = (fbrWidth - sprWidth) * 4;
		var end_addr:Int = ( (sprHeight * fbrWidth) * 4 ) + start_addr;
		var spr_addr:Int = sprite.start;
		
		while ( start_addr < end_addr )
		{
			var row_end_addr:Int = start_addr + (sprWidth * 4);
			
			while ( start_addr < row_end_addr )
			{
				var spv:Int;
				spv = sprite.getI32 (spr_addr);
				var bpv:Int = buffer.getI32 (start_addr);
				
				var comb:Int = spv + bpv;
				buffer.setI32 (start_addr, comb);
				
				
				start_addr += 4;  spr_addr += 4;
				
			}
			
			start_addr += fb_jump;
		}
	}
	
	/**
	 * Obliterates Alpha channel of frameBuffer
	 * @param	intermediateBuffer
	 * @param	frameBuffer
	 * @param	LUT
	 */
	public static function intermediateFilterProcess (intermediateBuffer:Buffer, frameBuffer:Buffer, LUT:Buffer)
	{
		#if debug
		Assert.equals (intermediateBuffer.size, frameBuffer.size);
		#end
		
		var ib_start:Int = intermediateBuffer.start;
		
		var fb_start:Int = frameBuffer.start;
		var fb_end:Int = frameBuffer.end;
		
		var lut_start:Int = LUT.start;
		
		while (fb_start < fb_end) {
		
			var ibl:UInt;
			var lutv:UInt;
			
			ibl = intermediateBuffer.getI32 (ib_start);
			
			try {
			lutv = LUT.getByte (lut_start + ibl);
			}catch (e:Dynamic) { throw "ibl: " + ibl; }
			
			frameBuffer.setByte (fb_start, lutv);		//Writes Alpha channel (remember endian-ness)
			
			fb_start += 4;
			ib_start += 4;
		}
	}
	
	//CONFIRMED - BGRA
	public static function clearBuffer (buffer:Buffer, color:UInt) {
		var addr:Int = buffer.start;
		var eaddr:Int = buffer.end;
		
		while (addr < eaddr) {
			buffer.setI32 (addr, color);
			
			addr += 4;
		}
	}
	
	public static function genLookupTable (lutBuffer:Buffer, threshold:Int)
	{
		for ( i in 0...threshold)
		{
			lutBuffer.setByte (lutBuffer.start + i, 0x00);
		}
		
		//* ANTI ALIASING!!!
		lutBuffer.setByte (lutBuffer.start + threshold++, 0x20);
		lutBuffer.setByte (lutBuffer.start + threshold++, 0x40);
		lutBuffer.setByte (lutBuffer.start + threshold++, 0x60);
		lutBuffer.setByte (lutBuffer.start + threshold++, 0x80);
		lutBuffer.setByte (lutBuffer.start + threshold++, 0xA0);
		lutBuffer.setByte (lutBuffer.start + threshold++, 0xC0);
		lutBuffer.setByte (lutBuffer.start + threshold++, 0xE0);
		//*/
		
		var size:Int = lutBuffer.size;
		for ( i in threshold...size)
		{
			lutBuffer.setByte (lutBuffer.start + i, 0xFF);
		}
	}
}

class TDD
{
	public function new( )
	{
		test_clearBuffer ();
		test_intermediateFilterProcess ();
	}
	
	function test_intermediateFilterProcess ()
	{
	}
	
	function test_clearBuffer ()
	{
		var b:Buffer = Buffer.allocate (4);
		Clean.clearBuffer (b, 0xFFFF0000);
		Assert.equals (0xFFFF0000, b.getI32 (b.start));
	}
}


class Buffer {
	public var start(default,null):Int;
	public var end(default, null):Int;
	public var size(default,null):Int;
	function new (start:Int, end:Int) {
		this.start = start;
		this.end = end;
		this.size = end - start;
	}
	
	inline
	public function getI32 (addr:Int){
		#if debug
		Assert.bounds (start, end, addr, 4);
		#end
		return Memory.getI32 (addr);
	}
	
	inline
	public function setI32 (addr:Int, i:Int){
		#if debug
		Assert.bounds (start, end, addr, 4);
		#end
		Memory.setI32 (addr, i);
	}
	
	//#if !debug inline #end
	inline
	public function getByte (addr:Int){
		#if debug
		Assert.bounds (start, end, addr, 1);
		#end
		return Memory.getByte (addr);
	}
	
	inline
	public function setByte (addr:Int, b:Int){
		#if debug
		Assert.bounds (start, end, addr, 1);
		#end
		Memory.setByte (addr, b);
	}
	
	static var current_pos:Int;
	static var ba:ByteArray;
	public static function allocate (bytes:Int):Buffer {
		if (ba == null) {
			ba = new ByteArray( );
			ba.length = 100 * 1000 * 1000;
			Memory.select (ba);
		}
		
		var start = current_pos;
		var end = current_pos + bytes;
		current_pos += bytes;
		return new Buffer (start, end);
	}
	
	public static function draw (bmd:BitmapData, buffer:Buffer)
	{
		var sz:Int = Std.int (bmd.width) * Std.int (bmd.height) * 4;
		Assert.equals (sz, buffer.size);
		
		ba.position = buffer.start;
		bmd.setPixels (bmd.rect, ba);
		ba.position = 0;
	}
	
	/*
	public static function read (bmd:BitmapData, buffer:Buffer)
	{
		var sz:Int = Std.int (bmd.width) * Std.int (bmd.height) * 4;
		Assert.equals (sz, buffer.size);
		
		ba.position = buffer.start;
		bmd.setPixels (bmd.rect, ba);
		ba.position = 0;
	}
	*/
}

class Assert
{
	public static inline function bounds (start:Int, end:Int, addr:Int, bytes:Int) {
		if ( addr < start ) throw "OOB: Left";
		if ( addr + bytes > end ) throw "OOB: Right";
	}
	
	public static inline function equals (a:Dynamic, b:Dynamic) {
		if (a != b) throw a + " does not equal " + b;
	}
}









