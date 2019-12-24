package ;

import tink.unit.*;
import tink.testrunner.*;
import tink.testrunner.Reporter;

class RunTests {
  static function main() {
    Runner.run(TestBatch.make([
      new ChunkTest(),
      // new CursorTest(),
    ]), new CompactReporter()).handle(Runner.exit);
  }
  
}
