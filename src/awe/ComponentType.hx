package awe;

import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using awe.util.MacroTools;
import haxe.macro.Expr;

/**
	Uniquely identifies every kind of component.
*/
abstract ComponentType(Int) from Int to Int {
	public static macro function getComponentCount(): ExprOf<Int>
		return macro $v{count};
	#if macro
	public static var count:Int = 0;
	public static var basicTypes(default, never) = new Map<String, ComponentType>();
	public static var advancedTypes(default, never) = new Map<ComponentType, ComponentType>();
	public static function get(ty: Type): awe.ComponentType {
		var tys = ty.toString();
		return if(basicTypes.exists(tys))
			advancedTypes.get(basicTypes.get(tys));
		else {
			var cty = count++;
			basicTypes[tys] = cty;
			advancedTypes[cty] = cty;
			cty;
		}
	}

	public static inline function getLocal(): ComponentType
		return get(Context.getLocalType());

	#end

	public static macro function of(ty: ExprOf<Class<Dynamic>>): ExprOf<ComponentType> {
		return macro cast($v{get(ty.resolveTypeLiteral())}, awe.ComponentType);
	}


	public static inline var PACKED_FLAG = 1 << 31;
	public static inline var EMPTY_FLAG = 1 << 30;
	/**
		Returns true if this component is marked as empty.
	  	@return If this component is marked empty.
	*/
	public inline function isEmpty():Bool
		return this & EMPTY_FLAG != 0;

	/**
		Returns true if this component is marked as packed.
		@return If this component is marked packed.
	*/
	public inline function isPacked():Bool
		return this & PACKED_FLAG != 0;

	/**
		Returns the component type free of markers.
		@return The pure component type.
	*/
	public inline function getPure():ComponentType
		return this & ~PACKED_FLAG & ~EMPTY_FLAG;

	@:op(A == B) static inline function eq(a: ComponentType, b: ComponentType): Bool {
		var a: Int = a.getPure();
		var b: Int = b.getPure();
		return a == b;
	}
	@:op(A != B) static inline function neq(a: ComponentType, b: ComponentType): Bool {
		var a: Int = a.getPure();
		var b: Int = b.getPure();
		return a != b;
	}
}