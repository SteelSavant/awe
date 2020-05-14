import utest.Assert;
import utest.Runner;
import utest.TestResult;
import utest.ui.Report;

class TestAll {
	static function main() {
		var runner = new Runner();
		runner.addCase(new TestAspect());
		runner.addCase(new TestComponent());
		runner.addCase(new TestUtil());
		runner.addCase(new TestWorld());
		Report.create(runner);
		var r:TestResult = null;
		runner.onProgress.add(function(o) {
			if (o.done == o.totals)
				r = o.result;
		});
		runner.run();
	}
}
