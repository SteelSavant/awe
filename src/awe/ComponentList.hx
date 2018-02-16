package awe;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using awe.util.MacroTools;
#end
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.Serializer;
import haxe.Unserializer;
import de.polygonal.ds.ArrayList;
import awe.Entity;

/**
	Represents a list of components.
	**/
interface IComponentList<T: Component> {
	/**
		The number of entities stored in this list.
	 */
	public var length(get, never): Int;
	/**
		Setup this component list inside the `world`.
		This must be ran before other methods are called.
		@param world The world to initialize this in.
	 */
	public function initialize(world: World): Void;
	/**
		Retrieve the component corresponding associated to the ID.
		@param id The id of the entity to retrieve the component for.
		@return The component.
	**/
	public function get(id: EntityId): Null<T>;
	/**
		Add the component to this list with the given ID.
		@param id The id of the tnity to add a component to.
	**/
	public function add(id: EntityId, value: T): Void;
	/**
		Remove the component corresponding to the ID given.
		@param id The `Entity` to remove from this list.
	**/
	public function remove(id: EntityId): Void;
	/**
		Iterate through the items in this list.
		@return The iterator for this list.
	**/
	public function iterator(): Iterator<ComponentListItem<T>>;

	#if serialize

	/**
		Serialize this list into a `String`.
		@return The serialized form of this list.
	**/
	public function serialize(): String;
	/**
		Unserialize the serialized value into this list.
		@param serial The serialized version of this list.
	**/
	public function unserialize(value: String): Void;
	#end
}
class ComponentList<T: Component> implements IComponentList<T> {
	var data: ArrayList<T>;
	var world: World;
	public var length(get, never): Int;
	inline function get_length(): Int
		return data.size;
	public inline function new(capacity: Int = 8)
		data = new ArrayList(capacity);

	public inline function initialize(world: World)
		this.world = world;

	public inline function get(id: EntityId): Null<T>
		return data.get(id);

	public inline function add(id: EntityId, value: T): Void
		data.set(id, value);

	public function remove(id: EntityId): Void {
		var value: Null<T> = data.get(id);
		if(value == null)
			throw 'Cannot remove null component of #$id';
		data.set(id, null);
		var bits = world.components.getComponentBits(id);
		var cty = value.getType().getPure();
		if(!bits.has(cty))
			throw 'Entity #$id does not have component';
		bits.clear(cty);
	}

	public inline function iterator(): ComponentListIterator<T>
		return new ComponentListIterator<T>(cast data);
	#if serialize
	public inline function serialize(): String
		return "c" + Serializer.run(data.toArray());

	public static function genericUnserialize(value: String): IComponentList<Dynamic> {
		switch(value.charCodeAt(0)) {
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
private class ComponentListItem<T: Component> {
	public var index(default, null): Entity;
	public var component(default, null): T;

	public function new(index: Entity, component: T) {
		this.index = index;
		this.component = component;
	}
}
#if generic
@:generic
#end
private class ComponentListIterator<T: Component> {
	var list: IComponentList<T>;
	var index: Int = 0;
	public function new(list: IComponentList<T>) {
		this.list = list;
	}
	public inline function hasNext()
		return index < list.length;

	public function next():ComponentListItem<T> {
		while(list.get(cast index) == null)
			index++;
		return new ComponentListItem<T>(cast (index + 1, Entity), list.get(cast index++));
	}
}

#if generic
@:generic
#end
class PackedComponentList<T: Component> implements IComponentList<T> {
	var _length: Int;
	var buffer: PackedComponent;
	var bytes: Bytes;
	var size: Int;
	var world: World;
	var ctype: ComponentType;


	public var length(get, never): Int;
	inline function get_length(): Int
		return _length;

	public function new(ctype: ComponentType, capacity: Int = 4, size: Int = 0) {
		buffer = cast {};
		_length = 0;
		this.size = size;
		this.ctype = ctype.getPure();
		bytes = Bytes.alloc(capacity * size);
		buffer.__bytes = bytes;
		buffer.__offset = 0;
	}


	public inline function initialize(world: World)
		this.world = world;

	public static macro function build<T: Component>(of: ExprOf<Class<T>>): ExprOf<PackedComponentList<T>> {
		var ty = of.resolveTypeLiteral();
		var cty = ComponentType.get(ty);
		if(!cty.isPacked())
			Context.error("Component type is not packed", of.pos);
		var size = of.resolveTypeLiteral().toComplexType().sizeOf();
		return macro new awe.ComponentList.PackedComponentList<Dynamic>(cast $v{cty}, 32, $v{size});
	}

	public function get(id: EntityId): Null<T> {
		buffer.__offset = id * size;
		return id >= length ? null : cast buffer;
	}

	public function add(id: EntityId, value: T): Void {
		var value:PackedComponent = cast value;
		if(id * size >= bytes.length) {
			var nbytes = Bytes.alloc(bytes.length * 2);
			nbytes.blit(0, bytes, 0, bytes.length);
			bytes = nbytes;
		}
		if(value == null)
			bytes.fill(id * size, size, 0);
		else {
			bytes.blit(id * size, bytes, 0, size);
			value.__bytes = bytes;
			value.__offset = id * size;
		}
		_length = Std.int(Math.max(length, id + 1));
	}
	public function remove(id: EntityId): Void {
		var comp = world.components.getComponentBits(id);
		var value: Null<T> = get(id);
		if(comp == null || value == null)
			return;
		comp.clear(ctype);
		bytes.fill(id * size, size, 0);
	}

	#if serialize
	public inline function serialize()
		return "p" + Serializer.run(this.bytes.sub(0, length << 4));

	public function unserialize(value: String) {
		bytes = Unserializer.run(value.substr(1));
		_length = bytes.length >> 4;
	}
	#end

	public inline function iterator()
		return new ComponentListIterator<T>(this);
}
