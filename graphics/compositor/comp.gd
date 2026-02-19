@tool
extends CompositorEffect
class_name PostProcessShader


# Basic CompositorEffect Tutorial Followed: https://docs.godotengine.org/en/stable/tutorials/rendering/compositor.html
# More Advanced CompositorEffect Example: https://github.com/BastiaanOlij/RERadialSunRays/blob/master/radial_sky_rays/radial_sky_rays.gd
# How manifold garden detects outlines: https://youtu.be/5VozHerlOQw?t=675
# How Jump Fill works for thickening outlines: https://bgolus.medium.com/the-quest-for-very-wide-outlines-ba82ed442cd9



# TODO:
# Use uniform buffer instead push constants where ever possible



# TODO: Outline Shader
# make an inital outline detection shader that reads depth and normal and writes to new buffer
# make expansion shader that does one iteration of jump fill (will be disbatched multiple times)
# make an merge shader that apples the generated SDF to the original image as an outline


@export var basic_shader_file: RDShaderFile:
	set(new):
		basic_shader_file = _set_rd_shader_file(new, basic_shader_file, &"basic")

@export var horz_blur_shader_file: RDShaderFile:
	set(new):
		horz_blur_shader_file = _set_rd_shader_file(new, horz_blur_shader_file, &"horz_blur")

@export var vert_blur_shader_file: RDShaderFile:
	set(new):
		vert_blur_shader_file = _set_rd_shader_file(new, vert_blur_shader_file, &"vert_blur")

@export var initial_outlines_shader_file: RDShaderFile:
	set(new):
		initial_outlines_shader_file = _set_rd_shader_file(new, initial_outlines_shader_file, &"initial_outlines")

@export var apply_outline_shader_file: RDShaderFile:
	set(new):
		apply_outline_shader_file = _set_rd_shader_file(new, apply_outline_shader_file, &"apply_outline")


# A helper function for the setters for the shaders to automatically connect/disconnect _shader_file_changed
func _set_rd_shader_file(new, previous, name: StringName):
	if new == previous: return previous
	if previous != null and previous.changed.is_connected(_shader_file_changed):
		previous.changed.disconnect(_shader_file_changed)
	if new != null and new.changed.is_connected(_shader_file_changed):
		new.changed.disconnect(_shader_file_changed)
	# previous = new # this deosnt work, so new is returned instead
	if new == null: return new
	new.changed.connect(_shader_file_changed.bind(new, name))
	new.changed.emit()
	return new


# called every time a shader is changed allowing hot reloading
# it will recompile the shader from SPIRV (which is compiled to by Godot automatically)
func _shader_file_changed(shader_file: RDShaderFile, name: StringName):
	var shader_spirv := shader_file.get_spirv()
	
	if shader_spirv == null: return
	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
		return
	
	RenderingServer.call_on_render_thread(_shader_file_changed_render_thread.bind(shader_spirv, name))




# Called when this resource is constructed.
func _init():
	RenderingServer.call_on_render_thread(_render_init)


# System notifications, we want to react on the notification that
# alerts us we are about to be destroyed.
# this happens after the rendering thread is done using about this
# so we dont need to worry about race conditions
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for key in shaders:
			if shaders[key].is_valid():
				# Freeing our shader will also free any dependents such as the pipeline
				rd.free_rid(shaders[key])


# main thread
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rendering thread

var rd: RenderingDevice = null

var linear_sampler: RID

func _render_init():
	rd = RenderingServer.get_rendering_device()
	
	var sampler_state = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	linear_sampler = rd.sampler_create(sampler_state)

var shaders: Dictionary[StringName, RID]
var pipelines: Dictionary[StringName, RID]

func _shader_file_changed_render_thread(shader_spirv: RDShaderSPIRV, name: StringName):
	var new_shader = rd.shader_create_from_spirv(shader_spirv)
	if not new_shader.is_valid(): return
	shaders[name] = new_shader
	pipelines[name] = rd.compute_pipeline_create(new_shader)




const name_context := &"OutlineShader"
const name_working_texture := &"working"
const name_working_texture2 := &"working2"


# STEPS:
# RoughNorm & Depth => texture		for outline with normals and depth
# texture =======> texture2			for jump1
# texture2 =======> texture			for jump2
# texture =======> texture2			for jump4
# texture2 =======> texture			for jump8
# texture =======> texture2			for jump16
# Color & texture2 ===> Color		for outline

func proj_to_float_array(proj: Projection):
	var array: PackedFloat32Array = PackedFloat32Array()
	array.push_back(proj.x.x)
	array.push_back(proj.x.y)
	array.push_back(proj.x.z)
	array.push_back(proj.x.w)
	array.push_back(proj.y.x)
	array.push_back(proj.y.y)
	array.push_back(proj.y.z)
	array.push_back(proj.y.w)
	array.push_back(proj.z.x)
	array.push_back(proj.z.y)
	array.push_back(proj.z.z)
	array.push_back(proj.z.w)
	array.push_back(proj.w.x)
	array.push_back(proj.w.y)
	array.push_back(proj.w.z)
	array.push_back(proj.w.w)
	return array

func proj_part_to_float_array(proj: Projection):
	var array: PackedFloat32Array = PackedFloat32Array()
	array.push_back(proj.x.x)
	array.push_back(proj.x.y)
	array.push_back(proj.x.z)
	array.push_back(proj.y.x)
	array.push_back(proj.y.y)
	array.push_back(proj.y.z)
	array.push_back(proj.z.x)
	array.push_back(proj.z.y)
	array.push_back(proj.z.z)
	array.push_back(proj.x.w)
	array.push_back(proj.y.w)
	array.push_back(proj.z.w)
	return array

func vec3_to_float_array(vec: Vector3):
	var array: PackedFloat32Array = PackedFloat32Array()
	array.push_back(vec.x)
	array.push_back(vec.y)
	array.push_back(vec.z)
	return array

# Called by the rendering thread every frame.
func _render_callback(_p_effect_callback_type: EffectCallbackType, p_render_data):
	if not rd: return
	if not pipelines[&"initial_outlines"].is_valid():
		push_error("initial_outlines invalid")
		return
	if not pipelines[&"apply_outline"].is_valid():
		push_error("apply_outline invalid")
		return
	
	# Get our render scene buffers object, this gives us access to our render buffers.
	# Note that implementation differs per renderer hence the need for the cast.
	var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
	var render_scene_data : RenderSceneDataRD = p_render_data.get_render_scene_data()
	if not render_scene_buffers: return
	
	# Get our render size, this is the 3D render resolution!
	var render_size := render_scene_buffers.get_internal_size()
	if render_size.x == 0 or render_size.y == 0: return
	
	@warning_ignore("integer_division")
	var groups := Vector3i(
		(render_size.x - 1) / 8 + 1,
		(render_size.y - 1) / 8 + 1,
		1
	)
	
	var projection := render_scene_data.get_cam_projection()
	
	# Push constant (needs to be multiple of 128 bytes aka multiple of 4 f32s)
	var small_push_constant: PackedFloat32Array = PackedFloat32Array()
	small_push_constant.push_back(render_size.x)
	small_push_constant.push_back(render_size.y)
	small_push_constant.push_back(1./render_size.x)
	small_push_constant.push_back(1./render_size.y)
	
	#var push_constant: PackedFloat32Array = PackedFloat32Array()
	#push_constant.append_array(small_push_constant)
	#push_constant.push_back(projection.w.z)
	#push_constant.push_back(projection.w.w)
	#push_constant.push_back(0.)
	#push_constant.push_back(0.)
	

	
	
	# If we have buffers for this viewport, check if they are the right size
	if render_scene_buffers.has_texture(name_context, name_working_texture):
		var texture_format : RDTextureFormat = render_scene_buffers.get_texture_format(name_context, name_working_texture)
		if texture_format.width != render_size.x or texture_format.height != render_size.y:
			# This will clear all textures for this viewport under this context
			render_scene_buffers.clear_context(name_context)
	
	# Create texture and texture2 on the GPU
	if !render_scene_buffers.has_texture(name_context, name_working_texture):
		var usage_bits : int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		render_scene_buffers.create_texture(
			name_context, name_working_texture,
			RenderingDevice.DATA_FORMAT_R16G16B16A16_UNORM, usage_bits,
			RenderingDevice.TEXTURE_SAMPLES_1, render_size,
			1, 1, true, false
		)
		render_scene_buffers.create_texture(
			name_context, name_working_texture2,
			RenderingDevice.DATA_FORMAT_R16G16B16A16_UNORM, usage_bits,
			RenderingDevice.TEXTURE_SAMPLES_1, render_size,
			1, 1, true, false
		)
	
	# Loop through views just in case we're doing stereo rendering. No extra cost if this is mono.
	var view_count = render_scene_buffers.get_view_count()
	for view in range(view_count):
		var view_proj := render_scene_data.get_view_projection(view)
		
		var push_constant_matrixes: PackedFloat32Array = PackedFloat32Array()
		push_constant_matrixes.append_array(small_push_constant)
		push_constant_matrixes.append_array(proj_to_float_array(projection.inverse()))
		push_constant_matrixes.append_array(proj_part_to_float_array(view_proj))
		push_constant_matrixes.append_array([0.,0.,0.,0.])
		
		# Get the RID for our images
		var color_image := _make_image_uniform(render_scene_buffers.get_color_layer(view))
		## using a sampler instead of an image (because bug https://github.com/godotengine/godot/issues/96737 make using it as an image not work)
		var depth_image := _make_sampler_uniform(render_scene_buffers.get_depth_layer(view))
		var norm_rough_image = _make_image_uniform(render_scene_buffers.get_texture("forward_clustered", "normal_roughness"))
		var working_image = _make_image_uniform(render_scene_buffers.get_texture_slice(name_context, name_working_texture, view, 0, 1, 1))
		var working2_image = _make_image_uniform(render_scene_buffers.get_texture_slice(name_context, name_working_texture2, view, 0, 1, 1))
		
		# Run our compute shader.
		
		
		
		_apply_pass(&"initial_outlines", [working_image, depth_image, norm_rough_image], [push_constant_matrixes], groups)
		_apply_pass(&"apply_outline", [working_image, color_image], [small_push_constant], groups)
		
		
		## ~~~BLUR~~~
		#_apply_pass(&"horz_blur", [color_image], small_push_constant, groups)
		#_apply_pass(&"vert_blur", [color_image], small_push_constant, groups)
		#_apply_pass(&"horz_blur", [color_image], small_push_constant, groups)
		#_apply_pass(&"vert_blur", [color_image], small_push_constant, groups)


func _make_image_uniform(image: RID) -> RDUniform:
	var uniform: RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(image)
	return uniform

func _make_sampler_uniform(image: RID) -> RDUniform:
	var uniform: RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = 0
	uniform.add_id(linear_sampler)
	uniform.add_id(image)
	return uniform


func _apply_pass(shader_name: StringName, uniforms: Array[RDUniform], push_constants: Array[PackedFloat32Array], groups: Vector3i):
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipelines[shader_name])
	
	var set_index: int = 0
	for uniform in uniforms:
		var uniform_set := UniformSetCacheRD.get_cache(shaders[shader_name], set_index, [ uniform ])
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, set_index)
		set_index += 1
	for push_constant in push_constants:
		rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, groups.x, groups.y, groups.z)
	rd.compute_list_end()
