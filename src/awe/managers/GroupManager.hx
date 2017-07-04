package awe.managers;

import de.polygonal.ds.ArrayList;
import awe.System;

/**
	Handles entity grouping.
**/
class GroupManager extends System {
	var groups: Map<String, ArrayList<Entity>>;

	public function new() {
		super();
		groups = new Map<String, ArrayList<Entity>>();
	}

	/**
	 *	Set the group of the entity.
	 *	@param entity The entity whose group is being set.
	 *	@param group The group to set the entity to.
	 */
	public function add(entity: Entity, group: String): Void {
		if(!groups.exists(group))
			groups.set(group, new ArrayList(8));
		groups.get(group).add(entity);
	}
	/**
	 *	Get the entities contained in a given group.
	 *	@param group The group to check.
	 *	@return The entities.
	 */
	public inline function getEntities(group: String): ArrayList<Entity>
		return groups.get(group);

	/**
	 *	Get all groups the entity belongs to..
	 *	@param entity The entity to get the groups of.
	 *	@return The groups it belongs to.
	 */
	public function getGroups(entity: Entity): ArrayList<String> {
		var contained = new ArrayList(8);
		for(group in groups.keys()) {
			if(groups.get(group).contains(entity))
				contained.add(group);
		}
		return contained;
	}
	/**
		Check if the entity is in the group.
		@param entity The entity to check.
		@param group The group to check the ntity is contained in.
		@return If the entity is in the group.
	**/
	public inline function isInGroup(entity: Entity, group: String): Bool
		return groups.exists(group) && groups.get(group).contains(entity);

	/**
		Remove the entity from the specified group.
		@param entity The entity to remove from the group.
		@param group The group to remove the entity from.
	**/
	public inline function remove(entity: Entity, group: String):Void
		if(groups.exists(group))
			groups.get(group).remove(entity);
	/**
		Completely remove the group.
		@param group The group to remove.
	**/
	public inline function removeGroup(group: String):Void
		groups.remove(group);
}