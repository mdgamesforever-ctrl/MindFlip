class_name MindVisuals
extends RefCounted
const FONT = preload("res://assets/fonts/DejaVuSans.ttf")
const BOLD = preload("res://assets/fonts/DejaVuSans-Bold.ttf")
const BG = Color("0b1220")
const PANEL = Color("121e2d")
const TILE = Color("1d2d3c")
const LINE = Color("29404e")
const TEXT = Color("ecf3f1")
const MUTED = Color("91a4b7")
const MINT = Color("78efd0")
const GOLD = Color("f5ca7c")
const VIOLET = Color("b6a0ff")
const CORAL = Color("ff9a94")
static func style(fill: Color, border: Color = Color.TRANSPARENT, radius: int = 14, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = fill; s.border_color = border
	s.set_corner_radius_all(radius); s.set_border_width_all(width); s.anti_aliasing = true
	return s
static func energy(color: String) -> Color:
	match color:
		"violet": return VIOLET
		"coral": return CORAL
		_: return MINT
static func star(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var a := -PI/2+i*PI/5; var r := radius if i%2==0 else radius*.46
		points.append(center+Vector2(cos(a),sin(a))*r)
	return points
