package awe;

import awe.managers.EntityManager;

import de.polygonal.ds.BitVector;

/**
	Reperesents a single thing in a `World`.
**/
typedef EntityId = Int;

/**
	Reperesents a single thing in a `World`.
**/
class Entity {
	/**
		The world containing this entity.
	*/
	public var world(default, null): World;
	/**
		The identifier of this entity.
	*/
	public var id(default, null): EntityId;

	public var componentBits(get, never): BitVector;

	inline function get_componentBits(): BitVector
		return world.components.getComponentBits(id);

	@:allow(awe)
	function new(world: World, id: EntityId) {
		this.world = world;
		this.id = id;
	}
	/**
		Delete this entity from the world.
	*/
	public function deleteFromWorld(): Void {
		if(world == null)
			return;
		world.entities.free(id);
		world.components.componentBits.remove(id);
		world = null;
	}
	/**
		Add the component to the `World`, and attach it to this entity.
		@param value The component to attach to this entity.
	**/
	public inline function add(value: Component)
		world.components.lists[value.getType().getPure()].add(id, value);
	/**
		Retrieve a component by its component type.
		@param type The component type to find.
		@return The component.
	**/
	public inline function getByType(type: ComponentType): Component
		return world.components.getComponent(id, type.getPure());
	/**
		Retrieve the component attached to this entity.

		This is much slower than using `ComponentList`s directly, so try to avoid this.
		@param kind The component type to find.
		@return The component of the type given.
	**/
	public inline function get<T: Component>(kind: Class<T>): Null<T>
		return world.components.getComponentListByClass(kind).get(id);
	/**
		Remove a component from this entity in the world..
		@param kind The component type to remove.
	**/
	public inline function remove<T: Component>(kind: Class<T>): Void
		world.components.getComponentListByClass(kind).remove(id, true);

	/**
		Check if this entity has a certain component.
		@param kind Component type to check.
		@return If this entity has this component.
	**/
	public inline function has<T: Component>(kind: Class<T>): Bool
		return componentBits.has(world.components.getTypeForClass(kind));
	/**
		Returns the string representation of this entity.
	*/
	public inline function toString(): String
		return '#$id';
}