extends KinematicBody2D
#此敌人模板仅供测试！

var Identifier="Enermy"
var Name:String                         #怪物名称，也代表种类
var Exist:bool=true
var TargetPosition:Vector2              #暂定，可能无此变量
var Target                              #锁定的目标，为玩家或NPC
var BirthPosition:Vector2               #出生位置，回溯模式下会回到此处
var Speed:float                         #即creature_status中的Speed[SpeedType]
var AImode:String                        
#AI模式，值为“default",“guarding",attacking","backtracking",分别对应默认、进攻、警惕和回溯模式
#默认模式下按一定轨迹移动，警惕模式下前往目标点，进攻模式下追踪目标，回溯模式下寻路回到出生点
var BattleMod:String                    #值为“common"或”defense"，对应正常战斗和防御战
var KnockBack:Vector3                   #被击退值，三维向量，xy表示方向，z表示剩余击退距离，每一帧击退距离呈二次函数
var Attackable:bool=true                #是否可以进行攻击
var AttackRange:float                   #攻击距离，单位为像素
var FaceDirection:Vector2               #面朝方向，决定视野范围
var SightRange:float                    #扇形视野的半径
var SightAngle:float                    #扇形视野的夹角，采用角度制
var GuardingPosition:Vector3            #警戒坐标，前往此坐标查看，z值为警戒指数
var Territory:Vector3                   #圆形领域，xy代表中心坐标，z代表半径

var DamageArea=preload("res://weapons/melee/damage_area/DamageArea.tscn")   
   
onready var CreatureStatus=$CreatureStatus


func init(_Name:String,_FaceDirection:Vector2):
    Name=_Name
    TargetPosition=global_position
    BirthPosition=global_position
    AImode="default"
    FaceDirection=_FaceDirection
    match Name:
        "test_enermy":
            CreatureStatus.init(100,100,0,[3,5,5],"Enermy",$CollisionShape2D.shape,[1,1,1,1]) 
            SightAngle=90
            SightRange=400
            $AttackColdTimer.wait_time=1
        _:
            print("Invalid enermy name \"",Name,"\"!")
            queue_free()   
        
func _physics_process(delta):
    if !Exist:
        return
    attack()
    if !CreatureStatus.alive():
        die()#死了，但不会立刻消失。动画会持续一小段时间
    Target=CreatureStatus.TargetEnermy
    if Target!=null:
        TargetPosition=Target.global_position    
    AIFunction()
    var movement=CreatureStatus.find_way(TargetPosition)
    Speed=CreatureStatus.Speed[CreatureStatus.SpeedType]
    move(movement)

func detect():
    if FaceDirection==Vector2(0,0):#这种情况说明初始化有问题，且会引发错误
        return
    var Tars=Global.PlayerAndNPCs#所有和自己敌对的生物集合，包括玩家和NPC
    var res=null#检测到的离自己最近敌对生物
    var TempMinimumDis=INF#当前检测到的生物的离自己最短距离
    FaceDirection=FaceDirection.normalized()
    for Tar in Tars:
        if CreatureStatus.AggroValue.get(Tar)==null and (Tar.global_position-global_position).length()>SightRange or abs(FaceDirection.angle_to(Tar.global_position-global_position))*180/PI>SightAngle/2:
            continue#若对此单位没有仇恨，且其不在扇形区域内，直接判断下一个
        #判断是否撞上障碍物
        var collision=Global.detect_collision_in_line(global_position,Tar.global_position,[self], 1)
        if !collision and TempMinimumDis>(Tar.global_position-global_position).length():
            res=Tar
            TempMinimumDis=(Tar.global_position-global_position).length()
            if CreatureStatus.AggroValue.get(Tar)==null:
                CreatureStatus.add_aggro(100,Tar)
        elif collision and CreatureStatus.AggroValue.get(Tar)!=null:
                CreatureStatus.dec_aggro(0.4,Tar)
    return res#结果为离自己最近的被检测到的敌人，若没有检测到则返回null
        
func move(movement:Vector2):#移动策略，同NPC的
    if movement!=Vector2(0,0):
        FaceDirection=movement.normalized()#移动方向决定面朝方向
    if (TargetPosition-global_position).length()<=Speed*0.5: 
        movement=Vector2()
    if KnockBack.z:
        var KnockBackDistance=sqrt(KnockBack.z)
        movement+=Vector2(KnockBack.x,KnockBack.y).normalized()*KnockBackDistance
        KnockBack.z-=KnockBackDistance
        if KnockBack.z<=1:
            KnockBack.z=0
    var OriginalPosition=global_position
    var collision=move_and_collide(movement)
    if collision:
        movement = movement.slide(collision.normal).normalized()*(Speed-(global_position-OriginalPosition).length())
        move_and_collide(movement)

func AIFunction():#AI切换以及不同AI的行动
    match AImode:
        "default":#默认模式
            var Tar=detect()
            if Tar!=null:
                Target=Tar
                AImode="attacking"#找到目标后进入攻击模式
            elif GuardingPosition.z>0:
                AImode="guarding"
                SightAngle*=1.5
                SightRange*=1.5
        "guarding":#警戒模式
            detect()
            TargetPosition=Vector2(GuardingPosition.x,GuardingPosition.y)
            if Target!=null:
                AImode="attacking"
                SightAngle/=1.5
                SightRange/=1.5
            if (TargetPosition-global_position).length()<=SightRange/3:
                var collision=Global.detect_collision_in_line(global_position,TargetPosition,[self],1)
                if collision:
                    return
                TargetPosition=global_position
                GuardingPosition.z-=2
            if GuardingPosition.z<=0:
                GuardingPosition.z=0
                AImode="backtracking"
                SightAngle/=1.5
                SightRange/=1.5
        "attacking":#冲突模式，追踪目标进行攻击
            detect()
            if Target==null and GuardingPosition.z<=0:
                AImode="backtracking"#失去目标，则进入回溯模式 
        "backtracking":#回溯模式，回到出生点
            if Target!=null:
                AImode="attacking"
                return
            elif GuardingPosition.z>0:
                AImode="guarding"    
                SightAngle*=1.5
                SightRange*=1.5
            TargetPosition=BirthPosition
            if (global_position-BirthPosition).length()<=Speed*0.5:
                TargetPosition=global_position
                AImode="default"
        _:
            print("WARNING!!! ",self," in an unknown AImode!")
            return

func attack():#攻击
    if !Attackable:
        return
    var NewDamageArea=DamageArea.instance()
    NewDamageArea.init("test_damage_area",$CreatureStatus.Attack,FaceDirection.normalized(),self,CreatureStatus.Camp,0)
    self.add_child(NewDamageArea)
    Attackable=false
    $AttackColdTimer.start()

func _on_AttackColdTimer_timeout():
    Attackable=true

func raise_guard(pos:Vector2,value:float):
    if GuardingPosition.z<value and (global_position-pos).length()<=value:
        GuardingPosition=Vector3(pos.x,pos.y,value)


func die():
    $DisappearTimer.start()
    Exist=false
    $CollisionShape2D.queue_free()

func _on_DisappearTimer_timeout():
    queue_free()
