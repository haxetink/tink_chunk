package tink.chunk;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import tink.Chunk;

// TODO: integrate into Chunk ultimately
// Source: https://github.com/nodejs/node/blob/44161274821a2e81e7a5706c06cf8aa8bd2aa972/lib/internal/buffer.js
class ChunkTools {
	public static function readUInt8(chunk:Chunk, offset:Int):Int {
		check(chunk, offset, 1);
		var val = chunk[offset];
		return val;
	}
	
	public static function readInt8(chunk:Chunk, offset:Int):Int {
		var val = readUInt8(chunk, offset);
		return val > 0x7f ? val - 0x100 : val;
	}
	
	public static function readUInt16LE(chunk:Chunk, offset:Int):Int {
		check(chunk, offset, 2);
		var first = chunk[offset];
		var last = chunk[offset + 1];
		return first + (last << 8);
	}
	
	public static function readInt16LE(chunk:Chunk, offset:Int):Int {
		var val = readUInt16LE(chunk, offset);
		return val > 0x7fff ? val - 0x10000 : val;
	}
	
	public static function readUInt24LE(chunk:Chunk, offset:Int):Int {
		check(chunk, offset, 3);
		var first = chunk[offset];
		var mid = chunk[offset + 1];
		var last = chunk[offset + 2];
		return first + (mid << 8) + (last << 16);
	}
	
	public static function readInt24LE(chunk:Chunk, offset:Int):Int {
		var val = readUInt24LE(chunk, offset);
		return val > 0x7fffff ? val - 0x1000000 : val;
	}
	
	public static function readInt32LE(chunk:Chunk, offset:Int):Int {
		check(chunk, offset, 4);

		var val = chunk[offset] +
			(chunk[offset+1] << 8) +
			(chunk[offset+2] << 16) +
			(chunk[offset+3] << 24); // Overflow
			
		return
			#if python
				val > (python.Syntax #if haxe4 .code #else .pythonCode #end('0x7fffffff'):Int) ? val - (python.Syntax #if haxe4 .code #else .pythonCode #end('0x100000000'):Int) : val;
			#else
				val;
			#end
	}
	
	public static function readNullTerminatedString(chunk:Chunk, offset:Int):String {
		return try new BytesInput(chunk, offset).readUntil(0) catch(e:Dynamic) chunk.toString();
	}
	
	public static function writeUInt8(v:Int):Chunk {
		var bytes = Bytes.alloc(1);
		bytes.set(0, v & 0xff);
		return bytes;
	}
	
	public static function writeInt8(v:Int):Chunk {
		var bytes = Bytes.alloc(1);
		v = v & 0xff;
		if(v < 0) v += 0x100;
		bytes.set(0, v);
		return bytes;
	}
	
	public static function writeUInt16LE(v:Int):Chunk {
		var bytes = Bytes.alloc(2);
		bytes.set(0, v & 0xff);
		bytes.set(1, (v >>> 8) & 0xff);
		return bytes;
	}
	
	public static inline function writeInt16LE(v:Int):Chunk {
		return writeUInt16LE(v);
	}
	
	public static function writeUInt24LE(v:Int):Chunk {
		var bytes = Bytes.alloc(3);
		bytes.set(0, v & 0xff);
		bytes.set(1, (v >>> 8) & 0xff);
		bytes.set(2, (v >>> 16) & 0xff);
		return bytes;
	}
	
	public static inline function writeInt24LE(v:Int):Chunk {
		return writeUInt24LE(v);
	}
	
	public static inline function writeInt32LE(v:Int):Chunk {
		var bytes = Bytes.alloc(4);
		bytes.set(0, v & 0xff);
		bytes.set(1, (v >>> 8) & 0xff);
		bytes.set(2, (v >>> 16) & 0xff);
		bytes.set(3, (v >>> 24) & 0xff);
		return bytes;
	}
	
	static inline function check(chunk:Chunk, offset:Int, length:Int) {
		if(chunk.length < offset + length) throw 'Out of range (chunk length = ${chunk.length}, read offset = ${offset}, read length = ${length})';
	}
}