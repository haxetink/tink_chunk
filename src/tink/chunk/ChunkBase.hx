package tink.chunk;

class ChunkBase {
  var flattened:Array<ByteChunk>;
  public function getCursor() {
    if (flattened == null) 
      flatten(this.flattened = []);
    return ChunkCursor.create(flattened);
  }
  public function flatten(into:Array<ByteChunk>) {}
}