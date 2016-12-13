package;

import haxe.Timer;
import haxe.io.Bytes;
import haxe.unit.TestCase;
import tink.Chunk;

using StringTools;

class ChunkTest extends TestCase {

  function compare(string:String, chunk:Chunk) {
    assertEquals(string, chunk);
    
    for (start in 0...string.length)
      for (end in start...string.length) 
        assertEquals(string.substring(start, end), chunk.slice(start, end));    
      
  }
  
  function test() {
    var hello = 'hello, world!';
    var chunk:Chunk = hello;
    
    compare(hello, chunk);
    
    hello += hello;
    chunk = chunk.concat(chunk);
        
    compare(hello, chunk);

    chunk = chunk.slice(0, 7).concat(chunk.slice(7, 15)).concat(chunk.slice(15, 26));

    assertEquals(hello, chunk);
    var i = 0;
    for (c in chunk)
      assertEquals(hello.charCodeAt(i++), c);
      
    for (i in 0...4) {
      chunk = chunk.concat(chunk);
      hello += hello;
    }
    compare(hello, chunk);  
  }

}