package awe;

import haxe.macro.Expr;

import haxe.io.Bytes;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.BitVector;
import haxe.ds.Vector;
using awe.util.MoreStringTools;
import awe.ComponentList;
import awe.Entity;
import awe.managers.AspectSubscriptionManager;
import awe.managers.ComponentManager;
import awe.managers.EntityManager;
/**
    The central object on which components, systems, etc. are added.
    
    Worlds should be constructed using the `World.build` macro.
 */
@:final class World {
	@:allow(awe)
	var components(default, null): ComponentManager;
	@:allow(awe)
	var systems(default, null): Vector<System>;

	/**
		The entities contained in the World.
	*/
	public var entities(default, null): EntityManager;

	/**
		Subscriptions to entites.
	*/
	public var subscriptions(default, null): AspectSubscriptionManager;
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
	public function new(componentLists: ComponentListMap, componentMaps: ComponentClassMap, systems: Vector<System>) {
		for(componentList in componentLists)
			if(componentList != null)
				componentList.initialize(this);
		subscriptions = new AspectSubscriptionManager();
		this.components = new ComponentManager(componentLists, componentMaps);
		this.systems = systems;
		this.components.initialize(this);
		subscriptions.initialize(this);
		entities = new EntityManager();
		entities.initialize(this);
		for(system in systems)
			system.initialize(this);
	}
	/**
		Create an entity, with no components.
	**/
	public inline function createEntity(): Entity
		return entities.createEntityInstance();
	/**
		Create an entity, with components based on an Entity archetype.
	**/
	public function createEntityFromArchetype(archetype: Archetype): Entity {
		var entity = createEntity();
		components.componentBits[entity.id] = archetype.cid.clone();
		for(i in 0...archetype.cid.numBits)
			if(archetype.cid.has(i))
				components.createType(entity.id, i);
		subscriptions.changed(entity.id);
		return entity;
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
		return awe.build.AutoWorld.build(setup);
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