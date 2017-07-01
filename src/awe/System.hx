package awe;

import awe.Aspect;
import de.polygonal.ds.ArrayList;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.ExprTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using StringTools;
#end
/** A basic system. **/
class System {
	/** The world that contains this system. **/
	public var world(default, null): World;
	/** If this system is enabled or not. **/
	public var enabled: Bool;
	/** Create a new, empty system. **/
	public function new() {
		enabled = true;
		world = null;
	}
	/**
		Check if this system should be processed.
		@return If this should be processed or not.
	**/
	public inline function checkProcessing(): Bool
		return enabled;

	/**
		Initializes this system in the `World`.
		@param world The `World` to initialize this in.
	**/
	public function initialize(world: World): Void {
		this.world = world;
	}

	/**
		Process this system by running `begin`, `processSystem`, then `end`.
	**/
	@:final public function process(): Void {
		if(checkProcessing()) {
			begin();
			processSystem();
			end();
		}
	}
	/**
		Process this system.
	**/
	public function processSystem(): Void {}

	/**
		Called before processing starts.
	**/
	public function begin(): Void {}
	/**
		Called after processing has finished.
	**/
	public function end(): Void {}
	/**
		Free resources used by this system.
	**/
	public function dispose(): Void {}
}

@:autoBuild(awe.EntitySystem.build())
class EntitySystem extends System {
	/** The aspect to check an entity against before adding to this system. **/
	public var aspect(default, null): Aspect;
	/** The entities that match the `aspect`. **/
	public var matchers(default, null): ArrayList<Entity>;
	public function new(aspect: Aspect) {
		super();
		this.aspect = aspect;
		this.matchers = new ArrayList();
	}
	@:access(awe)
	public function processMatchers():Void {
		matchers.clear();
		for(entity in world.entities)
			if(aspect.matches(entity.getComposition(world)))
				matchers.add(entity);
	}
	public function processEntity(entity: Entity): Void {}
	public override function processSystem(): Void {
		if(matchers.size ==  0)
			processMatchers();
		for(entity in matchers)
			processEntity(entity);
	}
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
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
					var component = switch(type.toType()) {
						case Type.TInst(ty, params): {
							params[0];
						}
						default: {
							Context.fatalError("Invalid component type", field.pos);
						}
					};
					var cty = ComponentType.get(component);
					initializeExprs.push(macro $i{field.name} = cast world.components[$v{cty.getPure()}]);
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