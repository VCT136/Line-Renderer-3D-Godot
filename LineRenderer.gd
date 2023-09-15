extends MeshInstance3D

@export var points: Array[Vector3] = [Vector3(0,0,0),Vector3(0,5,0)]
@export var startThickness: float = 0.1
@export var endThickness: float = 0.1
@export var cornerSmooth = 5
@export var capSmooth = 5
@export var drawCaps: bool = true
@export var drawCorners: bool = true
@export var globalCoords: bool = true
@export var scaleTexture: bool = true
@export var material: Material = null
@export var cameraAddress: String = "/root/main/camera/Camera3D"

var camera
var cameraOrigin

func _ready():
	mesh = ImmediateMesh.new()

func _process(delta):
	if points.size() < 2:
		return
	
	camera = get_node(cameraAddress)
	if camera == null:
		cameraOrigin = to_local(Vector3.ZERO)
	else:
		cameraOrigin = to_local(camera.get_global_transform().origin)
	
	var progressStep = 1.0 / points.size();
	var progress = 0;
	var thickness = lerp(startThickness, endThickness, progress);
	var nextThickness = lerp(startThickness, endThickness, progress + progressStep);
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(points.size() - 1):
		var A = points[i]
		var B = points[i+1]
	
		if globalCoords:
			A = to_local(A)
			B = to_local(B)
	
		var AB = B - A;
		var orthogonalABStart = (cameraOrigin - ((A + B) / 2)).cross(AB).normalized() * thickness;
		var orthogonalABEnd = (cameraOrigin - ((A + B) / 2)).cross(AB).normalized() * nextThickness;
		
		var AtoABStart = A + orthogonalABStart
		var AfromABStart = A - orthogonalABStart
		var BtoABEnd = B + orthogonalABEnd
		var BfromABEnd = B - orthogonalABEnd
		
		if i == 0:
			if drawCaps:
				cap(A, B, thickness, capSmooth)
		
		if scaleTexture:
			var ABLen = AB.length()
			var ABFloor = floor(ABLen)
			var ABFrac = ABLen - ABFloor
			
			mesh.surface_set_uv(Vector2(ABFloor, 0))
			mesh.surface_add_vertex(AtoABStart)
			mesh.surface_set_uv(Vector2(-ABFrac, 0))
			mesh.surface_add_vertex(BtoABEnd)
			mesh.surface_set_uv(Vector2(ABFloor, 1))
			mesh.surface_add_vertex(AfromABStart)
			mesh.surface_set_uv(Vector2(-ABFrac, 0))
			mesh.surface_add_vertex(BtoABEnd)
			mesh.surface_set_uv(Vector2(-ABFrac, 1))
			mesh.surface_add_vertex(BfromABEnd)
			mesh.surface_set_uv(Vector2(ABFloor, 1))
			mesh.surface_add_vertex(AfromABStart)
		else:
			mesh.surface_set_uv(Vector2(1, 0))
			mesh.surface_add_vertex(AtoABStart)
			mesh.surface_set_uv(Vector2(0, 0))
			mesh.surface_add_vertex(BtoABEnd)
			mesh.surface_set_uv(Vector2(1, 1))
			mesh.surface_add_vertex(AfromABStart)
			mesh.surface_set_uv(Vector2(0, 0))
			mesh.surface_add_vertex(BtoABEnd)
			mesh.surface_set_uv(Vector2(0, 1))
			mesh.surface_add_vertex(BfromABEnd)
			mesh.surface_set_uv(Vector2(1, 1))
			mesh.surface_add_vertex(AfromABStart)
		
		if i == points.size() - 2:
			if drawCaps:
				cap(B, A, nextThickness, capSmooth)
		else:
			if drawCorners:
				var C = points[i+2]
				if globalCoords:
					C = to_local(C)
				
				var BC = C - B;
				var orthogonalBCStart = (cameraOrigin - ((B + C) / 2)).cross(BC).normalized() * nextThickness;
				
				var angleDot = AB.dot(orthogonalBCStart)
				
				if angleDot > 0:
					corner(B, BtoABEnd, B + orthogonalBCStart, cornerSmooth)
				else:
					corner(B, B - orthogonalBCStart, BfromABEnd, cornerSmooth)
		
		progress += progressStep;
		thickness = lerp(startThickness, endThickness, progress);
		nextThickness = lerp(startThickness, endThickness, progress + progressStep);
	
	mesh.surface_end()
	mesh.surface_set_material(0, material)

func cap(center, pivot, thickness, smoothing):
	var orthogonal = (cameraOrigin - center).cross(center - pivot).normalized() * thickness;
	var axis = (center - cameraOrigin).normalized();
	
	var array = []
	for i in range(smoothing + 1):
		array.append(Vector3(0,0,0))
	array[0] = center + orthogonal;
	array[smoothing] = center - orthogonal;
	
	for i in range(1, smoothing):
		array[i] = center + (orthogonal.rotated(axis, lerpf(0, PI, float(i) / smoothing)));
	
	for i in range(1, smoothing + 1):
		mesh.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		mesh.surface_add_vertex(array[i - 1]);
		mesh.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		mesh.surface_add_vertex(array[i]);
		mesh.surface_set_uv(Vector2(0.5, 0.5))
		mesh.surface_add_vertex(center);
		
func corner(center, start, end, smoothing):
	var array = []
	for i in range(smoothing + 1):
		array.append(Vector3(0,0,0))
	array[0] = start;
	array[smoothing] = end;
	
	var axis = start.cross(end).normalized()
	var offset = start - center
	var angle = offset.angle_to(end - center)
	
	for i in range(1, smoothing):
		array[i] = center + offset.rotated(axis, lerpf(0, angle, float(i) / smoothing));
	
	for i in range(1, smoothing + 1):
		mesh.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		mesh.surface_add_vertex(array[i - 1]);
		mesh.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		mesh.surface_add_vertex(array[i]);
		mesh.surface_set_uv(Vector2(0.5, 0.5))
		mesh.surface_add_vertex(center);
