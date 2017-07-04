package;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
using awe.util.BitVectorTools;
using awe.util.MoreStringTools;
import awe.util.Signal;
import de.polygonal.ds.BitVector;
import awe.Component;

@Packed
class Packed implements Component {
    public var a: Int;
    public function new() {}
}
@Empty
class Empty implements Component {
    public function new() {}
}
class Test extends TestCase {
    public function testComponentBits() {
        var a = new Packed();
        assertTrue(a.getType().isPacked());
        assertFalse(a.getType().isEmpty());
        var b = new Empty();
        assertFalse(b.getType().isPacked());
        assertTrue(b.getType().isEmpty());
    }
    public function testBits() {
        var bits = new BitVector(16);
        assertEquals(bits.numBits, 16);
        assertFalse(bits.has(1));
        bits.set(2);
        assertTrue(bits.has(2));
        bits.set(4);
        bits.set(6);
        bits.set(7);
        var subBits = new BitVector(6);
        subBits.set(2);
        subBits.set(4);
        subBits.set(6);
        assertTrue(bits.contains(subBits));
        assertFalse(subBits.contains(bits));
    }
    public function testSignal() {
        var signal = new Signal();
        var result;
        signal.add(function(v) result = v);
        signal.dispatch(16);
        assertEquals(result, 16);
        assertEquals(signal.getListeners().size, 1);
        signal.clear();
        result = 0;
        signal.dispatch(16);
        assertEquals(result, 0);
        assertEquals(signal.getListeners().size, 0);
    }
    public function testString() {
        assertTrue('a'.isVowel());
        assertFalse('b'.isVowel());
        assertEquals("position".pluralize(), "positions");
    }
    static function main() {
        var r = new TestRunner();
        r.add(new Test());
        r.run();
    }
}