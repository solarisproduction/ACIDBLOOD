class_name Visuals
extends RefCounted
## Shared placeholder-material cache so primitive actors don't allocate one
## material per instance (mobile-friendly).

static var _mats: Dictionary = {}

static func mat(color: Color, unshaded := false) -> StandardMaterial3D:
	var key := "%s|%s" % [color.to_html(), unshaded]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		if unshaded:
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mats[key] = m
	return _mats[key]

static func mesh_instance(mesh: Mesh, color: Color, unshaded := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, unshaded)
	return mi
