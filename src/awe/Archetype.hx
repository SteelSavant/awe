package awe;

import haxe.macro.Expr;

import de.polygonal.ds.BitVector;
/**
	Blueprints for fast construction of `Entity`s.

	This can be constructed by using the `Archetype.build` macro, or by calling
	the constructor with the composition and component defaults.
*/
class Archetype {
	var defaults: Array<Void -> Component>;
	@:allow(awe)
	var cid: BitVector;
	/**
	 	Create a new `Archetype` instance based on its composition and component
		defaults.
		@param cid The composition.
		@param defaults A list of functions that create components.
	*/
	public function new(cid: BitVector, defaults: Array<Void -> Component>) {
		this.cid = cid;
		this.defaults = defaults;
	}
	/**
		Create an `Archetype` from a list of component classes it will be made with.
		
		@param types The component classes.
		@return The created `Archetype` instance.
	*/
	public static macro function build(types: Array<ExprOf<Class<Component>>>): ExprOf<Archetype> {
		return awe.build.AutoArchetype.build(types);
	}
}