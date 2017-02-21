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
  
  function testCursor() {
    var chunk:Chunk = '0123456789';
    var cursor = Chunk.EMPTY.cursor();
    
    cursor.shift(chunk.concat(chunk).concat(chunk));
    
    for (i in 0...5)
      assertTrue(cursor.next());
      
    assertEquals('5'.code, cursor.currentByte);
    assertEquals(5, cursor.currentPos);
    assertEquals(30, cursor.length);
    
    cursor.shift(chunk);
    
    assertEquals('5'.code, cursor.currentByte);
    assertEquals(0, cursor.currentPos);
    assertEquals(35, cursor.length);
    
    for (i in 0...20)
      assertTrue(cursor.next());
      
    assertEquals('5'.code, cursor.currentByte);
    assertEquals(20, cursor.currentPos);
    
    for (i in 0...5)
      assertTrue(cursor.next());
      
    assertEquals('0'.code, cursor.currentByte);
    cursor.shift(chunk);
    assertEquals('0'.code, cursor.currentByte);
    assertEquals(0, cursor.currentPos);
    assertEquals(20, cursor.length);
    
    for (i in 0...20)
      assertEquals(cursor.next(), i < 19);
    
    assertEquals( -1, cursor.currentByte);
    assertEquals(cursor.length, cursor.currentPos);    
  }
  
  function testBasic() {
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

}