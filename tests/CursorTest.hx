package;

import haxe.io.Bytes;
import haxe.unit.TestCase;
import tink.Chunk;

using StringTools;

class CursorTest extends TestCase {
  
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

    for (i in 0...100) {
      assertEquals('0'.code, cursor.currentByte);
      assertEquals(0, cursor.currentPos);
      assertEquals(20, cursor.length);
      
      for (i in 0...20)
        assertEquals(cursor.next(), i < 19);
      
      assertEquals( -1, cursor.currentByte);
      assertEquals(cursor.length, cursor.currentPos);    
      
      cursor.moveTo(10);
      cursor.moveBy(-20);  
    }
  }

}