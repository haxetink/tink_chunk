package ;

import tink.unit.*;
import tink.testrunner.*;

class RunTests {
  static function main() {
    Runner.run(TestBatch.make([
      new ChunkTest(),
      // new CursorTest(),
    ]), new tink.testrunner.Reporter.CompactReporter()).handle(Runner.exit);
  }
  
}
