extends Area2D

var identifier="DamageArea"
var Name:String                 #用于辨别攻击种类，名字可能没什么实际意义
var Attack:float   
var Direction:Vector2 
var Camp:String="Player"        #发起攻击的阵营，和发射者一致，决定会对谁造成伤害
var KnockBack:float             #对目标造成的击退力
var DamageList:Dictionary={}    #造成伤害的目标列表，防止二次伤害
var Owner:Object                #发起这次攻击的对象实例


func init(_Name:String,_Attack:float,_Direction:Vector2,_Owner:Object,_Camp:String,_KnockBack:float):
    Name=_Name
    Attack=_Attack
    Direction=_Direction
    Camp=_Camp
    KnockBack=_KnockBack
    Owner=_Owner
    match(Name):
        "test_damage_area":
            $DestroyTimer.wait_time=0.5
        _:
            print("Invalid damage area name \"",Name,"\"!")
            queue_free()    
    visible=false

func _physics_process(delta):
    visible=true#避免第一帧方向错误采取的操作，可以改进
    rotation_degrees=Direction.angle()*180/PI
    global_position=Vector2(Owner.global_position.x+45*cos(Direction.angle()),Owner.global_position.y+45*sin(Direction.angle()))

func _on_DamageArea_body_shape_entered(body_id, body, body_shape, local_shape):
    #当有实例进入伤害范围时触发此函数
    var collision=Global.detect_collision_in_line(global_position,body.global_position,[self], 1)
    #此处探测射线的最后一个参数为1，代表碰撞mask为0x00001，即只检测layer1的碰撞，也就是障碍物
    if collision:
        return
    elif body.CreatureStatus.Camp=="Player" and Camp=="Enermy":
        if DamageList.get(body)==null:
            hit_target(body)        
    elif body.CreatureStatus.Camp=="Enermy" and Camp=="Player":
        if DamageList.get(body)==null:
            hit_target(body)

func hit_target(target):#命中目标，并造成相应的击退
    if target!=null:
        target.CreatureStatus.get_hurt(Attack,"melee_damage",Owner)
        DamageList[target]=false
        var tempKnockback=Vector2(target.KnockBack.x,target.KnockBack.y)*target.KnockBack.z+Direction*KnockBack
        target.KnockBack.z=tempKnockback.length()
        target.KnockBack.x=tempKnockback.normalized().x
        target.KnockBack.y=tempKnockback.normalized().y

func _on_DestroyTimer_timeout():#摧毁自身
    queue_free()
