package awe;

/**
    Subscribes to entities being inserted and removed.
 */
interface SubscriptionListener {
    /**
        Called when entities are inserted that match the aspect.
        @param entities The newly inserted entities.
     */
    function inserted(entities: Array<Entity>): Void;
    /**
        Called when entities are removed that match the aspect.
        @param entities The removed entities.
     */
    function removed(entities: Array<Entity>): Void;
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
    public var entities(default, null): Array<Entity> = [];
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
        world.subscriptions.add(this);
    }
    @:allow(awe)
    function insertedSingle(entity: Entity)
        if(aspect.matches(entity.getComposition(world)))
            entities.push(entity);
    @:allow(awe)
    function removedSingle(entity: Entity)
        if(aspect.matches(entity.getComposition(world)))
            entities.remove(entity);
    @:allow(awe)
    function inserted(entities: Array<Entity>)
        for(entity in entities)
            insertedSingle(entity);
    @:allow(awe)
    function removed(entities: Array<Entity>)
        for(entity in entities)
            removedSingle(entity);
}