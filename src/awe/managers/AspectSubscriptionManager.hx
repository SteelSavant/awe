package awe.managers;

import polygonal.ds.ArrayList;
import awe.Entity;
import awe.EntitySubscription;

class AspectSubscriptionManager extends System {
	@:allow(awe)
	var _subscriptions:ArrayList<EntitySubscription>;

	public override function initialize(world:World) {
		super.initialize(world);
		_subscriptions = new ArrayList<EntitySubscription>();
	}

	/**
		Called when an entity is changed internally.
	**/
	@:allow(awe)
	function changed(entity:EntityId) {
		var comp = world.components.getComponentBits(entity);
		for (sub in _subscriptions) {
			var doesMatch = sub.aspect.matches(comp),
				hasEntity = sub.entities.indexOf(entity) != -1;
			if ((doesMatch && !hasEntity))
				sub.inserted(entity);
			else if (!doesMatch && hasEntity)
				sub.removed(entity);
		}
	}

	@:allow(awe)
	function removed(entity:EntityId) {
		var comp = world.components.getComponentBits(entity);
		for (sub in _subscriptions)
			if (sub.aspect.matches(comp))
				sub.removed(entity);
	}
}
