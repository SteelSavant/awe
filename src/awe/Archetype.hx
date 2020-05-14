package awe;

import haxe.macro.Expr;
import polygonal.ds.BitVector;
import awe.ComponentType;

/**
	Blueprints for fast construction of `Entity`s.

	This can be constructed by using the `Archetype.build` macro, or by calling
	the constructor with the composition and component defaults.
 */
class Archetype {
	@:allow(awe)
	var cid:BitVector;

	/**
			 	Create a new `Archetype` instance based on its composition bits.
		@param cid The composition. A set of bits corresponding to components.
	 */
	public inline function new(cid:BitVector) {
		this.cid = cid;
	}

	/**
		Register a component type from this archetype.
		@param type The component type to set.
	 */
	public inline function add(type:ComponentType)
		cid.set(type.getPure());

	/**
		Create an `Archetype` from a list of component classes it will be made with.

		@param types The component classes.
		@return The created `Archetype` instance.
	 */
	public static macro function build(types:Array<ExprOf<Class<Component>>>):ExprOf<Archetype> {
		return awe.build.AutoArchetype.build(types);
	}
}
