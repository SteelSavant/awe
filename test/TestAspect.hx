import utest.Assert;

import awe.Component;
import awe.Aspect;

import de.polygonal.ds.BitVector;
class Comp1 implements Component {
    public function new() {}
}
class Comp2 implements Component {
    public function new() {}
}

class TestAspect {
	public function new() {}

	public function testNone() {
		var aspect = Aspect.build({
			none: [Comp1, Comp2]
		});
		var bits = new BitVector(2);
		Assert.isTrue(aspect.matches(bits));
		bits.set(new Comp1().getType());
		Assert.isFalse(aspect.matches(bits));
		bits.set(new Comp2().getType());
		Assert.isFalse(aspect.matches(bits));
	}
	public function testAll() {
		var aspect = Aspect.build({
			all: [Comp1, Comp2]
		});
		var bits = new BitVector(2);
		Assert.isFalse(aspect.matches(bits));
		bits.set(new Comp1().getType());
		Assert.isFalse(aspect.matches(bits));
		bits.set(new Comp2().getType());
		Assert.isTrue(aspect.matches(bits));
	}
	public function testOne() {
		var aspect = Aspect.build({
			one: [Comp1, Comp2]
		});
		var bits = new BitVector(2);
		Assert.isFalse(aspect.matches(bits));
		bits.set(new Comp1().getType());
		Assert.isTrue(aspect.matches(bits));
		bits.set(new Comp2().getType());
		Assert.isFalse(aspect.matches(bits));
	}
}