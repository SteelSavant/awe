package awe.managers;

import awe.Component;
import awe.ComponentList;
import awe.ComponentType;
import awe.Entity;
import awe.System;
import de.polygonal.ds.BitVector;

typedef ComponentListMap = Map<ComponentType, IComponentList<Dynamic>>;
class ComponentManager extends System {
	@:allow(awe)
	var componentBits(default, null): Map<EntityId, BitVector>;
	@:allow(awe)
	var lists: ComponentListMap;
	
	@:allow(awe)
	function new(lists: ComponentListMap) {
		super();
		componentBits = new Map();
		this.lists = lists;
	}
	/**
		Get an entity's component bits.
	**/
	public inline function getComponentBits(id: EntityId): BitVector
		return componentBits[id];
	/**
		Get a certain component from an entity.
	*/
	public inline function getComponent(id: EntityId, type: ComponentType): Component
		return lists[type.getPure()].get(id);
	/**
		Get an array of all the components attached to an entity.
	*/
	public function getComponentsFor(id: EntityId): Array<Component> {
		var list: Array<Component> = [];
		var	componentBits: BitVector = this.componentBits[id];
		for(i in 0...componentBits.numBits)
			if(componentBits.has(i))
				list.push(lists[i].get(id));
		return list;
	}

	/**
		Create a component of given type by class.
		@param owner entity id
		@param componentClass class of component to instance.
		@return Newly created packed, pooled or basic component.
	 */
	public function create<T: Component>(owner: EntityId, componentClass: Class<T>): T {
		var value: T = Type.createEmptyInstance(componentClass);
		lists.get(value.getType()).add(owner, value);
		return value;
	}
}