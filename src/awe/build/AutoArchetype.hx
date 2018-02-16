package awe.build;

import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
import haxe.macro.Expr;
using awe.util.MacroTools;
import awe.ComponentType;

import de.polygonal.ds.BitVector;

#if !macro
class AutoArchetype {

	/**
		Create an `Archetype` from a list of component classes it will be made with.
		
		@param types The component classes.
		@return The created `Archetype` instance.
	*/
	public static function build(types: Array<ExprOf<Class<Component>>>): ExprOf<Archetype> return null;
}
#else
class AutoArchetype {
	public static function build(types: Array<ExprOf<Class<Component>>>): ExprOf<Archetype> {
		var cid = new BitVector(ComponentType.count);
		var types = [for(typeExpr in types) {
				var type = typeExpr.resolveTypeLiteral();
				var compType = ComponentType.get(type);
				var complexType = type.toComplexType();
				cid.set(compType.getPure());
				if(compType == null)
					Context.fatalError('awe: Component type ${typeExpr.toString()} cannot be resolved', typeExpr.pos);
				var path = switch(complexType) {
					case ComplexType.TPath(path):
						path;
					default:
						Context.fatalError('awe: Component type ${typeExpr.toString()} must be a path', typeExpr.pos);
						return macro null;
				};
				if(Context.defined("debug"))
					trace('Archetype type ${typeExpr.toString()}: Empty ${compType.isEmpty()}');
			}
		];
		return macro new Archetype(${cid.wrapBits()});
	}
}
#end