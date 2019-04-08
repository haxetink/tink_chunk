package tink;

import haxe.io.Bytes;
import haxe.io.BytesData;
import tink.chunk.*;

private class EmptyChunk extends ChunkBase implements ChunkObject {
  public function new() {
    #if python
    super(); // https://github.com/HaxeFoundation/haxe/issues/7541
    #end
  }
  
  public function getByte(i:Int)
    return 0;
    
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
  
  public function getByte(i:Int)
    return i < split ? left.getByte(i) : right.getByte(i - split);
  
  public function getLength()
    return this.length;
    
  public function new(left:Chunk, right:Chunk) {
    #if python
    super(); // https://github.com/HaxeFoundation/haxe/issues/7541
    #end
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

@:pure
abstract Chunk(ChunkObject) from ChunkObject to ChunkObject {
  
  public var length(get, never):Int;
    inline function get_length()
      return this.getLength();
      
  @:arrayAccess
  public inline function getByte(i:Int):Int
    return this.getByte(i);
      
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
  
  public inline function toHex()
    return this.toBytes().toHex();
    
  @:to public inline function toString()
    return this.toString();
    
  @:to public inline function toBytes()
    return this.toBytes();
  
  #if (nodejs && !macro)
  @:to public inline function toBuffer()
    return js.node.Buffer.hxFromBytes(this.toBytes());
  #end
    
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

  @:from public static inline function ofBytes(b:Bytes):Chunk 
    return (ByteChunk.of(b) : ChunkObject);
    
  @:from public static inline function ofString(s:String):Chunk 
    return ofBytes(Bytes.ofString(s));
    
  #if (nodejs && !macro)
  @:from public static inline function ofBuffer(s:js.node.Buffer):Chunk 
    return new tink.chunk.nodejs.BufferChunk(s);
  #end
    
  public static function ofHex(s:String):Chunk {
    var length = s.length >> 1;
    var bytes = Bytes.alloc(length);
    for(i in 0...length) bytes.set(i, Std.parseInt('0x' + s.substr(i * 2, 2)));
    return bytes;
  }
    
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
    
  #if tink_json
  
  @:to inline function toRepresentation():tink.json.Representation<Bytes> 
    return new tink.json.Representation(toBytes());
    
  @:from static inline function ofRepresentation<T>(rep:tink.json.Representation<Bytes>):Chunk
    return ofBytes(rep.get());
    
  #end
    
  static public var EMPTY(default, null):Chunk = ((new EmptyChunk() : ChunkObject) : Chunk);//haxe 3.2.1 ¯\_(ツ)_/¯
}