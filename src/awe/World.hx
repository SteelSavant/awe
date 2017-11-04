package awe;
#if macro
import haxe.macro.Context;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
using awe.util.MacroTools;
import haxe.macro.Expr;
#end
import haxe.io.Bytes;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.BitVector;
import haxe.ds.Vector;
using awe.util.MoreStringTools;
import awe.ComponentList;

/**
    The central object on which components, systems, etc. are added.
    
    Worlds should be constructed using the `World.build` macro.
 */
@:final class World {
	@:allow(awe)
	var components(default, null): Map<ComponentType, IComponentList<Dynamic>>;
	@:allow(awe)
	var systems(default, null): Vector<System>;
	@:allow(awe)
	var _entities(default, null): ArrayList<Entity>;

	/**
		The active entities contained in the World.
	*/
	public var entities(get, never): Iterable<Entity>;

	inline function get_entities(): Iterable<Entity>
		return _entities;

	/**
		The number of active entities in the world.
	*/
	public var numEntities(get, never): Int;

	inline function get_numEntities(): Int
		return _entities.size;

	@:allow(awe)
	var compositions(default, null): Map<Entity, BitVector>;
	@:allow(awe)
	var subscriptions(default, null):ArrayList<EntitySubscription> = new ArrayList<EntitySubscription>();
	/**
	    How many entities have been created in total since the world was initialised.
	 */
	@:allow(awe)
	var entityCount(default, null): Int;

	/**
	    The number of seconds since the last time `process` was called.
	    
	    This must be set manually so it can integrate with custom game loops.
	 */
	public var delta: Float = 0;

	/** 
		Construct a new world.
		Note: The `World.create` macro should be preferred.
		@param components The component lists for every kind of component.
		@param systems The systems that are processed.
	**/
	public function new(components, systems) {
		this.components = components;
		this.systems = systems;
		_entities = new ArrayList();
		compositions = new Map();
		entityCount = 0;
		for(system in systems)
			system.initialize(this);
		for(componentList in components) {
			if(componentList != null)
				componentList.initialize(this);
		}
	}
	/**
	    Get the component list corresponding to the component `cl`.
	    @param cl The component class to retrieve the component list for.
	    @return The component list.
	 */
	public function getComponentList<T: Component>(cl: Class<T>): Null<ComponentList.IComponentList<T>> {
		return cast components.get(Type.createEmptyInstance(cl).getType().getPure());
	}
	/**
	    Get the system that is an instance of `cl`.
	    @param cl The system class to retrieve the instance of.
	    @return The system.
	 */
	public function getSystem<T: System>(cl: Class<T>): Null<T> {
		for(system in systems)
			if(Std.is(system, cl))
				return cast system;
		return null;
	}
	/**
	    Construct a new instance of `World` based on the `WorldConfiguration` given.
	    @param setup The configuration to create the world with.
	    @return The created world.
	 */
	public static macro function build(setup: ExprOf<WorldConfiguration>): ExprOf<World> {
		var debug = Context.defined("debug");
		var expectedCountExpr = setup.getField("expectedEntityCount");
		if(expectedCountExpr == null)
			expectedCountExpr = macro $v{32};
		var expectedCount: Int = expectedCountExpr.getValue();
		var components = [for(component in setup.assertField("components").getArray()) {
			var ty = component.resolveTypeLiteral();
			var complex = ty.toComplexType();
			var cty = ComponentType.get(ty);
			var list = if(cty.isEmpty())
				macro null;
			else if(cty.isPacked())
				macro cast awe.ComponentList.PackedComponentList.build($component);
			else
				macro cast new awe.ComponentList<$complex>($v{expectedCount});
			macro $v{cty.getPure()} => $list;
		}];
		var systems = setup.assertField("systems").getArray();
		var components = { expr: ExprDef.EArrayDecl(components), pos: setup.pos };
		var block = [
			(macro var components:Map<awe.ComponentType, awe.ComponentList.IComponentList<Dynamic>> = $components),
			(macro var systems = new haxe.ds.Vector<awe.System>($v{systems.length})),
			(macro var csystem:awe.System = null),
		];
		for(i in 0...systems.length) {
			var system = systems[i];
			block.push(macro systems[$v{i}] = (csystem = $system));
		}
		for(component in setup.assertField("components").getArray()) {
			var cty = ComponentType.get(component.resolveTypeLiteral());
			var parts = component.toString().split(".");
			var name = parts[parts.length - 1].toLowerCase().pluralize();
		}
		block.push(macro new World(components, systems));
		return macro $b{block};
	}
	/**
		Process all active systems.
	 */
	public inline function process()
		for(system in systems)
			system.process();

	/**
		Free resources used by this world.
	**/
	public function dispose(): Void {
		for(system in systems)
			system.dispose();
	}
}
typedef WorldConfiguration = {
	?expectedEntityCount: Int,
	?components: Array<Class<Component>>,
	?systems: Array<System>
}