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

    public function testComponentTypes() {
        var pos = awe.ComponentType.of(Pos);
        var vel = awe.ComponentType.of(Vel);

        Assert.isFalse(pos.isEmpty());
        Assert.isFalse(vel.isEmpty());
    }
    
    public function testWorldEntity() {
        reset();
        Assert.equals(world.entities.count, 0);
        var entity: Entity = world.createEntityFromArchetype(Archetype.build(Pos, Vel));
        Assert.equals(world.entities.count, 1);
        Assert.isTrue(entity.has(Pos));
        Assert.isTrue(entity.has(Vel));
        Assert.isTrue(entity.componentBits != null);
        entity.remove(Pos);
        Assert.isFalse(entity.has(Pos));
        Assert.isTrue(entity.has(Vel));
        entity.deleteFromWorld();
        Assert.equals(entity.world, null);
        Assert.equals(world.entities.count, 0);
        entity.deleteFromWorld();
        Assert.equals(world.entities.count, 0);
    }
    public function testWorldArchetype() {
        reset();
        var entityArch = Archetype.build(Pos, Vel);
        for(i in 0...14) {
            var entity: Entity = world.createEntityFromArchetype(entityArch);
            trace(entity.componentBits.toString());
            Assert.isTrue(entity.has(Pos));
            Assert.isTrue(entity.has(Vel));
            entity.remove(Vel);
            Assert.isFalse(entity.has(Vel));
        }
    }
}