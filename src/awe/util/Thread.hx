package awe.util;

typedef Thread =
#if neko
	neko.vm.Thread
#elseif cpp
	cpp.vm.Thread
#elseif java
	java.vm.Thread
#else
	Null<Dynamic>
#end
;