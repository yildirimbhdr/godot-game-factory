class_name Levels
## Level data. A level is a Dictionary:
##   cell      px per grid cell (default 92; use 84 for 11 rows)
##   mask      optional ASCII silhouette ('#' = filled), auto-split into jigsaw pieces in plane 0
##   cols/rows grid size when there is no mask
##   bars      [{plane, a: Vector2, b: Vector2, w}] capsule pieces between two grid points (cell units)
##   colors    how many screw colours
##   seed      makes piece split and colour assignment reproducible
## Rules the data must respect are in docs/puzzle-design.md of the plugin; check_levels.gd verifies them.

## Saturated screw/jar colours (pieces use the pastel PIECE_COLORS so screws stand out).
const COLORS := {
	"mint": Color("3FC79A"), "sky": Color("4A9BFF"), "peach": Color("FF9A55"),
	"butter": Color("FFC93C"), "lavender": Color("9B6BF0"), "coral": Color("FF5E73"),
}
const PIECE_COLORS: Array[Color] = [
	Color("FFD6E0"), Color("D6F5E8"), Color("D9E8FF"), Color("FFEBCB"),
	Color("EADDFB"), Color("FFF7C2"), Color("FFFFFF"), Color("E4E4EE"),
]

## Eight levels per world. Each world re-colours the backdrop and the board so the game does not look the same for 32 levels.
const LEVELS_PER_WORLD := 8
const WORLDS := [
	{"name": "Meadow", "top": Color("FFF4E8"), "bottom": Color("E9DDFB"), "blobs": [Color("FFC8D8"), Color("BFE6FF"), Color("C9F2DD")],
		"board": Color("F1E6FF"), "border": Color("5B4B8A"), "node": Color("3FC79A")},
	{"name": "Candy", "top": Color("FFF0F6"), "bottom": Color("D7F5EA"), "blobs": [Color("FFB3D1"), Color("FFE29A"), Color("B8F0DC")],
		"board": Color("FFE9F2"), "border": Color("8A4B7A"), "node": Color("FF7FB0")},
	{"name": "Sunset", "top": Color("FFE9D6"), "bottom": Color("F7C9D8"), "blobs": [Color("FFC27A"), Color("FF9AA2"), Color("FFE29A")],
		"board": Color("FFF0DF"), "border": Color("8A5B4B"), "node": Color("FF9A55")},
	{"name": "Night", "top": Color("4A4590"), "bottom": Color("201C45"), "blobs": [Color("6F63D9"), Color("3F7BD9"), Color("9B6BF0")],
		"board": Color("5A54A8"), "border": Color("1C1840"), "node": Color("9B6BF0")},
]


static func world_of(level: int) -> Dictionary:
	return WORLDS[mini(level / LEVELS_PER_WORLD, WORLDS.size() - 1)]


const DATA: Array[Dictionary] = [
	{ # 1 ladder: two sticks behind, three bars in front
		"name": "Ladder", "color_seed": 206, "target_greedy": 0.95, "max_greedy": 0.98, "deep_first": false, "cols": 9, "rows": 10, "colors": 3, "seed": 1,
		"bars": [
			{"plane": 0, "a": Vector2(1.5, 0.5), "b": Vector2(1.5, 9.5), "w": 0.9},
			{"plane": 0, "a": Vector2(7.5, 0.5), "b": Vector2(7.5, 9.5), "w": 0.9},
			{"plane": 1, "a": Vector2(0.5, 2.0), "b": Vector2(8.5, 2.0), "w": 1.0},
			{"plane": 1, "a": Vector2(0.5, 5.0), "b": Vector2(8.5, 5.0), "w": 1.0},
			{"plane": 1, "a": Vector2(0.5, 8.0), "b": Vector2(8.5, 8.0), "w": 1.0},
		],
	},
	{ # 2 house, one strap across it
		"name": "House", "color_seed": 201, "target_greedy": 0.45, "max_greedy": 0.60, "deep_first": true, "jars_visible": 2, "colors": 3, "seed": 5, "piece_size": [4, 6],
		"mask": [
			"....#....",
			"...###...",
			"..#####..",
			".#######.",
			"#########",
			".#######.",
			".##...##.",
			".##...##.",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 4.5), "b": Vector2(8.5, 4.5), "w": 0.9},
			{"plane": 1, "a": Vector2(1.5, 2.0), "b": Vector2(7.5, 2.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # 3 heart under a cross of two straps
		"name": "Heart", "color_seed": 203, "target_greedy": 0.3, "max_greedy": 0.45, "deep_first": true, "jars_visible": 2, "colors": 4, "seed": 7, "piece_size": [4, 6],
		"mask": [
			".##...##.",
			"####.####",
			"#########",
			"#########",
			".#######.",
			"..#####..",
			"...###...",
			"....#....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 0.5), "b": Vector2(8.5, 6.5), "w": 0.9},
			{"plane": 1, "a": Vector2(8.5, 0.5), "b": Vector2(0.5, 6.5), "w": 0.9},
		],
	},
	{ # 4 weave: three depth planes
		"name": "Weave", "color_seed": 53, "target_greedy": 0.2, "max_greedy": 0.35, "deep_first": true, "jars_visible": 2, "cols": 9, "rows": 10, "colors": 4, "seed": 3,
		"bars": [
			{"plane": 0, "a": Vector2(1.5, 0.5), "b": Vector2(1.5, 9.5), "w": 0.9},
			{"plane": 0, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 9.5), "w": 0.9},
			{"plane": 0, "a": Vector2(7.5, 0.5), "b": Vector2(7.5, 9.5), "w": 0.9},
			{"plane": 1, "a": Vector2(0.5, 1.5), "b": Vector2(8.5, 1.5), "w": 0.9},
			{"plane": 1, "a": Vector2(0.5, 5.0), "b": Vector2(8.5, 5.0), "w": 0.9},
			{"plane": 1, "a": Vector2(0.5, 8.5), "b": Vector2(8.5, 8.5), "w": 0.9},
			{"plane": 2, "a": Vector2(0.5, 1.0), "b": Vector2(8.5, 9.0), "w": 0.9},
			{"plane": 2, "a": Vector2(8.5, 1.0), "b": Vector2(0.5, 9.0), "w": 0.9},
		],
	},
	{ # 5 rocket with two fins strapped on
		"name": "Rocket", "color_seed": 32, "target_greedy": 0.12, "max_greedy": 0.27, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 11, "piece_size": [4, 7],
		"mask": [
			"....#....",
			"...###...",
			"..#####..",
			"..#####..",
			"..#####..",
			"..#####..",
			".#######.",
			"##.###.##",
			"#..###..#",
			"...#.#...",
		],
		"bars": [
			{"plane": 1, "a": Vector2(1.0, 3.0), "b": Vector2(8.0, 3.0), "w": 0.9},
			{"plane": 1, "a": Vector2(1.0, 6.0), "b": Vector2(8.0, 6.0), "w": 0.9},
			{"plane": 2, "a": Vector2(1.0, 1.0), "b": Vector2(8.0, 8.5), "w": 0.8},
			{"plane": 2, "a": Vector2(8.0, 1.0), "b": Vector2(1.0, 8.5), "w": 0.8},
		],
	},
	{ # 6 cupcake
		"name": "Cupcake", "color_seed": 298, "target_greedy": 0.08, "max_greedy": 0.23, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 5, "piece_size": [4, 6],
		"mask": [
			"....#....",
			"...###...",
			"..#####..",
			".#######.",
			"#########",
			"#########",
			".#######.",
			"..#####..",
			"..#####..",
			"...###...",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 9.5), "w": 0.8},
			{"plane": 2, "a": Vector2(0.5, 1.0), "b": Vector2(8.5, 9.0), "w": 0.8},
		],
	},
	{ # 7 star
		"name": "Star", "color_seed": 228, "target_greedy": 0.06, "max_greedy": 0.21, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 8, "piece_size": [4, 6],
		"mask": [
			"....#....",
			"....#....",
			"...###...",
			"#########",
			".#######.",
			"..#####..",
			"..##.##..",
			".##...##.",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 4.5), "b": Vector2(8.5, 4.5), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # 8 big weave, six colours
		"name": "Tangle", "color_seed": 136, "target_greedy": 0.04, "max_greedy": 0.19, "deep_first": true, "jars_visible": 2, "cell": 84, "cols": 9, "rows": 11, "colors": 6, "seed": 9,
		"bars": [
			{"plane": 0, "a": Vector2(1.5, 0.5), "b": Vector2(1.5, 10.5), "w": 0.9},
			{"plane": 0, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 10.5), "w": 0.9},
			{"plane": 0, "a": Vector2(7.5, 0.5), "b": Vector2(7.5, 10.5), "w": 0.9},
			{"plane": 1, "a": Vector2(0.5, 2.0), "b": Vector2(8.5, 2.0), "w": 0.9},
			{"plane": 1, "a": Vector2(0.5, 5.5), "b": Vector2(8.5, 5.5), "w": 0.9},
			{"plane": 1, "a": Vector2(0.5, 9.0), "b": Vector2(8.5, 9.0), "w": 0.9},
			{"plane": 2, "a": Vector2(0.5, 1.0), "b": Vector2(8.5, 10.0), "w": 0.9},
			{"plane": 2, "a": Vector2(8.5, 1.0), "b": Vector2(0.5, 10.0), "w": 0.9},
		],
	},	{ # 9 balloon
		"name": "Balloon", "color_seed": 191, "target_greedy": 0.08, "max_greedy": 0.25, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 11, "piece_size": [4, 6],
		"mask": [
			"..#####..",
			".#######.",
			"#########",
			"#########",
			"#########",
			".#######.",
			"..#####..",
			"...###...",
			"....#....",
			"....#....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(1.0, 0.5), "b": Vector2(8.0, 7.5), "w": 0.8},
		],
	},
	{ # 10 fish
		"name": "Fish", "color_seed": 162, "target_greedy": 0.07, "max_greedy": 0.22, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 6, "piece_size": [4, 6],
		"mask": [
			"..####...",
			".######.#",
			"#########",
			"#########",
			".######.#",
			"..####...",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 2.5), "b": Vector2(8.5, 2.5), "w": 0.9},
			{"plane": 2, "a": Vector2(1.5, 0.5), "b": Vector2(7.5, 5.5), "w": 0.8},
		],
	},
	{ # 11 key
		"name": "Key", "color_seed": 207, "target_greedy": 0.07, "max_greedy": 0.22, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 13, "piece_size": [4, 6],
		"mask": [
			".#####...",
			"#######..",
			"##...##..",
			"#######..",
			".#####...",
			"...#.....",
			"...##....",
			"...#.....",
			"...##....",
			"...#.....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 2.0), "b": Vector2(6.5, 2.0), "w": 0.9},
			{"plane": 2, "a": Vector2(3.5, 0.5), "b": Vector2(3.5, 9.5), "w": 0.8},
		],
	},
	{ # 12 pine tree
		"name": "Pine", "color_seed": 243, "target_greedy": 0.06, "max_greedy": 0.2, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 4, "piece_size": [4, 6],
		"mask": [
			"....#....",
			"...###...",
			"..#####..",
			".#######.",
			"...###...",
			"..#####..",
			".#######.",
			"#########",
			"....#....",
			"....#....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 5.5), "b": Vector2(8.5, 5.5), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 9.5), "w": 0.8},
		],
	},
	{ # 13 crown
		"name": "Crown", "color_seed": 51, "target_greedy": 0.06, "max_greedy": 0.2, "deep_first": true, "jars_visible": 2, "colors": 5, "seed": 5, "piece_size": [4, 6],
		"mask": [
			"#...#...#",
			"##..#..##",
			"#########",
			"#########",
			"#########",
			".#######.",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(0.5, 0.5), "b": Vector2(8.5, 5.5), "w": 0.8},
			{"plane": 2, "a": Vector2(8.5, 0.5), "b": Vector2(0.5, 5.5), "w": 0.8},
		],
	},
	{ # 14 mushroom
		"name": "Mushroom", "color_seed": 236, "target_greedy": 0.05, "max_greedy": 0.18, "deep_first": true, "jars_visible": 2, "colors": 6, "seed": 7, "piece_size": [4, 6],
		"mask": [
			"..#####..",
			".#######.",
			"#########",
			"#########",
			".#######.",
			"...###...",
			"...###...",
			"...###...",
			"..#####..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 1, "a": Vector2(2.0, 6.5), "b": Vector2(7.0, 6.5), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 8.5), "w": 0.8},
		],
	},
	{ # 15 sailboat
		"name": "Sailboat", "color_seed": 123, "target_greedy": 0.05, "max_greedy": 0.18, "deep_first": true, "jars_visible": 2, "colors": 6, "seed": 8, "piece_size": [4, 6],
		"mask": [
			"....##...",
			"...###...",
			"..####...",
			".#####...",
			"######...",
			"....#....",
			"#########",
			".#######.",
			"..#####..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 4.0), "b": Vector2(8.5, 6.5), "w": 0.9},
			{"plane": 2, "a": Vector2(0.5, 6.5), "b": Vector2(8.5, 6.5), "w": 0.8},
		],
	},
	{ # 16 castle
		"name": "Castle", "color_seed": 167, "target_greedy": 0.04, "max_greedy": 0.16, "deep_first": true, "jars_visible": 2, "colors": 6, "seed": 9, "piece_size": [4, 6],
		"mask": [
			"#.#.#.#.#",
			"#########",
			".#######.",
			".#######.",
			".##.#.##.",
			".##...##.",
			".##...##.",
			"#########",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 2.0), "b": Vector2(8.5, 2.0), "w": 0.9},
			{"plane": 2, "a": Vector2(0.5, 0.5), "b": Vector2(8.5, 7.0), "w": 0.8},
		],
	},
	{ # 17 cat
		"name": "Cat", "color_seed": 202, "target_greedy": 0.04, "max_greedy": 0.16, "deep_first": true, "jars_visible": 2, "colors": 6, "seed": 10, "piece_size": [4, 6],
		"mask": [
			"#.......#",
			"##.....##",
			"#########",
			"#########",
			"#.##.##.#",
			"#########",
			".#######.",
			"..#####..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.5), "b": Vector2(8.5, 3.5), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
			{"plane": 2, "a": Vector2(0.5, 1.0), "b": Vector2(8.5, 6.0), "w": 0.8},
		],
	},
	{ # 18 diamond, last of the pilot set
		"name": "Diamond", "color_seed": 267, "target_greedy": 0.03, "max_greedy": 0.15, "deep_first": true, "jars_visible": 2, "colors": 6, "seed": 12, "piece_size": [4, 6],
		"mask": [
			"..#####..",
			".#######.",
			"#########",
			".#######.",
			"..#####..",
			"...###...",
			"....#....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 2.0), "b": Vector2(8.5, 2.0), "w": 0.9},
			{"plane": 2, "a": Vector2(0.5, 0.5), "b": Vector2(8.5, 5.5), "w": 0.8},
			{"plane": 2, "a": Vector2(8.5, 0.5), "b": Vector2(0.5, 5.5), "w": 0.8},
		],
	},

	{ # apple
		"name": "Apple", "color_seed": 98, "target_greedy": 0.2, "max_greedy": 0.45, "deep_first": true, "jars_visible": 3, "tray": 4, "colors": 4, "seed": 1, "piece_size": [4, 6],
		"mask": [
			"....#....",
			".##.#.##.",
			"#########",
			"#########",
			"#########",
			"#########",
			".#######.",
			"..##.##..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # ghost
		"name": "Ghost", "color_seed": 52, "target_greedy": 0.08, "max_greedy": 0.20, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 5, "seed": 2, "piece_size": [4, 6],
		"mask": [
			"..#####..",
			".#######.",
			"#########",
			"##.###.##",
			"#########",
			"#########",
			"#########",
			"##.#.#.##",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # moon
		"name": "Moon", "color_seed": 114, "target_greedy": 0.08, "max_greedy": 0.20, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 5, "seed": 4, "piece_size": [4, 6],
		"mask": [
			"..####...",
			".####....",
			"####.....",
			"####.....",
			"####.....",
			".####....",
			"..####...",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 6.5), "w": 0.8},
		],
	},
	{ # cloud
		"name": "Cloud", "color_seed": 55, "target_greedy": 0.1, "max_greedy": 0.22, "deep_first": true, "jars_visible": 2, "tray": 4, "colors": 6, "seed": 2, "piece_size": [4, 6],
		"mask": [
			"...###...",
			".#######.",
			"#########",
			"#########",
			".#######.",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 2.0), "b": Vector2(8.5, 2.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 4.5), "w": 0.8},
		],
	},
	{ # umbrella
		"name": "Umbrella", "color_seed": 209, "target_greedy": 0.07, "max_greedy": 0.19, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 5, "seed": 2, "piece_size": [4, 6],
		"mask": [
			"..#####..",
			".#######.",
			"#########",
			"#########",
			"....#....",
			"....#....",
			"....#....",
			"...##....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # bell
		"name": "Bell", "color_seed": 29, "target_greedy": 0.06, "max_greedy": 0.18, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 5, "seed": 6, "piece_size": [4, 7],
		"mask": [
			"....#....",
			"...###...",
			"..#####..",
			"..#####..",
			".#######.",
			".#######.",
			"#########",
			"#########",
			"....#....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.5), "b": Vector2(8.5, 3.5), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 8.5), "w": 0.8},
		],
	},
	{ # anchor
		"name": "Anchor", "color_seed": 175, "target_greedy": 0.06, "max_greedy": 0.18, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 6, "seed": 1, "piece_size": [4, 6],
		"mask": [
			"....#....",
			"...###...",
			"....#....",
			".#######.",
			"....#....",
			"....#....",
			"#...#...#",
			"##..#..##",
			".#######.",
			"..#####..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 4.0), "b": Vector2(8.5, 4.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 9.5), "w": 0.8},
		],
	},
	{ # snowman
		"name": "Snowman", "color_seed": 120, "target_greedy": 0.1, "max_greedy": 0.22, "deep_first": true, "jars_visible": 3, "tray": 2, "colors": 4, "seed": 3, "piece_size": [4, 6],
		"mask": [
			"...###...",
			"..#####...",
			"...###...",
			"..#####..",
			".#######.",
			".#######.",
			".#######.",
			"..#####..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # robot
		"name": "Robot", "color_seed": 218, "target_greedy": 0.05, "max_greedy": 0.17, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 6, "seed": 1, "piece_size": [3, 5],
		"mask": [
			"....#....",
			"...###...",
			".#######.",
			".##.#.##.",
			".#######.",
			".#######.",
			"#.#####.#",
			"#.#####.#",
			"..##.##..",
			"..##.##..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 4.0), "b": Vector2(8.5, 4.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 9.5), "w": 0.8},
		],
	},
	{ # lighthouse
		"name": "Lighthouse", "color_seed": 257, "target_greedy": 0.06, "max_greedy": 0.18, "deep_first": true, "jars_visible": 1, "tray": 3, "colors": 5, "seed": 3, "piece_size": [4, 6],
		"mask": [
			"...###...",
			"..#####..",
			"...###...",
			"...###...",
			"..#####..",
			"..#####..",
			"..#####..",
			".#######.",
			"#########",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.5), "b": Vector2(8.5, 3.5), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 8.5), "w": 0.8},
		],
	},
	{ # butterfly
		"name": "Butterfly", "color_seed": 203, "target_greedy": 0.05, "max_greedy": 0.17, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 6, "seed": 8, "piece_size": [4, 6],
		"mask": [
			"##.....##",
			"####.####",
			"#########",
			".#######.",
			"#########",
			"####.####",
			"##.....##",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 6.5), "w": 0.8},
		],
	},
	{ # tulip
		"name": "Tulip", "color_seed": 256, "target_greedy": 0.06, "max_greedy": 0.18, "deep_first": true, "jars_visible": 2, "tray": 4, "colors": 6, "seed": 7, "piece_size": [4, 6],
		"mask": [
			"#..#.#..#",
			"##.###.##",
			"#########",
			".#######.",
			"..#####..",
			"....#....",
			"....#....",
			"...##....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # trophy
		"name": "Trophy", "color_seed": 226, "target_greedy": 0.04, "max_greedy": 0.16, "deep_first": true, "jars_visible": 2, "tray": 3, "colors": 6, "seed": 2, "piece_size": [4, 6],
		"mask": [
			"#########",
			"#.#####.#",
			".#######.",
			"..#####..",
			"...###...",
			"....#....",
			"...###...",
			"..#####..",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
	{ # gem
		"name": "Gem", "color_seed": 142, "target_greedy": 0.04, "max_greedy": 0.16, "deep_first": true, "jars_visible": 1, "tray": 3, "colors": 6, "seed": 1, "piece_size": [4, 6],
		"mask": [
			"..#####..",
			".#######.",
			"#########",
			"#########",
			".#######.",
			"..#####..",
			"...###...",
			"....#....",
		],
		"bars": [
			{"plane": 1, "a": Vector2(0.5, 3.0), "b": Vector2(8.5, 3.0), "w": 0.9},
			{"plane": 2, "a": Vector2(4.5, 0.5), "b": Vector2(4.5, 7.5), "w": 0.8},
		],
	},
]
