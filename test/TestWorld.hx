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
    public function new() {
        world = World.build({
            systems: [],
            components: [Pos, Vel],
            expectedEntityCount: 16
        });
    }
    public function testWorldEntity() {
        world.entities.clear();
        Assert.equals(world.entities.size, 0);
        var entity: Entity = Archetype.build(Pos, Vel).create(world);
        Assert.isTrue(entity.has(world, Pos));
        Assert.isTrue(entity.has(world, Vel));
        Assert.isTrue(entity.getComposition(world) != null);
        Assert.equals(world.entities.size, 1);
        world.getComponentList(Pos).remove(entity);
        Assert.isFalse(entity.has(world, Pos));
        Assert.isTrue(entity.has(world, Vel));
        entity.delete(world);
        Assert.equals(entity.getComposition(world), null);
        Assert.equals(world.entities.size, 0);
    }
    public function testWorldEntities() {
        Assert.equals(world.entities.size, 0);
        var entityArch = Archetype.build(Pos, Vel);
        world.entities.clear();
        for(i in 0...14) {
            var entity: Entity = entityArch.create(world);
            Assert.isTrue(entity.has(world, Pos));
            Assert.isTrue(entity.has(world, Vel));
        }
        Assert.equals(world.entities.size, 14);
    }
}