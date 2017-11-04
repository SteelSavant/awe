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
/**
    Performs operations related to entites.
 */
class System {
	/**
	    The world containing this system.
	 */
	public var world(default, null): World;
	/**
	    If this system is enabled or not.
	 */
	public var enabled: Bool;
	/**
	    Create an enabled system with no world.
	 */
	public function new() {
		enabled = true;
		world = null;
	}
	/**
		Check if this system should be processed.
		@return If this should be processed or not.
	 */
	public inline function checkProcessing(): Bool
		return enabled;

	/**
		Initializes this system in the `World`.
	@param world The `World` to initialize this in.
	 */
	public function initialize(world: World): Void
		this.world = world;

	/**
	 	Process this system by running `begin`, `processSystem`, then `end`.
	*/
	@:final public function process(): Void {
		if(checkProcessing()) {
			begin();
			processSystem();
			end();
		}
	}
	/**
		Called as the middle step of processing.
	*/
	public function processSystem(): Void {}

	/**
		Called before processing starts.
	*/
	public function begin(): Void {}
	/**
		Called after processing has finished.
	*/
	public function end(): Void {}
	/**
		Free resources used by this system, and prepare for deletion.
	*/
	public function dispose(): Void {}
}

/**
    Performs operations on entities matching a given `Archetype`.
    
    Extending this lets you use the '@auto' metadata in front of fields
    that are a `IComponentList<...>` or a `System` to automatically
    fetch this component list or system from the world in the `initialize`
    method.
 */
@:autoBuild(awe.EntitySystem.build())
class EntitySystem extends System implements EntitySubscription.SubscriptionListener {
	/**
	    The aspect an entity must match to be considered by the system.
	 */
	public var aspect(default, null): Aspect;
	/**
	    The entity subscription, used to keep track of entities matching the
	    `aspect`.
	 */
	public var subscription(default, null): EntitySubscription;
	/**
	    Make a new EntitySystem that tracks entities matching an aspect.
	    @param aspect The aspect tracked entities must match.
	 */
	public function new(aspect: Aspect) {
		super();
		this.aspect = aspect;
		subscription = new EntitySubscription(aspect);
	}
	/**
		Initializes this system, as well as the subscription, in the `World`.
		@param world The `World` to initialize this in.
	 */
	public override function initialize(world: World) {
		super.initialize(world);
		subscription.initialize(world);
	}
	/**
	    Called every time `process` is ran for each entity matching `Aspect`
	    @param entity The `Entity` to be processed.
	 */
	public function processEntity(entity: Entity): Void {}
	public override function processSystem(): Void
		for(entity in subscription.entities)
			processEntity(entity);
    public function inserted(entities: Array<Entity>): Void {}
    public function removed(entities: Array<Entity>): Void {}
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
					var component = switch(type) {
						case ComplexType.TPath({params: [TypeParam.TPType(ty)]}):
							ty;
						default: 
							Context.fatalError('awe: Unrecognised component list ${type.toString()}', field.pos);
					}
					var cty = ComponentType.get(component.toType());
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