package awe.util;

import de.polygonal.ds.BitVector;
class BitVectorTools {
	public static function contains(set: BitVector, subset: BitVector): Bool {
        var length = Std.int(Math.min(set.arrSize, subset.arrSize));
        for(i in 0...length)
            if(subset.getBucketAt(i) & ~set.getBucketAt(i) != 0)
                return false;
        return true;
	}
	public static function intersects(set: BitVector, subset: BitVector): Bool {
        var length = Std.int(Math.min(set.arrSize, subset.arrSize));
        for(i in 0...length)
            if(subset.getBucketAt(i) & set.getBucketAt(i) != 0)
                return true;
        return false;
	}
}