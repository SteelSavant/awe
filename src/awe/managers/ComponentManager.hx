package awe.managers;

import awe.Component;
import awe.ComponentList;
import awe.ComponentType;
import awe.Entity;
import awe.System;
import polygonal.ds.BitVector;
import haxe.macro.Expr;

typedef ComponentListMap = Map<ComponentType, IComponentList<Component>>;
typedef ComponentClassMap = Map<ComponentType, Class<Component>>;
typedef ComponentTypeMap = Map<String, ComponentType>;

class ComponentManager extends System {
	@:allow(awe)
	var componentBits(default, null):Map<EntityId, BitVector>;
	@:allow(awe)
	var componentClasses(default, null):ComponentClassMap;
	var componentTypes(default, null):ComponentTypeMap;

	@:allow(awe)
	var lists:ComponentListMap;

	@:allow(awe)
	function new(lists:ComponentListMap, classes:ComponentClassMap) {
		super();
		componentBits = new Map();
		this.lists = lists;
		this.componentClasses = classes;
		this.componentTypes = new Map();
		for (ty in classes.keys())
			componentTypes[Type.getClassName(classes[ty])] = ty;
	}

	@:allow(awe)
	inline function getComponentList(type:ComponentType):IComponentList<Component>
		return lists[type.getPure()];

	@:allow(awe)
	function getTypeForClass<T:Component>(cl:Class<T>):ComponentType {
		for (cty in componentClasses.keys())
			if (componentClasses[cty] == cast cl)
				return cty;
		return null;
	}

	@:allow(awe)
	function getComponentListByClass<T:Component>(cl:Class<T>):Null<IComponentList<T>> {
		var ty = getTypeForClass(cl);
		return ty == null ? null : cast lists[ty];
	}

	/**
		Get an entity's component bits.
	**/
	public inline function getComponentBits(id:EntityId):BitVector
		return componentBits[id];

	/**
		Get a certain component from an entity.
	 */
	public inline function getComponent(id:EntityId, type:ComponentType):Component
		return lists[type.getPure()].get(id);

	/**
		Get an array of all the components attached to an entity.
	 */
	public function getComponentsFor(id:EntityId):Array<Component> {
		var list:Array<Component> = [];
		var componentBits:BitVector = this.componentBits[id];
		for (i in 0...componentBits.numBits)
			if (componentBits.has(i))
				list.push(lists[i].get(id));
		return list;
	}

	/**
		Create a component of given type by its type.
		@param owner entity id
		@param componentType component type
		@return Newly created packed, pooled or basic component.
	 */
	public inline function createType(owner:EntityId, componentType:ComponentType, notifySubscriptions:Bool = true):Component
		return create(owner, componentClasses[componentType], notifySubscriptions);

	/**
		Create a component of given type by class.
		@param owner entity id
		@param componentClass class of component to instance.
		@return Newly created packed, pooled or basic component.
	 */
	public inline function create<T:Component>(owner:EntityId, componentClass:Class<T>, notifySubscriptions:Bool = true):T
		return cast lists[componentTypes[Type.getClassName(componentClass)]].create(owner, notifySubscriptions);
}
