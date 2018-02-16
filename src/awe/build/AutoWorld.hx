package awe.build;

import haxe.macro.Context;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
using awe.util.MacroTools;
using awe.util.MoreStringTools;
import haxe.macro.Expr;

#if !macro
class AutoWorld {
	public static function build(setup: ExprOf<World.WorldConfiguration>): ExprOf<World>
		return null;
}
#else
class AutoWorld {
	public static function build(setup: ExprOf<World.WorldConfiguration>): ExprOf<World> {
		var expectedCountExpr = setup.getField("expectedEntityCount");
		if(expectedCountExpr == null)
			expectedCountExpr = macro $v{32};
		var expectedCount: Int = expectedCountExpr.getValue();

		var componentClasses: Array<Expr> = [];
		var componentLists: Array<Expr> = [];
		for(component in setup.assertField("components").getArray()) {
			var ty = component.resolveTypeLiteral();
			var complex = ty.toComplexType();
			var cty = ComponentType.get(ty);
			var list = if(cty.isEmpty())
				macro null;
			else if(cty.isPooled())
				macro cast new awe.ComponentList.PooledComponentList<$complex>($component, $v{expectedCount});
			else
				macro cast new awe.ComponentList<$complex>($component, $v{expectedCount});
			componentLists.push(macro $v{cty.getPure()} => $list);
			componentClasses.push(macro $v{cty.getPure()} => $component);
		}
		var systems = setup.assertField("systems").getArray();
		var block = [
			(macro var componentLists:awe.managers.ComponentManager.ComponentListMap = $a{componentLists}),
			(macro var componentClasses:awe.managers.ComponentManager.ComponentClassMap = $a{componentClasses}),
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
		block.push(macro new World(componentLists, componentClasses, systems));
		return macro $b{block};
	}
}
#end