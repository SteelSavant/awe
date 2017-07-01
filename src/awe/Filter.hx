package awe;
import haxe.macro.Expr;
#if macro
import awe.Component.AutoComponent;
#end
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.Context;
import haxe.macro.Context;
using awe.util.MacroTools;
using awe.util.BitVectorTools;

import de.polygonal.ds.BitVector;

/**
	A filter for matching entities' components against. This is used to check
	if a system is interested in processing an entity.

	This can be constructed by using the `Filter.build(_)` macro.
	Using this, you can build a filter from a binary operation representing
	the combination of types this will expect.

	### Binary Syntax

	#### All of...
	```haxe
	Filter.build(Position & Velocity);
	```
	#### One of...
	```haxe
	Filter.build(Position | Velocity);
	```
	#### None of...
	```haxe
	Filter.build(!Position);
	```

	### Alternate syntax
	```haxe
	Filter.build({
		all: [Position, Velocity, Gravity, Physical],
		none: Frozen
	})
	```
**/
class Filter {
	var allSet(default, null): BitVector;
	var oneSet(default, null): BitVector;
	var noneSet(default, null): BitVector;
	public function new(allSet, oneSet, noneSet) {
		this.allSet = allSet;
		this.oneSet = oneSet;
		this.noneSet = noneSet;
	}
	public static macro function build(expr: Expr): ExprOf<Filter> {
		var debug = Context.defined("debug");
		if(debug)
			Sys.println("Building filter from " + expr.toString());
		var all = new BitVector(64);
		var one = new BitVector(64);
		var none = new BitVector(64);
		function innerBuild(expr: Expr, ?set: BitVector) {
			set = set == null ? all : set;
			switch(expr.expr) {
				case EConst(CIdent("_")):
				case EParenthesis(e):
					innerBuild(expr, set);
				case EBinop(OpAnd | Binop.OpBoolAnd | OpAdd, a, b):
					innerBuild(a, all);
					innerBuild(b, all);
				case EBinop(OpOr | OpBoolOr, a, b):
					innerBuild(a, one);
					innerBuild(b, one);
				case EArrayDecl(types):
					for(t in types)
						innerBuild(t, set);
				case EObjectDecl(fields):
					var allVal = expr.getField("all");
					var noneVal = expr.getField("none");
					var oneVal = expr.getField("one");
					if(allVal != null)
						innerBuild(allVal, all);
					if(noneVal != null)
						innerBuild(noneVal, none);
					if(oneVal != null)
						innerBuild(oneVal, one);
				case EUnop(OpNot | OpNeg, _, a):
					innerBuild(a, none);
				case EField(_, _) | EConst(CIdent(_)):
					var ty = expr.resolveTypeLiteral();
					var cty = ComponentType.get(ty);
					if(debug)
						Sys.println("Adding " + ty.toString() + " (id = " + cty.getPure() + ") to filter");
					set.set(ComponentType.get(ty).getPure());
				default:
					Context.error("Invalid expression for filter", Context.currentPos());
			}
		};
		innerBuild(expr);
		return macro new Filter(${all.wrapBits()}, ${one.wrapBits()}, ${none.wrapBits()});
	}
	/**
		Make a string representation of this filter.
		@return The string representation.
	**/
	public function toString()
		return "all: " + allSet + "; one: " + oneSet + "; none: " + noneSet;
	/**
		Returns true if the `components` set fulfills this filter.
		@param components The `BitVector` of components to check against.
		@return If the `components` set fulfills this filter.
	**/
	public function matches(components: BitVector): Bool {
		return (components.contains(allSet) || oneSet.intersects(components)) && !noneSet.intersects(components);
	}

	public function matching(world: World): Array<Entity> {
		return [for(i in 0...world.entityCount) cast i];
	}
}