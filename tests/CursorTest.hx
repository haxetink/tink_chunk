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

  function testSeek() {
    var first = 'abcdefghijklmnopqrstuvwxyz';
    var second = first.toUpperCase();
    
    var together = first + second;

    function noise(length:Int):Chunk {
      var ret = '';
      while (ret.length <= length) {
        ret += together.substr(0, Std.random(together.length));
      }
      return ret.substr(0, length);
    }

    var pack = noise(1 << 16);
    var count = 
      #if (interp || php)
        16;
      #elseif (js || java || cs)
        1024;
      #else
        128;
      #end
    var huge = Chunk.join([for (i in 0...count) pack]);
    var total:Chunk = noise(321) & first & second & noise(123) & first & huge & first & second & noise(200) & 'werf';
    var c = total.cursor();
    
    function seekable(s:String) {
      return [for (i in 0...s.length) s.charCodeAt(i)];
    }
        
    function expect(length:Int, ?pos:haxe.PosInfos)
      switch c.seek(together) {
        case Some(v): assertEquals(length, v.length, pos);
        case None: assertTrue(false, pos);
      }

    expect(321);
    var start = haxe.Timer.stamp();
    expect(123 + first.length + huge.length);
  }
}