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
 * Blueprints for fast construction of `Entity`s.
 *
 * This can be constructed by using the `Archetype.build` macro, or by calling
 * the constructor with the composition and component defaults.
 */
class Archetype {
	var defaults: Array<Void -> Component>;
	var cid: BitVector;
	/**
	 * Create a new `Archetype` instance based on its composition and component
	 * defaults.
	 * @param cid The composition.
	 * @param defaults A list of functions that make components.
	 */
	public function new(cid: BitVector, defaults: Array<Void -> Component>) {
		this.cid = cid;
		this.defaults = defaults;
	}
	/**
	 * Create a single `Entity`, using this `Archetype` as a template.
	 * @param world The world to create the entities in.
	 * @return The entity created.
	 */
	public function create(world: World): Entity {
		var entity:Entity = new Entity(world);
		
		for(def in defaults) {
			var inst = def();
			if(inst == null)
				continue;
			var ty = inst.getType();
			var list = world.components.get(ty.getPure());
			if(list == null)
				throw 'Component list for $def is null, did you add it to the World in World.create?';
			list.add(entity, inst);
		}
		world.compositions[entity] = cid;
		entity.insertIntoSubscriptions(world);
		return entity;
	}
	/**
	 * Create multiple entities at once, using this `Archetype` as a template.
	 * @param world The world to create the entities in.
	 * @param count How many entities will be created.
	 * @return The list of entities created.
	 */
	public function createSome(world: World, count: Int): ArrayList<Entity> {
		#if debug
		if(count < 0)
			throw 'Entity count ($count) should be bigger than zero!';
		#end
		var list = new ArrayList<Entity>(count);
		for(i in 0...count)
			list.add(create(world));
		return list;
	}
	/**
	 * Create an `Archetype` from a list of component classes it will be made with.
	 *
	 * This requires the components classes to have a zero-argument constructor.
	 * @param types The component classes.
	 * @return The `Archetype` instance.
	 */
	public static macro function build(types: Array<ExprOf<Class<Component>>>): ExprOf<Archetype> {
		var cid = new BitVector(ComponentType.count);
		var types = [for(typeExpr in types) {
				var type = typeExpr.resolveTypeLiteral();
				var compType = awe.ComponentType.get(type);
				var complexType = type.toComplexType();
				cid.set(compType.getPure());
				if(compType == null)
					Context.fatalError('awe: Component type ${typeExpr.toString()} cannot be resolved', typeExpr.pos);
				var path = switch(complexType) {
					case ComplexType.TPath(path):
						path;
					default:
						Context.fatalError('awe: Component type ${typeExpr.toString()} must be a path', typeExpr.pos);
						return macro null;
				};
				if(compType.isEmpty())
					macro function() return null;
				else
					macro function() return Type.createEmptyInstance($typeExpr);
			}
		];
		return macro new Archetype(${cid.wrapBits()}, ${{expr: ExprDef.EArrayDecl(types), pos: Context.currentPos()}});
	}
}