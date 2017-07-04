package awe;

import haxe.io.Bytes;

/**
 * Extra fields added to a packed component by the `Component.from` macro.
 */
typedef PackedComponent = {
	var __offset: Int;
	var __bytes: Bytes;
}