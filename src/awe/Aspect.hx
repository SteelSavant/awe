package awe;

import haxe.macro.Expr;

using awe.util.MacroTools;
using awe.util.BitVectorTools;

import polygonal.ds.BitVector;

/**
	A generic Aspect base.
 */
interface IAspect {
	/**
		Returns true if the `components` set fulfills this aspect.
		@param components The `BitVector` of components to check against.
		@return If the `components` set fulfills this aspect.
	 */
	function matches(components:BitVector):Bool;
}

/**
	Matches any combo of components.
 */
class AnyAspect implements IAspect {
	public inline function new() {}

	public inline function matches(components:BitVector):Bool
		return true;
}

/**
	An aspect for matching entities' components against. This is used to check
	if a system is interested in processing an entity.

	This can be constructed by using the `Aspect.build(_)` macro.
	Using this, you can build a aspect from a binary operation representing
	the combination of types this will expect.

	### Binary Syntax

	#### All of...
	```haxe
	Aspect.build(Position & Velocity);
	```
	#### One of...
	```haxe
	Aspect.build(Position | Velocity);
	```
	#### None of...
	```haxe
	Aspect.build(!Position);
	```

	### Alternate syntax
	```haxe
	Aspect.build({
		all: [Position, Velocity, Gravity, Physical],
		none: Frozen
	})
	```
**/
class Aspect implements IAspect {
	var allSet(default, null):BitVector;
	var oneSet(default, null):BitVector;
	var noneSet(default, null):BitVector;

	/**
			 	Create a new aspect from bit vectors.
		@param allSet The components to require all of.
		@param oneSet The components to require at least one of.
		@param noneSet The components to require none of.
	 */
	public function new(allSet, oneSet, noneSet) {
		this.allSet = allSet;
		this.oneSet = oneSet;
		this.noneSet = noneSet;
	}

	/**
		Matches any combo of components.
		@return The aspect.
	 */
	public static inline function any():AnyAspect
		return new AnyAspect();

	public static macro function build(expr:Expr):ExprOf<Aspect>
		return awe.build.AutoAspect.build(expr);

	/**
		Make a string representation of this aspect.
		@return The string representation.
	**/
	public function toString()
		return "all: " + allSet + "; one: " + oneSet + "; none: " + noneSet;

	/**
		Returns true if the `components` set fulfills this aspect.
		@param components The `BitVector` of components to check against.
		@return If the `components` set fulfills this aspect.
	 */
	public function matches(componentBits:BitVector):Bool {
		// Check if the entity possesses ALL of the components defined in the aspect.
		if (allSet.ones() > 0 && !componentBits.contains(allSet))
			return false;

		// If we are STILL interested,
		// Check if the entity possesses ANY of the exclusion components,
		// if it does then the system is not interested.
		if (noneSet.ones() > 0 && noneSet.intersects(componentBits))
			return false;

		// If we are STILL interested,
		// Check if the entity possesses ANY of the components in the oneSet.
		// If so, the system is interested.
		if (oneSet.ones() > 0 && !oneSet.intersects(componentBits))
			return false;

		return true;
	}
}
