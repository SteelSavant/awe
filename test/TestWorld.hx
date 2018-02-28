import utest.Assert;

import awe.Aspect;
import awe.Archetype;
import awe.World;
import awe.Component;
import awe.ComponentList;
import awe.Archetype;
import awe.Entity;
import awe.System;


class Pos implements PooledComponent {
    public var x: Float = -1;
    public var y: Float = -1;
    public function new() {}
}
class Vel implements Component {
    public var x: Float;
    public var y: Float;
    public function new() {}
}

class Movement extends EntitySystem {
    public function new() {
        super(Aspect.build(Pos & Vel));
    }
}

class TestWorld {
    var world: World;
    function reset() {
        world = World.build({
            systems: [
                new Movement()
            ],
            components: [Pos, Vel],
            expectedEntityCount: 16
        });
    }
    public function new() {    }

    public function testComponentTypes() {
        var pos = awe.ComponentType.of(Pos);
        var vel = awe.ComponentType.of(Vel);

        Assert.isFalse(pos.isEmpty());
        Assert.isTrue(pos.isPooled());
        Assert.isFalse(vel.isEmpty());
        Assert.isFalse(vel.isPooled());
    }
    public function testWorldComponentPools() {
        var pos = new Pos();
        pos.x = 10;
        pos.y = 10;
        pos.reset();
        Assert.equals(pos.x, -1);
        Assert.equals(pos.y, -1);
    }
    
    public function testWorldEntity() {
        reset();
        Assert.equals(world.entities.count, 0);
        var entity: Entity = world.createEntityFromArchetype(Archetype.build(Pos, Vel));
        Assert.isTrue(entity != null);
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
    }
    public function testWorldArchetype() {
        reset();
        var entityArch = Archetype.build(Pos, Vel);
        for(i in 0...14) {
            var entity: Entity = world.createEntityFromArchetype(entityArch);
            Assert.isTrue(entity.has(Pos));
            Assert.isTrue(entity.has(Vel));
            var movement = world.getSystem(Movement);
            Assert.notEquals(-1, movement.subscription.entities.indexOf(entity.id));
            entity.remove(Vel);
            Assert.isFalse(entity.has(Vel));
            Assert.equals(-1, movement.subscription.entities.indexOf(entity.id));
        }
    }
}