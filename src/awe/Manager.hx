package awe;

class Manager {
	/** The world that contains this manager. **/
	public var world(default, null): World;
	/**
		Initializes this manager in the `World`.
		@param world The `World` to initialize this in.
	**/
	public function initialize(world: World): Void {
		this.world = world;
	}
	/**
		Called when an entity is added to the world.
	**/
	public function added(entity: Entity): Void {}
	/**
		Called when an entity is deleted from the world.
	**/
	public function removed(entity: Entity): Void {}
}