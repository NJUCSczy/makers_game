extends KinematicBody2D

var Identifier="Player"
var Speed:float                             #即creature_status中的Speed[SpeedType]
var KeyboardPressState:Array=[0,0,0,0]      #运动方向按键情况
var PlayerMoveState:Vector2=Vector2()       #当前运动向量
var Weight                                  #当前负重值,在背包物品变化时要重新计算
var WeightLimit                             #主角的最大负重值
var KnockBack:Vector3                       #被击退值，三维向量，xy表示方向，z表示剩余击退距离，每一帧击退距离呈二次函数
var WeaponChoice:String                     #"ranged"或"melee"，代表当前选中远程或近战武器

onready var CreatureStatus=$creature_status
onready var RangedWeapon=$RangedWeapon
onready var MeleeWeapon=$MeleeWeapon

func _ready():#暂时留着，之后会被init取代
    CreatureStatus.init(0,0,0,[5,5,5],"Player",$CollisionShape2D.shape,[1,1,1,1])
    RangedWeapon.init("test_ranged_weapon",self,CreatureStatus.Ability["ranged_damage"],1,1)
    RangedWeapon.set_bullet_num(200)
    MeleeWeapon.init("test_melee_weapon",self,CreatureStatus.Ability["melee_damage"],1)
    WeaponChoice="melee"
    $ChangeWeaponTimer.wait_time=0.5

func init():
    CreatureStatus.init(0,0,0,[5,5,5],"Player",$CollisionShape2D.shape,[1,1,1,1])
    RangedWeapon.init("test_ranged_weapon",self,CreatureStatus.Ability["ranged_damage"],1,1)
    RangedWeapon.set_bullet_num(200)
    MeleeWeapon.init("test_melee_weapon",self,CreatureStatus.Ability["melee_damage"],1,1)
    WeaponChoice="melee"
    $ChangeWeaponTimer.wait_time=0.5

func _physics_process(delta):
    Global.PlayerCamera.set_camera(global_position)
    Speed=CreatureStatus.Speed[CreatureStatus.SpeedType]
    direction_action()
    move()

func _input(event):
    if Global.GameStatus!="PlayerControl":
        return
    if event is InputEventMouseMotion:
        RangedWeapon.Direction=(event.global_position+Global.PlayerCamera.global_position-Vector2(640,360)-global_position).normalized()
        MeleeWeapon.Direction=(event.global_position+Global.PlayerCamera.global_position-Vector2(640,360)-global_position).normalized()
    elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
        #按下鼠标左键，使用当前武器攻击
        if WeaponChoice=="ranged":
            RangedWeapon.Shooting=true
            RangedWeapon.shoot()
        elif WeaponChoice=="melee":
            MeleeWeapon.attack()
    elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed:
        #放开鼠标左键，如果装备远程武器且需要换弹，则重新装弹
        if WeaponChoice=="ranged":
            RangedWeapon.Shooting=false
            if RangedWeapon.AllBulletNum>0 and RangedWeapon.BulletNum<=0:
                RangedWeapon.Attackable=false
                RangedWeapon.reload()
    elif event.is_action("ui_focus_next"):
        #鼠标滚轮下滚，切换近战/远程武器。如果远程武器没有弹药，则重新装弹
        if $ChangeWeaponTimer.time_left:
            return
        if RangedWeapon.BulletNum<=0:
            RangedWeapon.reload()
        if WeaponChoice=="ranged":
            WeaponChoice="melee"
        elif WeaponChoice=="melee":
            WeaponChoice="ranged"
        $ChangeWeaponTimer.start()
    
func direction_action():
    #根据按键情况，决定移动方向
    if Input.is_action_pressed("ui_up")&&!KeyboardPressState[0]:
        KeyboardPressState[0]=1
        PlayerMoveState.y=-1
    elif !Input.is_action_pressed("ui_up")&&KeyboardPressState[0]:
        KeyboardPressState[0]=0
        if KeyboardPressState[1]:
            PlayerMoveState.y=1
        else:
            PlayerMoveState.y=0
    if Input.is_action_pressed("ui_down")&&!KeyboardPressState[1]:
        KeyboardPressState[1]=1
        PlayerMoveState.y=1
    elif !Input.is_action_pressed("ui_down")&&KeyboardPressState[1]:
        KeyboardPressState[1]=0
        if KeyboardPressState[0]:
            PlayerMoveState.y=-1
        else:
            PlayerMoveState.y=0
    if Input.is_action_pressed("ui_left")&&!KeyboardPressState[2]:
        KeyboardPressState[2]=1
        PlayerMoveState.x=-1
    elif !Input.is_action_pressed("ui_left")&&KeyboardPressState[2]:
        KeyboardPressState[2]=0
        if KeyboardPressState[3]:
            PlayerMoveState.x=1
        else:
            PlayerMoveState.x=0
    if Input.is_action_pressed("ui_right")&&!KeyboardPressState[3]:
        KeyboardPressState[3]=1
        PlayerMoveState.x=1
    elif !Input.is_action_pressed("ui_right")&&KeyboardPressState[3]:
        KeyboardPressState[3]=0
        if KeyboardPressState[2]:
            PlayerMoveState.x=-1
        else:
            PlayerMoveState.x=0
                
func move():
    var movement=(PlayerMoveState.normalized())*Speed       #算出移动距离
    var OriginalPosition=global_position                    #记下移动前位置
    var collision = move_and_collide(movement)              #检测是否碰撞，并且沿碰撞方向滑动
    if collision:                                           #如果碰撞，沿着滑动方向运动直到达到一帧运动距离
            movement = movement.slide(collision.normal).normalized()*(Speed-(global_position-OriginalPosition).length())
            move_and_collide(movement)

func _on_RangedWeapon_bullet_consume(num):
    pass #远程武器使用的子弹被消耗，进行扣减，在有实际的子弹物品之后编辑
