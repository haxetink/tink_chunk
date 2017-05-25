# Tinkerbell Binary Chunks

[![Build Status](https://travis-ci.org/haxetink/tink_chunk.svg?branch=master)](https://travis-ci.org/haxetink/tink_chunk)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/haxetink/public)

This library provides an abstraction for readonly binary data, that can be sliced and concatenated without copying the actual payload.

```haxe
abstract Chunk {
  
  var length(get, never):Int;    
  function concat(that:Chunk):Chunk;
    
  function cursor():ChunkCursor;//see below
  function iterator():Iterator;
      
  function slice(from:Int, to:Int):Chunk;    
  function blitTo(target:Bytes, offset:Int):Void;
  
  static var EMPTY(default, null):Chunk;  
  
  //Some implicit conversions:
  
  @:to function toString():String;
  @:to function toBytes():Bytes;
    
  @:from static private function ofBytes(b:Bytes):Chunk;
  @:from static private function ofString(s:String):Chunk;
    
  //A few defitions for `&` to concatenate with other chunks but also strings and bytes
  
  @:op(a & b) static private function catChunk(a:Chunk, b:Chunk):Chunk;    
  @:op(a & b) static private function rcatString(a:Chunk, b:String):Chunk;
  @:op(a & b) static private function lcatString(a:String, b:Chunk):Chunk;
  @:op(a & b) static private function lcatBytes(a:Bytes, b:Chunk):Chunk;
  @:op(a & b) static private function rcatBytes(a:Chunk, b:Bytes):Chunk; 
}

class ChunkCursor {
  var length(default, null):Int;
  var currentPos(default, null):Int;
  var currentByte(default, null):Int;
  function next():Bool;
}
```

The cursor is not unlike a normal iterator. It's API will however be expanded for seeking and other niceties. To iterate over just a part of a chunk just grab the `slice` you need first and then create a cursor or iterator.
