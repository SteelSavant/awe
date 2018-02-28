package awe;


/**
	Raw data to be attached to an `Entity`. Should contain absolutely no logic
	and should be serializable. This will be automatically pooled or packed.
**/
#if !macro
@:autoBuild(awe.build.AutoComponent.from())
#end
@:keepSub
interface Component {
	/**
		Retrieve the component type for this component. This can be used to
		determine how the component is stored. 
		@return The component type.
	*/
	public function getType(): ComponentType;
}
@:keepSub
interface PooledComponent extends Component {
	/**
		Restore this component to its initial state.
	*/
	public function reset(): Void;
}