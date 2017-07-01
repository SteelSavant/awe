package awe;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
import haxe.macro.Expr;
using awe.util.MacroTools;
#end
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.BitVector;
/**
	Blueprints for fast `Entity` construction.

	This can be constructed by using the `Archetype.build(_)` macro.
	Using this, you can build an archetype by calling it with the
	components you want the `Entity` to have.

	### Example
	```haxe
	Archetype.build(Position, Velocity);
	```
**/
class Archetype {
	var types: Array<ComponentType>;
	var cid: BitVector;
	/**
		Create a new Archetype.
		@param cid The component ID.
		@param types The component types to construct and attach.
	**/
	public function new(cid: BitVector, types: Array<ComponentType>) {
		this.cid = cid;
		this.types = types;
	}
	/**
		Create a new `Entity` with the components given by this `Archetype`.
		@param world The world to create the entity in.
		@return The created entity.
	**/
	public function create(world: World): Entity {
		var entity:Entity = world.entityCount++;
		for(type in types) {
			if(!type.isEmpty()) {
				var list = world.components.get(type.getPure());
				#if debug
				if(list == null)
					throw 'Component list for $type is null!';
				#end
				list.add(entity, null);
			}
		}
		world.entities.add(entity);
		world.compositions.set(entity, cid);
		entity.insertIntoSubscriptions(world);
		return entity;
	}
	public function createSome(world: World, count: Int): ArrayList<Entity> {
		var list = new ArrayList<Entity>(count);
		for(i in 0...count)
			list.add(create(world));
		return list;
	}
	/**
		Constructs an `Archetype` from some component types.
	**/
	public static macro function build(types: Array<ExprOf<Class<Component>>>): ExprOf<Archetype> {
		var cid = new BitVector(32);
		var types = [for(tye in types) {
			var ty = MacroTools.resolveTypeLiteral(tye);
			var cty = awe.ComponentType.get(ty);
			cid.set(cty.getPure());
			macro $v{cty};
		}];
		return macro new Archetype(${cid.wrapBits()}, ${{expr: ExprDef.EArrayDecl(types), pos: Context.currentPos()}});
	}
}