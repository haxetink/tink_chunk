package;

import haxe.io.Bytes;
import tink.unit.*;
import tink.Chunk;

using StringTools;

@:asserts
@:timeout(100000)
class ChunkTest {
  public function new() {}
  
  function compare(string:String, chunk:Chunk, asserts:AssertionBuffer) {
    asserts.assert(string == chunk);
    
    for (start in 0...string.length)
      for (end in start...string.length) {
        asserts.assert(string.substring(start, end) == chunk.slice(start, end));
      }
      
  }
  
  @:variant(function(str:String):Chunk return str)
  #if nodejs
  @:variant(function(str:String):Chunk return js.node.Buffer.from(str))
  #end
  public function chunkTests(create: String -> Chunk) {
    var hello = 'hello, world!';
    var chunk:Chunk = create(hello);
    
    compare(hello, chunk, asserts);
    
    hello += hello;
    chunk = chunk.concat(chunk);
        
    compare(hello, chunk, asserts);

    chunk = chunk.slice(0, 7).concat(chunk.slice(7, 15)).concat(chunk.slice(15, 26));

    asserts.assert(hello == chunk);
    var i = 0;
    for (c in chunk) {
      asserts.assert(hello.charCodeAt(i) == c);
      asserts.assert(hello.charCodeAt(i) == chunk[i]);
      i++;
    }
    
    var bytes = chunk.toBytes();
      
    asserts.assert(hello + hello == chunk & chunk);
    asserts.assert(hello + hello == hello & chunk);
    asserts.assert(hello + hello == chunk & hello);
    asserts.assert(hello + hello == chunk & bytes);
    asserts.assert(hello + hello == bytes & chunk);
      
    for (i in 0...3) {
      chunk = chunk.concat(chunk);
      hello += hello;
    }
    compare(hello, chunk, asserts);  
    return asserts.done();
  }
  
  @:variant(this.randomBytes(256))
  #if nodejs
  @:variant(this.randomBuffer(256))
  #end
  public function issue9(chunk:Chunk) {
    var bytes = Bytes.alloc(256);
    for(i in 0...bytes.length) bytes.set(i, Std.random(0xff));
    var chunk:Chunk = Chunk.EMPTY;
    for(i in 0...10000) chunk = chunk & chunk;
    var out = Bytes.alloc(chunk.length);
    chunk.blitTo(out, 0);
    var data = out.getData();
    
    for(i in 0...chunk.length)
      switch [chunk[i], Bytes.fastGet(data, i)] {
        case [expected, actual] if(expected != actual):
          asserts.fail(new tink.core.Error('Expected $expected but got $actual at position $i'));
        case _:
      }
    return asserts.done();
  }
  
  @:variant('00')
  @:variant('ff')
  @:variant('00ff')
  @:variant('ffff')
  public function ofHex(value:String) {
    asserts.assert(Chunk.ofHex(value).toHex() == value);
    return asserts.done();
  }
  
  function randomBytes(size:Int) {
    var bytes = haxe.io.Bytes.alloc(256);
    for(i in 0...bytes.length) bytes.set(i, Std.random(0xff));
    return bytes;
  }
  
  #if nodejs
  function randomBuffer(size:Int) {
    var buffer = js.node.Buffer.alloc(256);
    for(i in 0...buffer.length) buffer[i] = Std.random(0xff);
    return buffer;
  }
  #end
}