package;

import haxe.unit.TestCase;
import tink.Chunk;

using tink.CoreApi;

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

    for (noPrune in [true, false]) {

      function expect(length:Int, ?pos:haxe.PosInfos)
        switch c.seek(together, { withoutPruning: noPrune }) {
          case Some(v): assertEquals(length, v.length, pos);
          case None: assertTrue(false, pos);
        }

      expect(321);
      expect(123 + first.length + huge.length);
      c.moveTo(0);

    }

    assertEquals(204, c.length);
  }
  
  function testSweep() {
    var chunk:Chunk = '0123456789';
    var cursor = chunk.cursor();
    assertEquals('01234', cursor.sweep(5));
    assertEquals(5, cursor.currentPos);
    assertEquals('56', cursor.sweepTo(7));
    assertEquals(7, cursor.currentPos);
    
    var cursor = chunk.cursor();
    cursor.next();
    assertEquals('12345', cursor.sweep(5));
    assertEquals(6, cursor.currentPos);
    assertEquals('6', cursor.sweepTo(7));
    assertEquals(7, cursor.currentPos);
  }

  function testEdgeCase() {
    assertEquals(0, Chunk.EMPTY.cursor().left().length);
    assertEquals(0, Chunk.EMPTY.cursor().right().length);
  }
  
  function testInt32() {
    var chunk = Chunk.ofHex('00000005');
    var cursor = chunk.cursor();
    assertEquals(83886080, chunk.cursor().readInt32().sure());
    assertEquals(5, chunk.cursor().readInt32(false).sure());
  }
  
  function testUInt32() {
    var chunk = Chunk.ofHex('12345678');
    assertEquals(0x78563412, chunk.cursor().readUInt32().sure());
    assertEquals(0x12345678, chunk.cursor().readUInt32(false).sure());
  }
  
  function testInt16() {
    var chunk = Chunk.ofHex('0005');
    var cursor = chunk.cursor();
    assertEquals(1280, chunk.cursor().readInt16().sure());
    assertEquals(5, chunk.cursor().readInt16(false).sure());
  }
  
  function testUInt16() {
    var chunk = Chunk.ofHex('1234');
    assertEquals(0x3412, chunk.cursor().readUInt16().sure());
    assertEquals(0x1234, chunk.cursor().readUInt16(false).sure());
  }
  
  function testInt8() {
    var chunk = Chunk.ofHex('ff05');
    var cursor = chunk.cursor();
    assertEquals(-1, cursor.readInt8().sure());
    assertEquals(5, cursor.readInt8().sure());
  }
  
  function testUInt8() {
    var chunk = Chunk.ofHex('01fe');
    var cursor = chunk.cursor();
    assertEquals(1, cursor.readUInt8().sure());
    assertEquals(254, cursor.readUInt8().sure());
  }
}