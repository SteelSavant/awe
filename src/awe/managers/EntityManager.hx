package awe.managers;

import awe.Entity;
import awe.System;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.BitVector;
import de.polygonal.ds.ArrayedDeque;

/**
	Allocates, manages, and de-allocates entities.
*/
class EntityManager extends System {
	@:allow(awe)
	var entities: ArrayList<Entity>;
	@:allow(awe)
	var recycled: BitVector = new BitVector(32);
	var limbo: ArrayedDeque<EntityId> = new ArrayedDeque<EntityId>();
	var nextId: EntityId = 0;

	/**
		The number of entities in the world.
	**/
	public var count: Int;

	@:allow(awe)
	public function new(initialCapacity: Int = 32) {
		super();
		entities = new ArrayList<Entity>(initialCapacity);
		count = 0;
	}
	inline function get_count(): Int
		return entities.size;
	/**
		Reset this manager to its original state.
	*/
	public function reset(): Void {
		limbo.clear();
		recycled.clearAll();
		entities.clear();
		nextId = 0;
		count = 0;
	}
	/**
		Make an entity without registering it with the world.
	*/
	function createEntity(id: EntityId): Entity {
		var e = new Entity(world, id);
		entities.set(id, e);
		count++;
		return e;
	} 
	/**
		Construct a new, empty entity.
	*/
	public function createEntityInstance(): Entity {
		var entity = if(limbo.isEmpty())
			createEntity(nextId++);
		else {
			var id = limbo.popFront();
			recycled.clear(id);
			return entities.get(id);
		};
		world.components.componentBits.set(entity.id, new BitVector(32));
		return entity;
	}
	/**
		Construct a new, empty entity and returns its id.
	*/
	public inline function create(): EntityId
		return createEntityInstance().id;
	/**
		Obtain entity object for id.
	*/
	public inline function getEntity(id: EntityId): Null<Entity>
		return entities.get(id);
	
	public inline function iterator(): Iterator<Entity>
		return new EntityIterator(this);

	@:allow(awe)
	function free(id: EntityId): Void {
		if(entities.get(id) == null)
			return;
		limbo.pushBack(id);
		recycled.set(id);
		count--;
	}
}

private class EntityIterator {
	var index: Int = 0;
	var entities: EntityManager;

	public function new(entities: EntityManager) {
		this.entities = entities;
	}
	function skipRecycled() {
		var entity: Null<Entity>;
		do {
			entity = entities.getEntity(index++);
		} while(entities.recycled.has(entity.id) && entity != null);
		index--;
	}
	public function hasNext(): Bool {
		skipRecycled();
		return index + 1 < entities.entities.size;
	}

	public inline function next(): Null<Entity> {
		skipRecycled();
		return entities.getEntity(index);
	}
}