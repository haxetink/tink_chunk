# Tinkerbell Binary Chunks

This library provides an abstraction for readonly binary data, that can be sliced and concatenated without copying the actual payload.

```haxe
abstract Chunk {
  
  var length(get, never):Int;    
  function concat(that:Chunk):Chunk;
    
  function cursor():ChunkCursor;
  function iterator():Iterator;
      
  function slice(from:Int, to:Int):Chunk;    
  function blitTo(target:Bytes, offset:Int):Void;
  
  static var EMPTY(default, null):Chunk;  
    
  @:to function toString():String;
  @:to function toBytes():Bytes;
    
  @:from static private function ofBytes(b:Bytes):Chunk;
  @:from static private function ofString(s:String):Chunk;
    
  @:op(a & b) static private function catChunk(a:Chunk, b:Chunk):Chunk;    
  @:op(a & b) static private function rcatString(a:Chunk, b:String):Chunk;
  @:op(a & b) static private function lcatString(a:String, b:Chunk):Chunk;
  @:op(a & b) static private function lcatBytes(a:Bytes, b:Chunk):Chunk;
  @:op(a & b) static private function rcatBytes(a:Chunk, b:Bytes):Chunk; 
}

class ChunkIterator {
  var length(default, null):Int;
  var currentPos(default, null):Int;
  var currentByte(default, null):Int;
  function next():Bool;
}
```

