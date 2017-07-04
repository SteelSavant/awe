import awe.Archetype;
import awe.Component;
import awe.ComponentList;
import awe.World;
import awe.Entity;
import awe.System;
import awe.Aspect;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasElement;

@auto
class Collide implements Component {}

@auto
class Size implements Component {
	public var w: Float;
	public var h: Float;
	public function set(w, h) {
		this.w = w;
		this.h = h;
	}
}
@auto
class Position implements Component {
	public var x: Float;
	public var y: Float;
	public function set(x, y) {
		this.x = x;
		this.y = y;
	}
}
@auto
class Velocity implements Component {
	public var x: Float;
	public var y: Float;
	public function set(x, y) {
		this.x = x;
		this.y = y;
	}
}
enum InputData {
	Up;
	Down;
	None;
}

@auto
class Input implements Component {}
@auto
class Bounce implements Component {}
enum SideData {
	Left;
	Right;
}
@auto
class Side implements Component {
	public var side: SideData;
	public function new(side: SideData = null)
		this.side = side;
}

@auto
class Draw implements Component {
	public var color: String;
	public function new(color: String = "white")
		this.color = color;
}
@auto
class Speed implements Component {
	public var speed: Float;
	public function new(speed: Float = 100)
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
			case Up: 1;
			case Down: -1;
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
					new InputSystem(),
					new awe.managers.GroupManager()
				],
				expectedEntityCount: 3
			});
			var playerArch = Archetype.build(Size, Speed, Input, Position, Velocity, Draw);
			var player = playerArch.create(world);
			player.get(world, Draw).color = "red";
			player.get(world, Velocity).set(0, 0);
			var size: Size = player.get(world, Size);
			size.set(3, 50);
			var pos:Position = player.get(world, Position);
			pos.set(65, 55);
			player.get(world, Speed).speed = 1000;
			var ballArch = Archetype.build(Size, Position, Velocity, Draw, Bounce);
			var ball = ballArch.create(world);
			ball.get(world, Draw).color = "blue";
			ball.get(world, Size).set(30, 30);
			ball.get(world, Position).set(300, 300);
			ball.get(world, Velocity).set(100, 100);
			world.delayLoop(0.05);
		};
	}
}