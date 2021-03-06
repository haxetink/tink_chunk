package;

import tink.Chunk;

using tink.chunk.ChunkTools;

@:asserts
class ChunkToolsTest {
  public function new() {}
  
  @:variant('00', 0)
  @:variant('ff', 255)
  public function uint8(input:String, output:Int) {
    asserts.assert(hex(input).readUInt8(0) == output);
    asserts.assert(output.writeUInt8().toHex() == input);
    return asserts.done();
  }
  
  @:variant('00', 0)
  @:variant('7f', 127)
  @:variant('80', -128)
  @:variant('ff', -1)
  public function int8(input:String, output:Int) {
    asserts.assert(hex(input).readInt8(0) == output);
    asserts.assert(output.writeInt8().toHex() == input);
    return asserts.done();
  }
  
  @:variant('0000', 0)
  @:variant('ff7f', 32767)
  @:variant('0080', 32768)
  @:variant('ffff', 65535)
  public function uint16LE(input:String, output:Int) {
    asserts.assert(hex(input).readUInt16LE(0) == output);
    asserts.assert(output.writeUInt16LE().toHex() == input);
    return asserts.done();
  }
  
  @:variant('0000', 0)
  @:variant('ff7f', 32767)
  @:variant('0080', -32768)
  @:variant('ffff', -1)
  public function int16LE(input:String, output:Int) {
    asserts.assert(hex(input).readInt16LE(0) == output);
    asserts.assert(output.writeInt16LE().toHex() == input);
    return asserts.done();
  }
  
  @:variant('000000', 0)
  @:variant('ffff7f', 8388607)
  @:variant('000080', 8388608)
  @:variant('ffffff', 16777215)
  public function uint24LE(input:String, output:Int) {
    asserts.assert(hex(input).readUInt24LE(0) == output);
    asserts.assert(output.writeUInt24LE().toHex() == input);
    return asserts.done();
  }
  
  @:variant('000000', 0)
  @:variant('ffff7f', 8388607)
  @:variant('000080', -8388608)
  @:variant('ffffff', -1)
  public function int24LE(input:String, output:Int) {
    asserts.assert(hex(input).readInt24LE(0) == output);
    asserts.assert(output.writeInt24LE().toHex() == input);
    return asserts.done();
  }
  
  @:variant('00000000', 0)
  @:variant('ffffff7f', 2147483647)
  @:variant('00000080', -2147483648)
  @:variant('ffffffff', -1)
  public function int32LE(input:String, output:Int) {
    asserts.assert(hex(input).readInt32LE(0) == output);
    asserts.assert(output.writeInt32LE().toHex() == input);
    return asserts.done();
  }
  
  @:variant('0000000000000000', 0)
  @:variant('000000000000f0bf', -1)
  @:variant('000000000000f03f', 1)
  @:variant('ffffffffffff3f43', 9007199254740991)
  @:variant('ffffffffffff3fc3', -9007199254740991)
  @:variant('efcdab9078563412', 5.62634910890851593421708369942E-221)
  @:variant('1234567890abcdef', -3.59870942784831628062373076293E230)
  @:variant('000000000000f07f', Math.POSITIVE_INFINITY)
  @:variant('000000000000f0ff', Math.NEGATIVE_INFINITY)
  public function doubleLE(input:String, output:Float) {
    asserts.assert(hex(input).readDoubleLE(0) == output);
    asserts.assert(output.writeDoubleLE().toHex() == input);
    return asserts.done();
  }
  
  public function nanDoubleLE() {
    var inputs = [
      '010000000000f07f',
      '000000000000f87f',
      Math.NaN.writeDoubleLE().toHex(),
    ];
    
    for(input in inputs)
      asserts.assert(Math.isNaN(hex(input).readDoubleLE(0)));
    return asserts.done();
  }
  
  @:variant('41', 'A')
  @:variant('4100', 'A')
  public function cstring(input:String, output:String) {
    asserts.assert(hex(input).readNullTerminatedString(0) == output);
    return asserts.done();
  }
  
  inline function hex(v:String) return Chunk.ofHex(v);
}