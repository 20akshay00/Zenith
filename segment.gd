@tool
extends Marker2D
class_name Segment

var editable: bool = true :
	set(value):
		radius_marker.visible = value
		editable = value

var radius: float = 5. 
@onready var radius_marker := $RadiusMarker

func _ready():
	if not Engine.is_editor_hint():
		editable = false
		visible = false

func _process(delta):
	# compute radius
	radius = radius_marker.position.length()
	
	# rescale gizmo extents
	gizmo_extents = radius / 5.
	radius_marker.gizmo_extents = radius / 10.
	
	queue_redraw()

func _draw():
	if Engine.is_editor_hint() and editable:
		draw_circle(Vector2.ZERO, radius, Color(0.174, 0.427, 0.47, 0.5))
		draw_arc(Vector2.ZERO, radius, 0., 2*PI, 30, Color(0., 0.6, 0.69, 0.5), 0.25)
