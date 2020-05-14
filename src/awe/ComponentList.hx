package awe;

import polygonal.ds.tools.ObjectPool;
import polygonal.ds.ArrayList;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.Serializer;
import haxe.Unserializer;
import awe.Entity;

/**
	Represents a list of components.
**/
interface IComponentList<T:Component> {
	/**
		The number of entities stored in this list.
	 */
	public var length(get, never):Int;

	/**
		Setup this component list inside the `world`.
		This must be ran before other methods are called.
		@param world The world to initialize this in.
	 */
	public function initialize(world:World):Void;

	/**
		Retrieve the component corresponding associated to the ID.
		@param id The id of the entity to retrieve the component for.
		@return The component.
	**/
	public function get(id:EntityId):Null<T>;

	/**
		Create this component in this entity.
	**/
	public function create(id:EntityId, notifySubscriptions:Bool = true):T;

	/**
		Add the component to this list with the given ID.
		@param id The id of the tnity to add a component to.
		@param notifySubscriptions Whether world entity subscriptions should be notified of this addition.
	**/
	public function add(id:EntityId, value:T, notifySubscriptions:Bool = true):Void;

	/**
		Remove the component corresponding to the ID given.
		@param id The `Entity` to remove from this list.
		@param notifySubscriptions Whether world entity subscriptions should be notified of this addition.
		@return The component removed.
	**/
	public function remove(id:EntityId, notifySubscriptions:Bool = true):T;

	/**
		Iterate through the items in this list.
		@return The iterator for this list.
	**/
	public function iterator():Iterator<ComponentListItem<T>>;

	#if serialize
	/**
		Serialize this list into a `String`.
		@return The serialized form of this list.
	**/
	public function serialize():String;

	/**
		Unserialize the serialized value into this list.
		@param serial The serialized version of this list.
	**/
	public function unserialize(value:String):Void;
	#end
}

class PooledComponentList<T:Component> extends ComponentList<T> {
	var pool:ObjectPool<T>;

	public override function initialize(world:World) {
		super.initialize(world);
		pool = new ObjectPool<T>(function() return Type.createEmptyInstance(cl));
	}

	public override function create(id:EntityId, notifySubscriptions:Bool = true):T {
		var value = pool.get();
		add(id, value, notifySubscriptions);
		return value;
	}

	public override function remove(id:EntityId, notifySubscriptions:Bool = true):T {
		var value = super.remove(id, notifySubscriptions);
		pool.put(value);
		return value;
	}
}

class ComponentList<T:Component> implements IComponentList<T> {
	var data:ArrayList<T>;
	var cl:Class<T>;
	var world:World;

	public var length(get, never):Int;

	inline function get_length():Int
		return data.size;

	public function new(cl:Class<T>, capacity:Int = 8) {
		this.cl = cl;
		data = new ArrayList(capacity);
	}

	public function initialize(world:World)
		this.world = world;

	public inline function get(id:EntityId):Null<T>
		return data.get(id);

	public function create(id:EntityId, notifySubscriptions:Bool = true):T {
		var value = Type.createEmptyInstance(cl);
		add(id, value, notifySubscriptions);
		return value;
	}

	public function add(id:EntityId, value:T, notifySubscriptions:Bool = true):Void {
		data.set(id, value);
		if (notifySubscriptions)
			world.subscriptions.changed(id);
	}

	public function remove(id:EntityId, notifySubscriptions:Bool = true):T {
		var value:Null<T> = data.get(id);
		if (value == null)
			throw 'Cannot remove null component of #$id';
		data.set(id, null);
		var bits = world.components.getComponentBits(id);
		var cty = value.getType().getPure();
		if (!bits.has(cty))
			throw 'Entity #$id does not have component';
		bits.clear(cty);
		if (notifySubscriptions)
			world.subscriptions.changed(id);
		return value;
	}

	public inline function iterator():ComponentListIterator<T>
		return new ComponentListIterator<T>(cast data);

	#if serialize
	public inline function serialize():String
		return "c" + Serializer.run(data.toArray());

	public static function genericUnserialize(value:String):IComponentList<Dynamic> {
		switch (value.charCodeAt(0)) {
			case 'p'.code:
				var l = new PackedComponentList();
				l.unserialize(value.substr(1));
				return l;
			case 'c'.code:
				var a = Unserializer.run(value.substr(1));
				var al = new ArrayList(ComponentType.getComponentCount(), a);
				var l = new ComponentList();
				l.list = al;
				return l;
			default:
				return null;
		}
	}
	#end
}

#if generic
@:generic
#end
private class ComponentListItem<T:Component> {
	public var index(default, null):Entity;
	public var component(default, null):T;

	public function new(index:Entity, component:T) {
		this.index = index;
		this.component = component;
	}
}

#if generic
@:generic
#end
private class ComponentListIterator<T:Component> {
	var list:IComponentList<T>;
	var index:Int = 0;

	public function new(list:IComponentList<T>) {
		this.list = list;
	}

	public inline function hasNext()
		return index < list.length;

	public function next():ComponentListItem<T> {
		while (list.get(cast index) == null)
			index++;
		return new ComponentListItem<T>(cast(index + 1, Entity), list.get(cast index++));
	}
}
