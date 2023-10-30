extends CharacterBody3D


@onready var camFpc := $%FPC
@onready var camTpc := $%TPC

const WALK_SPEED := 3.0
const RUN_SPEED := 5.0
const CROUCH_SPEED := 1.0
const ACC = .08
const FRIC = .1
const JUMP_VELOCITY = 4.5
const RUN_SPEED_ACC := .25
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var airControl = .2
var SPEED = 0


@onready var camera = $Systems/Camera
@onready var camFp := $Systems/Camera/FirstPersonCamera
@onready var arm := $Systems/Camera/SpringArm3D
@onready var checkFloor := $Systems/CheckFloor
@onready var mesh := $Mesh
@onready var anim := $Mesh/MeshPlayer
@onready var headBone = $Mesh/HeadBone
@onready var animTree := $AnimationTree
@onready var StandCol := $StandCollision
@onready var CrouchCol := $CrouchCollision
#@onready var headBone := $Mesh/Charater/Armature/Skeleton3D/HeadBone
#@onready var skeleton := $Mesh/Charater/Armature/Skeleton3D
#@onready var anim := $MainCharacter/AnimationPlayer
@onready var input = $PlayerInput

@export var player := 1 :
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.
		$PlayerInput.set_multiplayer_authority(id)

func _ready():
	animTree.active = true
	
	set_physics_process(multiplayer.is_server())
	
func _process(delta):
	
	animTree.set("parameters/CrouchStand/transition_request", ["crouch_to_stand","stand_to_crouch"][int(input.crouch)])
	input.is_on_floor = is_on_floor()
	if not is_on_floor():
		velocity.y -= gravity * delta
	if input.jumping:
		velocity.y = JUMP_VELOCITY
		input.jumping = false

	if player == multiplayer.get_unique_id():
		if input.cameraType == 1:
			camTpc.current = 1
		if input.cameraType == 0:
			camFpc.current = 1

	animTree.set("parameters/MainState/conditions/onAir", !is_on_floor())
	animTree.set("parameters/MainState/conditions/onFloor", is_on_floor() or checkFloor.is_colliding())
	
	if input.crouch:
		SPEED = lerpf(SPEED, CROUCH_SPEED, RUN_SPEED_ACC)
	elif input.running:
		SPEED = lerpf(SPEED, RUN_SPEED, RUN_SPEED_ACC)
	else:
		SPEED = lerpf(SPEED, WALK_SPEED, RUN_SPEED_ACC)

	var input_dir = (transform.basis * Vector3(input.input_dir.x, 0, input.input_dir.z)).normalized()
	if input.cameraType == 0:
		if input.input_dir.length() > 0:
			input_dir = input_dir.rotated(Vector3.UP, arm.rotation.y).normalized()
			if (player == multiplayer.get_unique_id()):
				var _mrot = Vector2(input_dir.z, input_dir.x).angle()
				input.direction = input_dir
				mesh.rotation.y = lerp_angle(mesh.rotation.y, _mrot, .2)
				input.direction.y = _mrot
			else: 
				mesh.rotation.y = input.direction.y
				input_dir = input.direction
	else:
		input_dir = input_dir.rotated(Vector3.UP, camFp.rotation.y - PI).normalized()
		if (player == multiplayer.get_unique_id()):
			input.direction = input_dir
			mesh.rotation.y = lerp_angle(mesh.rotation.y, camFp.rotation.y, .2)
			input.direction.y = camFp.rotation.y
		else: 
			mesh.rotation.y = input.direction.y
			input_dir = input.direction
		
		
	var __control = 1.0 if is_on_floor() else airControl
	var __interpolate = ACC if input.input_dir.length() > 0 else FRIC
	velocity.x = lerp(velocity.x, input_dir.x * SPEED, __interpolate * __control) 
	velocity.z = lerp(velocity.z, input_dir.z * SPEED, __interpolate * __control) 
	var moveLength = (transform.basis * Vector3(velocity.x, 0, velocity.z))
	animTree.set("parameters/MainState/WalkRun/blend_position", (moveLength).length())
	animTree.set("parameters/CrouchIdleWalk/blend_position", (moveLength).length())
	move_and_slide()

