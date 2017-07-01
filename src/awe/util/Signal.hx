package awe.util;

/**
	Dispatches events to listeners.
*/
abstract Signal<T>(ArrayList<SignalListener<T>>) {
	/** Create a new signal. */
	public inline function new()
		this = new ArrayList<SignalListener<T>>(8);

	/**
		Dispatch `event`, notifying all listeners of the event.
		@param event The event to dispatch to all listeners.
	*/
	public inline function dispatch(event: T)
		for(v in this)
			v.on(event);

	/**
		Add a new dispatcher.
		@param dispatch The dispatcher to add.
	*/
	public inline function add(dispatch: SignalListener<T>)
		this.add(dispatch);

	/**
		Add a new dispatcher.
		@param dispatch The dispatcher to remove.
	*/
	public inline function remove(dispatch: SignalListener<T>)
		this.remove(dispatch);

	/** Remove all the listeners. */
	public inline function clear()
		this.clear();

	/**
		Get all the listeners binded to this.
		@return The listeners.
	**/
	@:to public inline function getListeners(): ArrayList<SignalListener<T>>
		return this;
}