package awe;


/**
	Raw data to be attached to an `Entity`. Should contain absolutely no logic
	and should be serializable. This will be automatically pooled or packed.
**/
@:autoBuild(awe.build.AutoComponent.from())
@:keepSub
interface Component {
	/**
		Retrieve the component type for this component. This can be used to
		determine how the component is stored. 
		@return The component type.
	*/
	public function getType(): ComponentType;
}