package awe.build;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.ExprTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using StringTools;

#if macro
class AutoSystem {
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
        // Skip built-in systems
        if(Context.getLocalModule().startsWith("awe."))
            return fields;
		var initializeField = null;
		var initializeExprs = [];
		for(field in fields)
			if(field.name == "initialize") {
				initializeField = field;
			} else if(field.meta != null && field.meta.filter(function(m) return m.name == "auto").length > 0) {
				var type = switch(field.kind) {
					case FieldType.FVar(ty, _): ty;
					default: {
						Context.fatalError("Class member must be field", field.pos);
						return [];
					}
				}
				if(type.toString().indexOf("ComponentList") != -1) {
					var component = switch(type) {
						case ComplexType.TPath({params: [TypeParam.TPType(ty)]}):
							ty;
						default: 
							Context.fatalError('awe: Unrecognised component list ${type.toString()}', field.pos);
					}
					var cty = ComponentType.get(component.toType());
					initializeExprs.push(macro $i{field.name} = cast world.components.lists[$v{cty.getPure()}]);
				} else {
					var type = Context.parse(type.toString(), Context.currentPos());
					initializeExprs.push(macro $i{field.name} = cast world.getSystem($type));
				}
			}
		if(initializeField == null) {
			initializeField = {
				access: [Access.APublic, Access.AOverride],
				name: "initialize",
				kind: FieldType.FFun({
					args: [{
						name: "world",
						type: macro: awe.World
					}],
					ret: macro: Void,
					expr: macro super.initialize(world)
				}),
				pos: Context.currentPos()
			}
			fields.push(initializeField);
		}
		switch(initializeField.kind) {
			case FieldType.FFun(func): {
				if(func.expr != null)
					initializeExprs.push(func.expr);
				func.expr = macro $b{initializeExprs};
			}
			default: 
		}
		return fields;
	}
}

#else
class AutoSystem {
    public static function build():Array<Field>
}
#end