import utest.Assert;

import awe.Component;


@Packed
class Packed implements Component {
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
    public function testPackedComponent() {
        var a = new Packed();
        a.a = 5;
        Assert.equals(a.a, 5);
        a.b = 120;
        Assert.equals(a.b, 120);
        a.c = true;
        Assert.isTrue(a.c);
    }

    public function testComponentBits() {
        var a = new Packed();
        Assert.isTrue(a.getType().isPacked());
        Assert.isFalse(a.getType().isEmpty());
        var b = new Empty();
        Assert.isFalse(b.getType().isPacked());
        Assert.isTrue(b.getType().isEmpty());
    }
}