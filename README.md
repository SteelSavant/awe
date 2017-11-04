Awe
===

[API Reference](https://tombebb.github.io/awe/)

Awe is a *pure* entity component system heavily inspired by [Artemis](https://github.com/junkdog/artemis-odb), but taking advantage of Haxe features like macros and conditional compilation.

Basic ECS principles
--------------------

An **entity** represents an individual thing in the world, but does *not* actually
store any data by itself - this is simply an integer that uniquely identifies an entity.

A **component** is a small, composable piece of data that can be stored about an entity.

A **system** is a kind of object that performs operations on entities with certain 
component combinations.

More information is on the [t-machine wiki](http://entity-systems.wikidot.com/rdbms-with-code-in-systems).

Making the `World`
-------------------

The `World` is the what encapsulates all the components and systems contained in
the project. To construct it, you call `World.build(...)` with the entities and
systems you want it to have.

``` haxe
var world = World.build({
	systems: [new InputSystem(), new MovementSystem(), new RenderSystem(), new GravitySystem()],
	components: [Input, Position, Velocity, Acceleration, Gravity, Follow],
	expectedEntityCount: ...
});
```
Making Entities
---------------

An `Entity` represents a single thing in the `World`. To construct this, you need to
construct an `Archetype` by calling `Archetype.build(...)` with the components that
compose it.

``` haxe
var playerArchetype = Archetype.build(Input, Position, Velocity, Acceleration, Gravity);
var player = playerArchetype.build(world);
```

Types of component
------------------
### @Packed
This is a component that can be represented by bytes, thus doesn't have any fields whose type is not primitve.
### @Empty
This is a component that is used for marking components and has no fields.
### Regular
This is just a regular component.

Compiler flags
-----
These can be passed to haxe by adding '-D flag' to your 'build.hxml' or equivalent.
### debug
This prints extra information during compilation.
### nopack
This forces Awe's macro system to not pack components.