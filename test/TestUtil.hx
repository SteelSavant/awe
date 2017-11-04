import utest.Assert;

using awe.util.BitVectorTools;
using awe.util.MoreStringTools;

import de.polygonal.ds.BitVector;

class TestUtil {
	public function new() {

	}
    public function testBits() {
        var bits = new BitVector(16);
        Assert.equals(bits.numBits, 16);
        Assert.isFalse(bits.has(1));
        bits.set(2);
        Assert.isTrue(bits.has(2));
        bits.set(4);
        bits.set(6);
        bits.set(7);
        var subBits = new BitVector(6);
        subBits.set(2);
        subBits.set(4);
        subBits.set(6);
        Assert.isTrue(bits.contains(subBits));
        Assert.isFalse(subBits.contains(bits));
    }
    public function testString() {
        Assert.isTrue('a'.isVowel());
        Assert.isFalse('b'.isVowel());
        Assert.equals("position".pluralize(), "positions");
    }
}