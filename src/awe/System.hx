package awe;

import awe.Filter;
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
	public function shouldProcess(): Bool
		return enabled;

	/**
		Initializes this system in the `World`.
		@param world The `World` to initialize this in.
	**/
	public function initialize(world: World): Void {
		this.world = world;
	}

	/**
		Updates this system.
		@param delta The change in time in seconds.
	**/
	public function update(delta: Float): Void {}
}

@:autoBuild(awe.EntitySystem.build())
class EntitySystem extends System {
	/** The filter to check an entity against before adding to this system. **/
	public var filter(default, null): Filter;
	/** The entities that match the `filter`. **/
	public var matchers(default, null): ArrayList<Entity>;
	public function new(filter: Filter) {
		super();
		this.filter = filter;
		this.matchers = new ArrayList();
	}
	@:access(awe)
	public function updateMatchers():Void {
		matchers.clear();
		for(entity in world.entities)
			if(filter.matches(entity.getComposition(world)))
				matchers.add(entity);
	}
	public function updateEntity(delta:Float, entity: Entity): Void {}
	public override function update(delta: Float):Void {
		if(matchers.size ==  0)
			updateMatchers();
		for(entity in matchers)
			updateEntity(delta, entity);
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