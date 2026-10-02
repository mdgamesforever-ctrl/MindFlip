extends Node2D
# Separate CanvasItem keeps modal shading and panels above the live board,
# while native Control buttons remain the final input/presentation layer.
var game: Node2D
func _draw() -> void:
	if game != null: game.draw_overlay(self)
