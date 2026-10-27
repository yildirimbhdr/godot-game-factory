class_name Levels
extends RefCounted
## Level list. The data lives in levels_data.gd, produced by tools/gen_levels.gd (never hand-edited).

const DATA: Array[Dictionary] = LevelsData.DATA
const LEVELS_PER_WORLD := 10
const WORLD_NAMES: Array[String] = ["Mirrors", "Colors", "Mixers", "Splitters", "Filters", "Everything"]
const WORLD_COLORS: Array[Color] = [Color("B8C4FF"), Color("FF4D6D"), Color("D65DB1"), Color("5DE0E6"), Color("FFD166"), Color("3DDC97")]
const WORLD_HINTS: Array[String] = [
	"Tap a mirror to flip it. Light every crystal!",
	"Crystals only open for beams of their own color.",
	"A mixer merges beams: red + blue = magenta.",
	"A splitter sends a beam two ways at once.",
	"A filter lets only its own color through.",
	"Everything together. Take your time.",
]


static func world_of(index: int) -> int:
	return clampi(index / LEVELS_PER_WORLD, 0, WORLD_NAMES.size() - 1)


static func stars_for(moves: int, par: int) -> int:
	if moves <= par:
		return 3
	return 2 if moves <= par + 2 else 1
