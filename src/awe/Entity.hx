package awe;

import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
import haxe.macro.Expr;

using awe.util.MacroTools;
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
		return world.compositions.get(id);

	@:allow(awe)
	function new(world: World, id: EntityId) {
		this.world = world;
		this.id = id;
	}
	/**
		Delete this entity from the world.
	*/
	public function deleteFromWorld(): Void {
		world.entities.free(id);
		world.compositions.remove(id);
	}
	#if macro
	static function wrapGet(self: ExprOf<Entity>, ty: Type, cty: ComponentType) {
		var list = macro untyped $self.world.components.get($v{cty.getPure()});
		return Context.defined("debug") ? macro {
			var list = $list;
			if(list == null)
				"Component `" + $v{ty.toString()} + "` has not been registered with the World";
			list;
		} : list;
	}
	#end
	#if doc
	/**
		Add the component to the `World`, and attach it to this entity.
		@param world The world this entity is in.
		@param value The component to attach to this entity.
	**/
	public function add<T: Component>(value: T): Void {}
	/**
		Retrieve the component attached to this entity from the `World`.
		@param world The world this entity is in.
		@param kind The component type to find.
		@return The component of the type given.
	**/
	public function get<T: Component>(kind: Class<T>): Null<T> return null;
	#else

	public macro function add<T: Component>(self: ExprOf<Entity>, value: ExprOf<T>): ExprOf<Void> {
		var ty = Context.typeof(value);
		var cty = ComponentType.get(ty);
		var list = wrapGet(macro $self, ty, cty);
		return macro $list.add($self, $value);
	}
	public macro function has<T: Component>(self: ExprOf<Entity>, cl: ExprOf<Class<T>>): ExprOf<Bool> {
		var ty = MacroTools.resolveTypeLiteral(cl);
		var compTy = ComponentType.get(ty);
		return macro {
			if($self.componentBits == null)
				throw "No component bits found, has this entity been deleted?";
			$self.componentBits.has($v{compTy.getPure()});
		} 
	}
	public macro function get<T: Component>(self: ExprOf<Entity>, cl: ExprOf<Class<T>>): ExprOf<Null<T>> {
		var ty = MacroTools.resolveTypeLiteral(cl);
		var cty = ComponentType.get(ty);
		var list = wrapGet(macro $self, ty, cty);
		return macro $list.get($self);
	}
	#end
	/**
		Returns the string representation of this entity.
	*/
	public function toString(): String
		return '#$id';
}