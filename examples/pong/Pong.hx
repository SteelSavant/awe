import awe.Archetype;
import awe.Component;
import awe.ComponentList;
import awe.World;
import awe.Entity;
import awe.System;
import awe.Aspect;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasElement;

class Collide implements Component {}

class Size implements Component {
	public var w: Float;
	public var h: Float;
	public function new(w, h) {
		this.w = w;
		this.h = h;
	}
}
class Position implements Component {
	public var x: Float;
	public var y: Float;
	public function new(x, y) {
		this.x = x;
		this.y = y;
	}
}
class Velocity implements Component {
	public var x: Float;
	public var y: Float;
	public function new(x, y) {
		this.x = x;
		this.y = y;
	}
}
enum InputData {
	Up;
	Down;
	None;
}

class Input implements Component {
	public function new() {}
}
class Bounce implements Component {}
enum SideData {
	Left;
	Right;
}
class Side implements Component {
	public var side: SideData;
	public function new(side: SideData)
		this.side = side;
}

class Draw implements Component {
	public var color: String;
	public function new(color: String)
		this.color = color;
}
class Speed implements Component {
	public var speed: Float;
	public function new(speed: Float)
		this.speed = speed;
}


class BounceSystem extends EntitySystem {
	@auto public var positions: awe.IComponentList<Position>;
	@auto public var sizes: awe.IComponentList<Size>;
	@auto public var velocities: awe.IComponentList<Velocity>;
	@auto public var draw: DrawSystem;
	public override function new() {
		super(Aspect.build(Bounce & Position & Size & Velocity));
	}
	public override function processEntity(entity: Entity): Void {
		var pos: Position = positions.get(entity);
		var size: Size = sizes.get(entity);
		var vel: Velocity = velocities.get(entity);
		var delta = world.delta;
		if(pos.x + vel.x * delta < 0)
			vel.x = Math.abs(vel.x);
		if(pos.x + vel.x * delta + size.w > draw.canvas.width)
			vel.x = -Math.abs(vel.x);
		if(pos.y + vel.y * delta < 0)
			vel.y = Math.abs(vel.y);
		if(pos.y + vel.y * delta + size.h > draw.canvas.height)
			vel.y = -Math.abs(vel.y);
	}
}
class MovementSystem extends EntitySystem {
	@auto public var positions: awe.IComponentList<Position>;
	@auto public var velocities: awe.IComponentList<Velocity>;
	public override function new() {
		super(Aspect.build(Position & Velocity));
	}
	public override function processEntity(entity: Entity): Void {
		var pos: Position = positions.get(entity);
		var vel: Velocity = velocities.get(entity);
		pos.x += vel.x * world.delta;
		pos.y += vel.y * world.delta;
	}
}

class CollisionSystem extends EntitySystem {
	@auto public var positions: awe.IComponentList<Position>;
	@auto public var sizes: awe.IComponentList<Size>;
	@auto public var velocities: awe.IComponentList<Velocity>;
	public override function new() {
		super(Aspect.build(Collide & Position & Size & Velocity));
	}
	public override function processEntity(entity: Entity): Void {
		var pos: Position = positions.get(entity);
		var size: Size = sizes.get(entity);
		var vel: Velocity = velocities.get(entity);
		var delta = world.delta;
		var nextX = pos.x + vel.x * delta;
		var nextY = pos.y + vel.y * delta;
		for(other in subscription.entities) {
			if(other == entity) continue;
			var opos: Position = positions.get(entity);
			var osize: Size = sizes.get(entity);
			var ovel: Velocity = velocities.get(entity);
			if (pos.x < opos.x + osize.w &&
				pos.x + size.w > opos.x &&
				pos.y < opos.y + osize.h &&
				size.h + pos.y > opos.y) {
				vel.x = -vel.x;
				vel.y = -vel.y;
			}
		}
	}
}

class DrawSystem extends EntitySystem {
	var context: CanvasRenderingContext2D;
	public var canvas: CanvasElement;
	@auto public var draws: awe.IComponentList<Draw>;
	@auto public var positions: awe.IComponentList<Position>;
	@auto public var sizes: awe.IComponentList<Size>;
	public override function new() {
		super(Aspect.build(Position & Draw & Size));
		canvas = cast js.Browser.document.getElementById("pong");
		context = canvas.getContext2d();
	}
	public override function processSystem() {
		context.fillStyle = 'black';
		context.fillRect(0, 0, canvas.width, canvas.height);
		super.processSystem();
	}
	public override function processEntity(entity: Entity): Void {
		var pos: Position = positions.get(entity);
		var size: Size = sizes.get(entity);
		var draw: Draw = draws.get(entity);
		context.fillStyle = draw.color;
		context.fillRect(pos.x, pos.y, size.w, size.h);
	}
}

class InputSystem extends EntitySystem {
	@auto public var inputs: awe.IComponentList<Input>;
	@auto public var speeds: awe.IComponentList<Speed>;
	@auto public var velocities: awe.IComponentList<Velocity>;
	@auto public var draw: DrawSystem;

	var input: InputData;

	public override function new() {
		super(Aspect.build(Input & Velocity & Speed));
		input = InputData.None;
	}

	public override function initialize(world: World) {
		super.initialize(world);
		draw.canvas.onkeydown = function(event) {
			switch(event.keyCode) {
				case 40: input = Up;
				case 38: input = Down;
			}
		};
		draw.canvas.onkeyup = function(event) {
			switch(event.keyCode) {
				case 38 | 40: input = None;
			}
		};
	}

	public override function processEntity(entity: Entity): Void {
		var speed = speeds.get(entity);
		var velocity = velocities.get(entity);
		velocity.y = speed.speed * world.delta * (switch input {
			case Up: -1;
			case Down: 1;
			case None: 0;
		});
	}
}

class Pong {
	static function main() {
		js.Browser.window.onload = function(_) {
			var world = World.build({
				components: [Bounce, Collide, Side, Speed, Position, Velocity, Size, Input, Draw],
				systems: [
					new DrawSystem(),
					new BounceSystem(),
					new CollisionSystem(),
					new MovementSystem(),
					new InputSystem()
				],
				managers: [
					new awe.managers.GroupManager()
				],
				expectedEntityCount: 3
			});
			var playerArch = Archetype.build(Size, Collide, Speed, Input, Position, Velocity, Draw);
			var player = playerArch.create(world);
			player.add(world, new Draw("red"));
			player.add(world, new Size(3, 50));
			player.add(world, new Position(65, 55));
			player.add(world, new Velocity(0, 0));
			player.add(world, new Speed(7000));
			player.add(world, new Input());
			var ballArch = Archetype.build(Size, Collide, Position, Velocity, Draw, Bounce);
			var ball = ballArch.create(world);
			ball.add(world, new Draw("blue"));
			ball.add(world, new Size(30, 30));
			ball.add(world, new Position(300, 300));
			ball.add(world, new Velocity(1000, 1000));
			world.delayLoop(0.04);
		};
	}
}