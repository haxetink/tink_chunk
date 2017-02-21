package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class RunTests {
  static var cases:Array<Void->TestCase> = [
    ChunkTest.new,
    CursorTest.new
  ];
  static function main() {
    var runner = new TestRunner();
    
    for (c in cases)
      runner.add(c());
    
    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    );
  }
  
}