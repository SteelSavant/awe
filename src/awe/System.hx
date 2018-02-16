package awe;

import awe.Aspect;
import awe.Entity;
/**
    An individual unit of processing in a world.
    
    Extending this lets you use the '@auto' metadata in front of fields
    that are a `IComponentList<...>` or a `System` to automatically
    fetch this component list or system from the world in the `initialize`
    method.
 */
#if !macro
@:autoBuild(awe.build.AutoSystem.build())
#end
class System {
	/**
	    The world containing this system.
	 */
	public var world(default, null): World;
	/**
	    If this system is enabled or not.
	 */
	public var enabled: Bool;

	/**
		The type of game loop this will be grouped under in `World`.
	**/

	public var kind: GameLoopType;
	/**
	    Create an enabled system with no world.
	 */
	public function new(kind: GameLoopType = GameLoopType.Update) {
		enabled = true;
		this.kind = kind;
		world = null;
	}
	/**
		Check if this system should be processed.
		@return If this should be processed or not.
	 */
	public inline function checkProcessing(): Bool
		return enabled;

	/**
		Initializes this system in the `World`.
	@param world The `World` to initialize this in.
	 */
	public function initialize(world: World): Void {
		if(this.world != null)
			throw "System has already been initialized!";
		this.world = world;
	}

	/**
	 	Process this system by running `begin`, `processSystem`, then `end`.
	*/
	@:final public function process(): Void {
		if(checkProcessing()) {
			begin();
			processSystem();
			end();
		}
	}
	/**
		Called as the middle step of processing, every time `World.process` is ran.
	*/
	public function processSystem(): Void {}

	/**
		Called before processing starts.
	*/
	public function begin(): Void {}
	/**
		Called after processing has finished.
	*/
	public function end(): Void {}
	/**
		Free resources used by this system, and prepare for deletion.
	*/
	public function dispose(): Void
		world = null;
}

/**
    Performs operations on entities matching a given `Archetype`.
 */
#if !macro
@:autoBuild(awe.build.AutoSystem.build())
#end
class EntitySystem extends System implements EntitySubscription.SubscriptionListener {
	/**
	    The aspect an entity must match to be considered by the system.
	 */
	public var aspect(default, null): Aspect;
	/**
	    The entity subscription, used to keep track of entities matching the
	    `aspect`, and to listen for events related to this.
	 */
	public var subscription(default, null): EntitySubscription;
	/**
	    Make a new EntitySystem that tracks entities matching an aspect.
	    @param aspect The aspect tracked entities must match.
	 */
	public function new(aspect: Aspect, kind: GameLoopType = GameLoopType.Update) {
		super(kind);
		this.aspect = aspect;
		subscription = new EntitySubscription(aspect);
	}
	/**
		Initializes this system, as well as the subscription, in the `World`.
		@param world The `World` to initialize this in.
	 */
	public override function initialize(world: World) {
		super.initialize(world);
		subscription.initialize(world);
		subscription.addListener(this);
	}
	/**
	    Called every time `process` is ran for each entity matching `Aspect`
	    @param entity The `Entity` to be processed.
	 */
	public function processEntity(id: EntityId): Void {}
	public override function processSystem(): Void
		for(id in subscription.entities)
			processEntity(id);
    public function inserted(entity: EntityId): Void {}
    public function removed(entity: EntityId): Void {}
}