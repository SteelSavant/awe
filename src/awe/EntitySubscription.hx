package awe;

/**
 *  Matches entities meeting a certain aspect.
 */
interface SubscriptionListener {
    function inserted(entities: Array<Entity>): Void;
    function removed(entities: Array<Entity>): Void;
}
class EntitySubscription {
    public var aspect(default, null): Aspect;
    public var entities(default, null): Array<Entity> = [];
    public var world(default, null): World;
    var listeners(default, null): Array<SubscriptionListener> = [];
    public inline function addListener(listener:SubscriptionListener): Void
        listeners.push(listener);

    public inline function removeListener(listener:SubscriptionListener): Void
        listeners.remove(listener);
    
    @:allow(awe)
    function new(aspect: Aspect) {
        this.aspect = aspect;
    }
    public function initialize(world: World) {
        this.world = world;
        world.subscriptions.add(this);
    }
    @:allow(awe)
    function insertedSingle(entity: Entity)
        if(aspect.matches(entity.getComposition(world)))
            entities.push(entity);
    @:allow(awe)
    function inserted(entities: Array<Entity>)
        for(entity in entities)
            if(aspect.matches(entity.getComposition(world)))
                entities.push(entity);
    @:allow(awe)
    function removed(entities: Array<Entity>)
        for(entity in entities)
            if(aspect.matches(entity.getComposition(world)))
                entities.remove(entity);
}