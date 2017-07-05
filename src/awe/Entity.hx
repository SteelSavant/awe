package awe;

import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
import haxe.macro.Expr;
using awe.util.MacroTools;
import de.polygonal.ds.BitVector;

/**
	Reperesents a single thing in a `World`.
**/
abstract Entity(Int) to Int from Int {
	/**
		The identifier of this entity.
	*/
	public var id(get, never): Int;
	inline function get_id(): Int
		return this;
	@:allow(awe)
	function insertIntoSubscriptions(world: World): Void {
		for(sub in world.subscriptions)
			if(sub.aspect.matches(world.compositions[this]))
				sub.insertedSingle(this);
	}
	function removeFromSubscriptions(world: World): Void {
		for(sub in world.subscriptions)
			if(sub.aspect.matches(world.compositions[this]))
				sub.removed([this]);
	}
	/**
		Construct a new, empty entity inside the world.
		@param world The world to make the entity inside.
	*/
	public function new(world: World) {
		this = world.entityCount++;
		world.entities.add(this);
		world.compositions.set(this, new BitVector(32));
		insertIntoSubscriptions(world);
	}
	/**
		Delete this entity from the world.
		@param world The world to delete this entity from.
	 */
	public function delete(world: World): Void {
		removeFromSubscriptions(world);
		world.entities.remove(this);
		world.compositions.remove(this);
	}
	/**
		Finds the composition bits of this entity.
		@param world The world that this `Entity` is contained in.
		@return The composition bits.
	**/
	public inline function getComposition(world: World): BitVector
		return world.compositions.get(this);
	#if macro

	static function wrapGet(world: ExprOf<Entity>, ty: Type, cty: ComponentType) {
		var list = macro untyped $world.components.get($v{cty.getPure()});
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
	public static function add<T: Component>(world: World, value: T): Void {}
	/**
		Retrieve the component attached to this entity from the `World`.
		@param world The world this entity is in.
		@param kind The component type to find.
		@return The component of the type given.
	**/
	public static function get<T: Component>(world: World, kind: Class<T>): Null<T> return null;
	#else

	public macro function add<T: Component>(self: ExprOf<Entity>, world: ExprOf<World>, value: ExprOf<T>): ExprOf<Void> {
		var ty = Context.typeof(value);
		var cty = ComponentType.get(ty);
		var list = wrapGet(world, ty, cty);
		return macro $list.add($self, $value);
	}
	public macro function has<T: Component>(self: ExprOf<Entity>, world: ExprOf<World>, cl: ExprOf<Class<T>>): ExprOf<Bool> {
		var ty = MacroTools.resolveTypeLiteral(cl);
		var compTy = ComponentType.get(ty);
		return macro {
			if($self.getComposition($world) == null)
				throw "No composition found, has this entity been deleted?";
			$self.getComposition($world).has($v{compTy.getPure()});
		}
	}
	public macro function get<T: Component>(self: ExprOf<Entity>, world: ExprOf<World>, cl: ExprOf<Class<T>>): ExprOf<Null<T>> {
		var ty = MacroTools.resolveTypeLiteral(cl);
		var cty = ComponentType.get(ty);
		var list = wrapGet(world, ty, cty);
		return macro {
			var list = $list;
			if(list == null)
				null;
			else
				list.get($self);
		}
	}
	#end
	/** Returns the string representation of this data. */
	public inline function toString():String
		return "#" + Std.string(this);
}