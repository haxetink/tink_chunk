package tink;

import haxe.io.Bytes;
import haxe.io.BytesData;

interface ChunkObject {
  function getCursor():ChunkCursor;
  function flatten(into:Array<ByteChunk>):Void;
  function getLength():Int;
  function slice(from:Int, to:Int):Chunk;
  function toString():String;
  function toBytes():Bytes;
  function blitTo(target:Bytes, offset:Int):Void;
}
class ChunkIterator {
  
  var target:ChunkCursor;
  var _hasNext:Bool;
  
  public inline function new(target) {
    this.target = target;
    this._hasNext = target.length > target.currentPos;
  }
  
  public inline function hasNext()
    return _hasNext;
    
  public inline function next() {
    var ret = target.currentByte;
    _hasNext = target.next();
    return ret;
  }
}

class ChunkCursor {
  
  var parts:Array<ByteChunk>;
  var curPart:ByteChunk;
  var curPartIndex:Int = 0;
  var curOffset:Int = 0;
  var curLength:Int = 0;
  
  public var length(default, null):Int = 0;
  public var currentPos(default, null):Int = 0;
  public var currentByte(default, null):Int = -1;
  
  public function new(parts) {
    
    this.parts = parts;
    
    reset();    
  }
    
  function reset() {
    length = 0;
    currentPos = 0;
    currentByte = -1;
    curOffset = 0;
    
    for (p in parts)
      length += p.getLength();
    
    this.curPart = parts[this.curPartIndex = 0];
    if (this.curPart != null) {
      this.curLength = this.curPart.getLength();
      this.currentByte = this.curPart.getByte(0);
    }    
  }
  
  public function shift(chunk:Chunk) {
    
    parts.splice(0, curPartIndex);//throw out all old chunks
    
    switch parts[0] {
      case null:
      case chunk:
        switch chunk.getSlice(curOffset, curLength) {//get rid of old data in current chunk
          case null:
            parts.shift();
          case rest:
            parts[0] = rest;
        }
    }
    
    (chunk : ChunkObject).flatten(parts);//load new data
    
    reset();
  }

  public function flush() {
    var left = [for (i in curPartIndex...parts.length) (parts[i]:Chunk)];
    if (left.length > 0) {
      left[0] = curPart.slice(curOffset, curPart.getLength());
    }
    parts = [];
    reset();
    return Chunk.join(left);
  }
  
  public function next():Bool {
    if (currentPos == length) return false;
    currentPos++;
    if (currentPos == length) {
      currentByte = -1;
      curOffset = parts.length;//right?
      return false;
    }
    if (curOffset == curLength - 1) {
      curOffset = 0;
      curPart = parts[++curPartIndex];
      curLength = curPart.getLength();
      currentByte = curPart.getByte(0);
    }
    else {
      currentByte = curPart.getByte(++curOffset);
    }
    return true;
  }
}

private class ChunkBase {
  var flattened:Array<ByteChunk>;
  public function getCursor() {
    if (flattened == null) 
      flatten(this.flattened = []);
    return new ChunkCursor(flattened);
  }
  public function flatten(into:Array<ByteChunk>) {}
}

private class EmptyChunk extends ChunkBase implements ChunkObject {
  public function new() { }
    
  public function getLength()
    return 0;
    
  public function slice(from:Int, to:Int):Chunk
    return this;
    
  public function blitTo(target:Bytes, offset:Int):Void {}
    
  public function toString()
    return '';
    
  public function toBytes()
    return EMPTY;
    
  static var EMPTY = Bytes.alloc(0);
}

private class CompoundChunk extends ChunkBase implements ChunkObject {
  var left:Chunk;
  var right:Chunk;
  
  var split:Int;
  var length:Int;
  
  public function getLength()
    return this.length;
    
  public function new(left:Chunk, right:Chunk) {
    //TODO: try balancing here
    this.left = left;
    this.right = right;
    this.split = left.length;
    this.length = split + right.length;
  }
  
  override public function flatten(into:Array<ByteChunk>) {
    (left:ChunkObject).flatten(into);
    (right:ChunkObject).flatten(into);
  }
    
  public function slice(from:Int, to:Int):Chunk 
    return
      left.slice(from, to).concat(right.slice(from - split, to - split));
    
  public function blitTo(target:Bytes, offset:Int):Void {
    left.blitTo(target, offset);
    right.blitTo(target, offset + split);
  }
    
  public function toString() 
    return toBytes().toString();
    
  public function toBytes() {
    var ret = Bytes.alloc(this.length);
    blitTo(ret, 0);
    return ret;
  }
  
}

private class ByteChunk extends ChunkBase implements ChunkObject {
  //TODO: on JS this pretty much reinvents the wheel
  
  var data:BytesData;
  var from:Int;
  var to:Int;
  
  var wrapped(get, null):Bytes;
    inline function get_wrapped() {
      if (wrapped == null)
        wrapped = Bytes.ofData(data);
      return wrapped;
    }
  
  function new(data, from, to) {
    this.data = data;
    this.from = from;
    this.to = to;
  }
  
  public inline function getByte(index:Int)
    return Bytes.fastGet(data, from + index);
  
  override public function flatten(into:Array<ByteChunk>) 
    into.push(this);
  
  public function getLength():Int 
    return to - from;
  
  public function getSlice(from:Int, to:Int) { 
    if (to > this.getLength())
      to = this.getLength();
      
    if (from < 0)
      from = 0;
      
    return
      if (to <= from) null;
      else if (to == this.getLength() && from == 0) this;
      else new ByteChunk(data, this.from + from, to + this.from);
  }
    
  public function slice(from:Int, to:Int):Chunk 
    return
      switch getSlice(from, to) {
        case null: Chunk.EMPTY;
        case v: v;
      }
  
  public function blitTo(target:Bytes, offset:Int):Void 
    target.blit(offset, wrapped, from, getLength());
  
  public function toBytes():Bytes 
    return wrapped.sub(from, getLength());
  
  public function toString():String 
    return wrapped.getString(from, getLength());
  
  static public function of(b:Bytes):Chunk {
    if (b.length == 0)
      return Chunk.EMPTY;
    var ret = new ByteChunk(b.getData(), 0, b.length);
    ret.wrapped = b;
    return ret;
  }
  
}

abstract Chunk(ChunkObject) from ChunkObject to ChunkObject {
  
  public var length(get, never):Int;
    inline function get_length()
      return this.getLength();
      
  public function concat(that:Chunk) 
    return switch [length, that.length] {
      case [0, 0]: EMPTY;
      case [0, _]: that;
      case [_, 0]: this;
      case _: new CompoundChunk(this, that);
    }
    
  public inline function cursor()  
    return this.getCursor();
  
  public inline function iterator()
    return new ChunkIterator(this.getCursor());
      
  public inline function slice(from:Int, to:Int):Chunk 
    return this.slice(from, to);
    
  public inline function blitTo(target:Bytes, offset:Int)
    return this.blitTo(target, offset);
  
  @:to public inline function toString()
    return this.toString();
    
  @:to public inline function toBytes()
    return this.toBytes();
    
  static public function join(chunks:Array<Chunk>)
    return switch chunks {
      case null | []: EMPTY;
      case [v]: v;
      case v:
        var ret = v[0] & v[1];
        for (i in 2...v.length)
          ret = ret & v[i];
        ret;
    }

  @:from static inline function ofBytes(b:Bytes):Chunk 
    return (ByteChunk.of(b) : ChunkObject);
    
  @:from static inline function ofString(s:String):Chunk 
    return ofBytes(Bytes.ofString(s));
    
  @:op(a & b) static function catChunk(a:Chunk, b:Chunk)
    return a.concat(b);
    
  @:op(a & b) static function rcatString(a:Chunk, b:String)
    return catChunk(a, b);
    
  @:op(a & b) static function lcatString(a:String, b:Chunk)
    return catChunk(a, b);
    
  @:op(a & b) static function lcatBytes(a:Bytes, b:Chunk)
    return catChunk(a, b);
    
  @:op(a & b) static function rcatBytes(a:Chunk, b:Bytes)
    return catChunk(a, b);
    
  static public var EMPTY(default, null):Chunk = ((new EmptyChunk() : ChunkObject) : Chunk);//haxe 3.2.1 ¯\_(ツ)_/¯
}