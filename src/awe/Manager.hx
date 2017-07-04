package awe;

/**
 *  A kind of `System` that monitors all entities, not just all matching an
 *  `Aspect`.
 */
class Manager extends System {
    public override function inserted(entities: Array<Entity>): Void
		for(entity in entities)
			added(entity);
    public override function removed(entities: Array<Entity>): Void
		for(entity in entities)
			removed(entity);
	/**
	 *  Called when an entity is added to the world.
	 *  @param entity - The entity that was added.
	 */
	public function added(entity: Entity): Void {}
	/**
	 *  Called when an entity is removed to the world.
	 *  @param entity - The entity that was removed.
	 */
	public function removed(entity: Entity): Void {}
}