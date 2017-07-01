import awe.util.ArrayList;

class Main {
	static function main() {
		var ArrayList = new ArrayList();
		ArrayList.add(32);
		trace(ArrayList.contains(32));
		trace(ArrayList.contains(31));
	}
}