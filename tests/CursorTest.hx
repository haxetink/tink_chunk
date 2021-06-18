package;

import tink.Chunk;

using tink.CoreApi;

@:asserts
class CursorTest {
  public function new() {}
  
  public function cursor() {
    var chunk:Chunk = '0123456789';
    var cursor = Chunk.EMPTY.cursor();
    
    cursor.shift(chunk.concat(chunk).concat(chunk));
    
    for (i in 0...5)
      asserts.assert(cursor.next());
      
    asserts.assert(cursor.currentByte == '5'.code);
    asserts.assert(cursor.currentPos == 5);
    asserts.assert(cursor.length == 30);
    
    cursor.shift(chunk);
    
    asserts.assert(cursor.currentByte == '5'.code);
    asserts.assert(cursor.currentPos == 0);
    asserts.assert(cursor.length == 35);
    
    for (i in 0...20)
      asserts.assert(cursor.next());
      
    asserts.assert(cursor.currentByte == '5'.code);
    asserts.assert(cursor.currentPos == 20);
    
    for (i in 0...5)
      asserts.assert(cursor.next());
      
    asserts.assert(cursor.currentByte == '0'.code);
    cursor.shift(chunk);

    for (i in 0...100) {
      asserts.assert(cursor.currentByte == '0'.code);
      asserts.assert(cursor.currentPos == 0);
      asserts.assert(cursor.length == 20);
      
      for (i in 0...20)
        asserts.assert(i < 19 == cursor.next());
      
      asserts.assert(cursor.currentByte ==  -1);
      asserts.assert(cursor.currentPos == cursor.length);    
      
      cursor.moveTo(10);
      cursor.moveBy(-20);  
    }
    return asserts.done();
  }
  
  public function move() {
    var chunk:Chunk = '0123456789';
    var cursor = (chunk & chunk).cursor();
    
    asserts.assert(cursor.currentPos == 0);
    asserts.assert(cursor.left().toString() == '');
    asserts.assert(cursor.right().toString() == '01234567890123456789');
    cursor.moveBy(15);
    asserts.assert(cursor.currentPos == 15);
    asserts.assert(cursor.left().toString() == '012345678901234');
    asserts.assert(cursor.right().toString() == '56789');
    return asserts.done();
  }

  public function seek() {
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
          case Some(v): asserts.assert(v.length == length);
          case None: asserts.fail('Expect to seek succesfully');
        }

      expect(321);
      expect(123 + first.length + huge.length);
      c.moveTo(0);

    }

    asserts.assert(c.length == 204);
    return asserts.done();
  }
  
  @:variant('ab', 'b', 'a')
  @:variant('abc', 'bc', 'a')
  public function seekableAtEnd(input:Chunk, seekable:Chunk, result:Chunk) {
    return switch input.cursor().seek(seekable) {
      case Some(chunk):
        asserts.assert(chunk.toString() == result.toString());
        asserts.done();
      case None:
        asserts.fail('Expect to seek successfully: input=$input, seekable=$seekable, result=$result');
    }
  }
  
  public function sweep() {
    var chunk:Chunk = '0123456789';
    var cursor = chunk.cursor();
    asserts.assert(cursor.sweep(5) == '01234');
    asserts.assert(cursor.currentPos == 5);
    asserts.assert(cursor.sweepTo(7) == '56');
    asserts.assert(cursor.currentPos == 7);
    
    var cursor = chunk.cursor();
    cursor.next();
    asserts.assert(cursor.sweep(5) == '12345');
    asserts.assert(cursor.currentPos == 6);
    asserts.assert(cursor.sweepTo(7) == '6');
    asserts.assert(cursor.currentPos == 7);
    return asserts.done();
  }

  public function edgeCase() {
    asserts.assert(Chunk.EMPTY.cursor().left().length == 0);
    asserts.assert(Chunk.EMPTY.cursor().right().length == 0);
    return asserts.done();
  }
}