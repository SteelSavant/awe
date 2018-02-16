package awe.build;

import haxe.macro.Expr;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.Context;
import haxe.macro.Context;

import awe.ComponentType;
import de.polygonal.ds.BitVector;
using awe.util.MacroTools;

class AutoAspect {
	public static function build(expr: Expr): ExprOf<Aspect> {
		var all = new BitVector(ComponentType.count);
		var one = new BitVector(ComponentType.count);
		var none = new BitVector(ComponentType.count);
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
					set.set(ComponentType.get(ty).getPure());
				default:
					Context.error("Invalid expression for aspect", Context.currentPos());
			}
		};
		innerBuild(expr);
		return macro new Aspect(${all.wrapBits()}, ${one.wrapBits()}, ${none.wrapBits()});
	}
}