import utest.Assert;

import awe.World;
import awe.Component;
import awe.Archetype;
import awe.Entity;


class Pos implements Component {
    public var x: Float;
    public var y: Float;
    public function new() {}
}
class Vel implements Component {
    public var x: Float;
    public var y: Float;
    public function new() {}
}

class TestWorld {
    var world: World;
    function reset() {
        world = World.build({
            systems: [],
            components: [Pos, Vel],
            expectedEntityCount: 16
        });
    }
    public function new() {    }
    public function testWorldEntity() {
        reset();
        var entity: Entity = Archetype.build(Pos, Vel).create(world);
        Assert.isTrue(entity.has(Pos));
        Assert.isTrue(entity.has(Vel));
        Assert.isTrue(entity.componentBits != null);
        world.getComponentList(Pos).remove(entity);
        Assert.isFalse(entity.has(Pos));
        Assert.isTrue(entity.has(Vel));
        entity.deleteFromWorld();
        Assert.equals(entity.componentBits, null);
    }
    public function testWorldEntities() {
        reset();
        var entityArch = Archetype.build(Pos, Vel);
        for(i in 0...14) {
            var entity: Entity = entityArch.create(world);
            Assert.isTrue(entity.has(Pos));
            Assert.isTrue(entity.has(Vel));
        }
    }
}