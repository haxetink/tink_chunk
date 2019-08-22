package;

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

  function testChunk() {
    chunkTests(function (str: String): Chunk return str);
    #if nodejs
    chunkTests(function (str: String): Chunk return new js.node.Buffer(str));
    #end
  }
  
  function chunkTests(create: String -> Chunk) {
    var hello = 'hello, world!';
    var chunk:Chunk = create(hello);
    
    compare(hello, chunk);
    
    hello += hello;
    chunk = chunk.concat(chunk);
        
    compare(hello, chunk);

    chunk = chunk.slice(0, 7).concat(chunk.slice(7, 15)).concat(chunk.slice(15, 26));

    assertEquals(hello, chunk);
    var i = 0;
    for (c in chunk) {
      assertEquals(hello.charCodeAt(i), c);
      assertEquals(hello.charCodeAt(i), chunk[i]);
      i++;
    }
    
    var bytes = chunk.toBytes();
      
    assertEquals(hello + hello, chunk & chunk);
    assertEquals(hello + hello, hello & chunk);
    assertEquals(hello + hello, chunk & hello);
    assertEquals(hello + hello, chunk & bytes);
    assertEquals(hello + hello, bytes & chunk);
      
    for (i in 0...3) {
      chunk = chunk.concat(chunk);
      hello += hello;
    }
    compare(hello, chunk);  
  }

  function testIssue9() {
    var bytes = Bytes.alloc(256);
    var chunk:Chunk = Chunk.EMPTY;
    for(i in 0...10000) chunk = chunk & bytes;
    var out = Bytes.alloc(chunk.length);
    chunk.blitTo(out, 0);    
    assertTrue(true);
  }

}