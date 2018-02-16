package awe.build;


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
	static function genFieldAccess(t: ComplexType, offset: ExprOf<Int>): Expr {
		return switch(t) {
			case TPath({name: "Bool", pack: [], params: []}):
				macro __bytes.get($offset) != 0;
			case TPath({name: "Int", pack: [], params: []}):
				macro __bytes.getInt32($offset);
			case TPath({name: "Single", pack: [], params: []}):
				macro __bytes.getFloat($offset);
			case TPath({name: "Float", pack: [], params: []}):
				macro __bytes.getDouble($offset);
			case TPath(_):
				var ty = Context.getType(t.toString());
				switch(Context.follow(ty)) {
					case TEnum(en, []):
						switch(offset.expr) {
							case ExprDef.EConst(Constant.CIdent(n)):
								macro $v{en.get().constructs.get(n).index}
							default:
								macro Type.createEnumIndex(${exprPath(t)}, __bytes.getInt32($offset));
						}
					case TAbstract(ty, []):
						genFieldAccess(ty.get().type.toComplexType(), offset);
					default: null;
				}
			default:
				Context.fatalError('awe: Type ${t.toString()} cannot be packed', Context.currentPos());
		};
	}
	static function genFieldSetter(t: ComplexType, name: String, offset: ExprOf<Int>): Expr {
		var value = macro $i{name};
		return switch(t) {
			case TPath({name: "Bool", pack: [], params: []}):
				macro __bytes.set($offset, $value ? 1 : 0);
			case TPath({name: "Int", pack: [], params: []}):
				macro __bytes.setInt32($offset, $value);
			case TPath({name: "Single", pack: [], params: []}):
				macro __bytes.setFloat($offset, $value);
			case TPath({name: "Float", pack: [], params: []}):
				macro __bytes.setDouble($offset, $value);
			case TPath(_):
				var ty = Context.getType(t.toString());
				switch(Context.follow(ty)) {
					case TEnum(et, []):
						macro __bytes.setInt32($offset, Type.enumIndex($value));
					case TAbstract(ty, []):
						genFieldAccess(ty.get().type.toComplexType(), offset);
					default: null;
				}
			default:
				Context.fatalError('awe: Type ${t.toString()} cannot be packed', Context.currentPos());
		};
	}
	public static function isPrimitive(t: ComplexType): Bool {
		return switch(t) {
			case TPath({name: "Bool" | "Int" | "Single" | "Float", pack: [], params: []})
			| TPath({name: "Int64", pack: ["haxe"], params: []}):
				true;
			case ComplexType.TPath(_):
				var ty = Context.getType(t.toString());
				switch(Context.follow(ty)) {
					case TEnum(ty, []):
						for(c in ty.get().constructs)
							if(c.params.length > 0)
								return false;
						true;
					case TAbstract(ty, []):
						isPrimitive(ty.get().type.toComplexType());
					default: false;
				}
			default:
				false;
		};
	}
	public static function totalSize(fields: Array<Field>): Int {
		var size = 0;
		for(f in fields)
			switch(f.kind) {
				case FieldType.FVar(t, _):
					size += t.sizeOf();
				default:
			}
		return size;
	}

	static function defaultFields(fields: Array<Field>): Array<Field> {
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

	public static function isEmpty(ty: Type): Bool {
		return switch(ty) {
			case Type.TInst(_.get() => c, []) if(c.superClass == null && c.meta.has("Empty")):
				true;
			default:
				false;
		};
	}

	public static function canPack(ty: Type): Bool {
		return switch(ty) {
			case Type.TAbstract(ab, []):
				canPack(ab.get().type);
			case Type.TInst(_.get() => c, []) if(c.superClass == null && c.meta.has("Pack")):
				true;
			default:
				isPrimitive(ty.toComplexType());
		};
	}

	public static macro function from():Array<Field> {
		var fields = Context.getBuildFields();
		var offset = 0;
		var localClass = Context.getLocalClass().get();
		var auto = localClass.meta.hasAny(["Magic", "magic", "Auto", "auto"]);
		var shouldPack = localClass.meta.hasAny(["Packed", "packed", "pack", "Pack"]) && !Context.defined("nopack");
		var shouldEmpty = localClass.meta.hasAny(["Empty", "empty"]);
		if(auto) {
			var vars = fields.filter(function(f) return f.kind.getName() == "FVar");
			var varCount = 0;
			var allPrimitive = true;
			for(field in fields)
				switch(field.kind) {
					case FieldType.FVar(type, _):
						varCount++;
						if(!isPrimitive(type)) {
							allPrimitive = false;
							break;
						}
					default:
				}
			shouldPack = !Context.defined("nopack") && allPrimitive;
			shouldEmpty = varCount == 0;
		}
		var componentType = ComponentType.getLocal();
		if(!(shouldPack || shouldEmpty) || localClass.superClass != null)
			return defaultFields(fields);
		var advancedComponentType = componentType;
		if(shouldPack)
			advancedComponentType |= ComponentType.PACKED_FLAG;
		else if(shouldEmpty)
			advancedComponentType |= ComponentType.EMPTY_FLAG;
		ComponentType.advancedTypes[componentType] = advancedComponentType;
		for(field in fields) {
			switch(field.kind) {
				case FieldType.FVar(t, e):
					if(field.access.indexOf(Access.AStatic) == -1) {
						if(!isPrimitive(t))
							return defaultFields(fields);
						field.kind = FieldType.FProp("get", "set", t);
						var off = Context.makeExpr(offset, Context.currentPos());
						off = macro __offset + $off;
						var access = genFieldAccess(t, off);
						var setter = genFieldSetter(t, field.name, off);
						fields.push({
							name: "get_" + field.name,
							pos: field.pos,
							access: [Access.APrivate, Access.AInline],
							kind: FieldType.FFun({
								ret: t,
								expr: macro return $access,
								args: []
							}),
							meta: [
								{
									pos: Context.currentPos(),
									name: ":extern"
								}
							]
						});
						fields.push({
							name: "set_" + field.name,
							pos: field.pos,
							access: [Access.APrivate, Access.AInline],
							kind: FieldType.FFun({
								ret: t,
								expr: macro {
									$setter;
									return $i{field.name};
								},
								args: [{
									type: t,
									name: field.name
								}]
							}),
							meta: [
								{
									pos: Context.currentPos(),
									name: ":extern"
								}
							]
						});
						offset += t.sizeOf();
					}
				default:
			}
		}
		fields.push({
			name: "__offset",
			pos: Context.currentPos(),
			access: [Access.APrivate],
			kind: FieldType.FVar(macro: Int, macro 0)
		});
		fields.push({
			name: "__bytes",
			pos: Context.currentPos(),
			access: [Access.APrivate],
			kind: FieldType.FVar(macro: haxe.io.Bytes, macro haxe.io.Bytes.alloc($v{offset}))
		});
		fields.push({
			name: "reset",
			pos: Context.currentPos(),
			access: [Access.APublic, Access.AInline],
			kind: FieldType.FFun({
				ret: macro: Void,
				expr: macro __bytes.fill(__offset, $v{offset}, 0),
				args: []
			})
		});
		fields.push({
			name: "getType",
			pos: Context.currentPos(),
			kind: FieldType.FFun({
				ret: macro: awe.ComponentType,
				expr: macro return cast $v{advancedComponentType},
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