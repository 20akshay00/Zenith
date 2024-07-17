@tool
extends Node2D
class_name ConstrainedSpine

@onready var segments = get_children()
var segment_constraints: Array[float] = []
var segment_directions = []

@export var editable: bool = true :
	set(value):
		if editable: 
			_compute_segment_constraints()
			queue_redraw()	
		else: 
			_reset_positions()

		segments.map(func(segment): segment.editable = value)
		editable = value

func _ready():
	_compute_segment_constraints()

func _process(delta):
	queue_redraw()	
	if not editable: _enforce_segment_constraints()

func _draw():
	_draw_body()

	if editable:
		var positions: Array[Vector2] = []
		for i in range(segments.size() - 1):
			positions.append(segments[i].position)
			positions.append(segments[i+1].position)			
		
		draw_multiline(PackedVector2Array(positions), Color(0., 0.6, 0.69), 0.5)

func _draw_body():
	var points: Array[Vector2] = []
	_compute_segment_directions()
	points.append(_get_segment_arc_point(0, -PI/2))
	points.append(_get_segment_arc_point(0, -PI/4))
	points.append(_get_segment_arc_point(0, 0))
	points.append(_get_segment_arc_point(0, PI/4))
	points.append(_get_segment_arc_point(0, PI/2))	
	
	for i in range(1, segments.size()): points.append(_get_segment_arc_point(i, PI/2))

	points.append(_get_segment_arc_point(segments.size()-1, 3*PI/4))
	points.append(_get_segment_arc_point(segments.size()-1, PI))
	points.append(_get_segment_arc_point(segments.size()-1, -3*PI/4))	
	
	for i in range(segments.size() - 1, 0, -1): points.append(_get_segment_arc_point(i, -PI/2))
	
	var smooth_points: Array[Vector2] = []
	for i in range(points.size()):
		var interpolated_points := [0.25, 0.5, 0.75, 1.].map(
			func(weight): return points[i].cubic_interpolate(points[(i+1)%points.size()], points[i-1], points[(i+2)%points.size()], weight)
		)
		smooth_points.append_array(interpolated_points)
	
	draw_colored_polygon(PackedVector2Array(smooth_points), Color(0.658, 0.223, 0.192))
	draw_polyline(PackedVector2Array(smooth_points), Color.WHITE, 0.1)
	draw_line(smooth_points[-1], smooth_points[0], Color.WHITE, 0.1)

func _compute_segment_directions() -> void:
	segment_directions = range(segments.size() - 1).map(func(i: int) -> float: return (segments[i].position - segments[i+1].position).angle())
	segment_directions.insert(0, segment_directions[0])

func _get_segment_arc_point(idx: int, angle: float) -> Vector2:
	var point: Vector2 = segments[idx].position + segments[idx].radius * Vector2(cos(segment_directions[idx] + angle), sin(segment_directions[idx] + angle))
	return point

func _enforce_segment_constraints():
	for i in range(segments.size() - 1):
		segments[i+1].position = segments[i].position + (segments[i+1].position - segments[i].position).normalized() * (segment_constraints[i])

func _compute_segment_constraints():
	segment_constraints = []
	for i in range(segments.size() - 1):
		segment_constraints.append((segments[i].position - segments[i+1].position).length())
		
func _reset_positions():
	segments[0].position = Vector2(350., 200.)
	for i in range(segments.size() - 1):
		segments[i+1].position = segments[i].position - Vector2(segment_constraints[i], 0.)

func _on_child_entered_tree(node):
	var positions := segments.map(func(segment): return segment.position)
	var idx := positions.find(node.position)
	move_child(node, idx + 1)
	segments = get_children()
	_compute_segment_constraints()

func _on_child_exiting_tree(node):
	segments = segments.filter(func(segment): return segment != node)
	_compute_segment_constraints()
