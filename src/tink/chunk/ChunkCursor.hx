package tink.chunk;

class ChunkCursor {
  
  var parts:Array<ByteChunk>;
  var curPart:ByteChunk;
  var curPartIndex:Int = 0;
  var curOffset:Int = 0;
  var curLength:Int = 0;
  
  public var length(default, null):Int = 0;
  public var currentPos(default, null):Int = 0;
  public var currentByte(default, null):Int = -1;
  
  static public function create(parts) {
    var ret = new ChunkCursor();
    ret.parts = parts;
    ret.reset();
    return ret;
  }

  public function clone() {
    var ret = new ChunkCursor();
    ret.parts = this.parts.copy();
    ret.curPart = this.curPart;
    ret.curPartIndex = this.curPartIndex;
    ret.curOffset = this.curOffset;
    ret.curLength = this.curLength;
    ret.length = this.length;
    ret.currentPos = this.currentPos;
    ret.currentByte = this.currentByte;
    return ret;
  }

  function new() {}
    
  function reset() {
    length = 0;
    currentPos = 0;
    currentByte = -1;
    curOffset = 0;
    
    for (p in parts)
      length += p.getLength();
    
    this.curPart = parts[this.curPartIndex = 0];
    if (this.curPart != null) {
      this.curLength = this.curPart.getLength();
      this.currentByte = this.curPart.getByte(0);
    }    
  }
  
  public function shift(?chunk:Chunk) {

    parts.splice(0, curPartIndex);//throw out all old chunks
    
    switch parts[0] {
      case null:
      case chunk:
        switch chunk.getSlice(curOffset, curLength) {//get rid of old data in current chunk
          case null:
            parts.shift();
          case rest:
            parts[0] = rest;
        }
    }
    
    if (chunk != null)
      (chunk : ChunkObject).flatten(parts);//load new data
    
    reset();
  }

  public function clear() {
    parts = [];
    reset();
  }

  public function left() {
    var left = [for (i in 0...curPartIndex) (parts[i]:Chunk)];
    left.push(curPart.slice(0, curOffset));
    return Chunk.join(left);
  }
  
  public function right() {
    var right = [for (i in curPartIndex...parts.length) (parts[i]:Chunk)];
    if (right.length > 0) {
      right[0] = curPart.slice(curOffset, curPart.getLength());
    }
    return Chunk.join(right);
  }

  // public function seek(seekable:Array<Int>) {

  //   var copy = clone(),
  //       max = seekable.length;
  //       candidates = [];

  //   copy.shift();

  //   do {
  //     var b = copy.currentByte;
      
  //     candidates = [
  //       for (pos in candidates) 
  //         if (seekable[pos] == b) 
  //           if (pos == max) {
  //             var before = copy.left()
  //           }
  //           else pos + 1
  //         else continue
  //     ];

  //     // if (candidates.length > 0 && candidates[0] == max)
  //   } while (next());

    
  // }
  
  public inline function moveBy(delta:Int) 
    moveTo(currentPos + delta);

  public function moveTo(position:Int) {
    
    if (length == 0) return 0;

    if (position > length) position = length - 1;
    if (position < 0) position = 0;
    
    this.currentPos = position;

    for (i in 0...parts.length) {
      var c = parts[i];
      switch c.getLength() {
        case enough if (enough > position):
          this.curPart = c;
          this.curPartIndex = i;
          this.curOffset = position;
          this.currentByte = c.getByte(position);
        case v: 
          position -= v;
      }
    }

    return this.currentPos;
  }

  public function next():Bool {
    if (currentPos == length) return false;
    currentPos++;
    if (currentPos == length) {
      currentByte = -1;
      curOffset = 0;
      curPart = null;
      curPartIndex = parts.length;//right?
      return false;
    }
    if (curOffset == curLength - 1) {
      curOffset = 0;
      curPart = parts[++curPartIndex];
      curLength = curPart.getLength();
      currentByte = curPart.getByte(0);
    }
    else {
      currentByte = curPart.getByte(++curOffset);
    }
    return true;
  }
}