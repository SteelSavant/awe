package awe;

class Manager extends System {
	/**
		Called when an entity is added to the world.
	**/
	public function added(entity: Entity): Void {}
	/**
		Called when an entity is deleted from the world.
	**/
	public function removed(entity: Entity): Void {}
}