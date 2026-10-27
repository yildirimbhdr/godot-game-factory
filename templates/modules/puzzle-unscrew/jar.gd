class_name Jar
extends Node2D
## A collector jar with three sockets. Holds screws of one colour; `reserve()` claims a socket
## before the screw has finished flying so two screws never target the same one.

const SLOT_FRACTIONS: Array[Vector2] = [Vector2(-0.016, -0.156), Vector2(-0.18, 0.11), Vector2(0.17, 0.11)]
const TEXTURE_SIZE := 256.0

var color_name := ""
var heads: Array[Screw] = []
var _taken: Array[bool] = [false, false, false]


func setup(color_key: String) -> Jar:
	color_name = color_key
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/art/jars/jar_%s.png" % color_key)
	add_child(sprite)
	return self


func free_slots() -> int:
	return _taken.count(false)


func reserve() -> int:
	var i := _taken.find(false)
	_taken[i] = true
	return i


func slot_position(i: int) -> Vector2:
	return global_position + SLOT_FRACTIONS[i] * TEXTURE_SIZE * scale


## Returns true when this landing filled the jar.
func land(head: Screw, slot: int) -> bool:
	head.reparent(self, true)
	head.position = SLOT_FRACTIONS[slot] * TEXTURE_SIZE
	heads.append(head)
	return heads.size() == 3
