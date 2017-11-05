package awe;

import awe.Entity;
import de.polygonal.ds.NativeArray;

/**
    Subscribes to entities being inserted and removed.
 */
interface SubscriptionListener {
    /**
        Called when entities are inserted that match the aspect.
        @param entities The newly inserted entities' ids.
     */
    function inserted(entities: Array<EntityId>): Void;
    /**
        Called when entities are removed that match the aspect.
        @param entities The removed entities' ids.
     */
    function removed(entities: Array<EntityId>): Void;
}
/**
    Keeps a list of entities that meet the given `aspect`, and runs listeners
    when this list is added to / removed from.
 */
class EntitySubscription {
    /**
        The aspect to match entities against.
     */
    public var aspect(default, null): Aspect;
    /**
        The entities matching the `aspect`.
     */
    public var entities(default, null): Array<EntityId> = [];
    /**
        The world this subscription lies in.
     */
    public var world(default, null): World;
    var listeners(default, null): Array<SubscriptionListener> = [];
    /**
        Notify `listener` when entities are added / removed matching `aspect`.
        @param listener The listener to notify.
     */
    public inline function addListener(listener:SubscriptionListener): Void
        listeners.push(listener);

    /**
        Stop notifying `listener` when entities are added / removed matching
        `aspect`.
        @param listener The listener to notify.
     */
    public inline function removeListener(listener:SubscriptionListener): Void
        listeners.remove(listener);
    
    @:allow(awe)
    function new(aspect: Aspect) {
        this.aspect = aspect;
    }
    /**
        Initialize this subscription in `world`.
        @param world The world to add this to.
     */
    public function initialize(world: World) {
        this.world = world;
        world.subscriptions._subscriptions.add(this);
    }
    @:allow(awe)
    function insertedSingle(id: EntityId)
        if(aspect.matches(world.components.getComponentBits(id)))
            entities.push(id);
    @:allow(awe)
    function removedSingle(id: EntityId)
        if(aspect.matches(world.components.getComponentBits(id)))
            entities.remove(id);
    @:allow(awe)
    function inserted(entities: Array<EntityId>)
        for(entity in entities)
            insertedSingle(entity);
    @:allow(awe)
    function removed(entities: Array<EntityId>)
        for(entity in entities)
            removedSingle(entity);
}