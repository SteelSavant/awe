import utest.Assert;

import awe.Component;


@Pooled
class Pooled implements PooledComponent {
    public var a: Int;
    public var b: Float;
    public var c: Bool;
    public function new() {}
}
@Empty
class Empty implements Component {
    public function new() {}
}

class TestComponent {
	public function new() {

	}
    public function testPooledComponent() {
        var a = new Pooled();
        a.a = 5;
        Assert.equals(a.a, 5);
        a.b = 120;
        Assert.equals(a.b, 120);
        a.c = true;
        Assert.isTrue(a.c);
    }

    public function testComponentBits() {
        var a = new Pooled();
        Assert.isTrue(a.getType().isPooled());
        Assert.isFalse(a.getType().isEmpty());
        var b = new Empty();
        Assert.isFalse(b.getType().isPooled());
        Assert.isTrue(b.getType().isEmpty());
    }
}