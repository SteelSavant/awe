package;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import awe.World;
import awe.Archetype;
import awe.Entity;
using awe.util.BitVectorTools;
using awe.util.MoreStringTools;
import awe.util.Signal;
import de.polygonal.ds.BitVector;
import awe.Component;


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
        assertFalse(a.getType().isPacked());
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
    public function testWorld() {
        var world: World = World.build({
            systems: [],
            components: [Packed, Empty],
			expectedEntityCount: 1
        });
        assertEquals(world.entities.size, 0);
        var entity: Entity = Archetype.build(Packed, Empty).create(world);
        assertTrue(entity.has(world, Packed));
        assertTrue(entity.has(world, Empty));
        assertTrue(entity.getComposition(world) != null);
        assertEquals(world.entities.size, 1);
        world.getComponentList(Packed).remove(entity);
        assertFalse(entity.has(world, Packed));
        assertTrue(entity.has(world, Empty));
        entity.delete(world);
        assertEquals(entity.getComposition(world), null);
        assertEquals(world.entities.size, 0);
    }
    static function main() {
        var r = new TestRunner();
        r.add(new Test());
        r.run();
    }
}