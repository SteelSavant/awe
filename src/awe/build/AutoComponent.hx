package awe.build;

using Lambda;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using awe.util.MacroTools;

typedef MType = haxe.macro.Type;

#if(!macro)
class AutoComponent {
	public static function from(): Array<Field> return null;
}
#else
class AutoComponent {
	static function exprPath(t: ComplexType): ExprOf<Class<Dynamic>> {
		return switch(t) {
			case TPath(path):
				var all = [path.name].concat(path.pack);
				var expr = macro $i{all.pop()};
				while(all.length > 0) {
					var curr = all.pop();
					expr = macro $expr.$curr;
				}
				expr;
			default: null;
		}
	}

	public static function isEmpty(ty: Type): Bool {
		return switch(ty) {
			case Type.TInst(_.get() => c, []) if(c.superClass == null && c.meta.has("Empty")):
				true;
			default:
				false;
		};
	}

	public static function defaultValue(ty: ComplexType): Expr {
		switch(ty) {
			case macro: Int, macro: Float: return macro 0;
			case macro: Bool: return macro false;
			default: return macro null;
		}
	}


	public static function buildReset(vars: Array<Field>): Expr {
		var block = [];
		for(v in vars) {
			switch(v.kind) {
				case FieldType.FVar(ty, null):
					return defaultValue(ty);
				default:
					throw 'Cannot build field';
			}
		}
		return macro $b{block};
	}

	public static macro function from():Array<Field> {
		var fields = Context.getBuildFields();
		var offset = 0;
		var localClass = Context.getLocalClass().get();
		if(localClass.isInterface)
			return fields;

		var auto = localClass.meta.hasAny(["Magic", "magic", "Auto", "auto"]);
		var shouldPool = localClass.interfaces.exists(function(c) return c.t.get().name == "PooledComponent");
		var shouldEmpty = localClass.meta.hasAny(["Empty", "empty"]);

		var vars = fields.filter(function(f) return f.kind.getName() == "FVar" && f.access.indexOf(Access.AStatic) == -1);
		if(auto) {
			shouldEmpty = vars.length == 0;
		}
		var componentType = ComponentType.getLocal();
		var advancedComponentType = componentType;
		if(shouldPool)
			advancedComponentType |= ComponentType.POOLED_FLAG;
		else if(shouldEmpty)
			advancedComponentType |= ComponentType.EMPTY_FLAG;
		ComponentType.advancedTypes[componentType] = advancedComponentType;
		var hasReset = fields.exists(function(f) return f.name == "reset");
		var hasGetType = fields.exists(function(f) return f.name == "getType");
		if(shouldPool && !hasReset)
			fields.push({
				name: "reset",
				pos: Context.currentPos(),
				access: [Access.APublic, Access.AInline],
				kind: FieldType.FFun({
					ret: macro: Void,
					expr: buildReset(vars),
					args: []
				})
			});
		if(!hasGetType)
			fields.push({
				name: "getType",
				pos: Context.currentPos(),
				kind: FieldType.FFun({
					ret: macro: awe.ComponentType,
					expr: macro return cast $v{ ComponentType.getLocal() },
					args: []
				}),
				access: [
					Access.AInline, Access.APublic
				]
			});
		return fields;
	}
}
#end