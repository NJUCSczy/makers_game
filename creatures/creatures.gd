extends KinematicBody2D

var Identifier="Creature"
var Health:float            #当前生命值
var MaxHealth:float         #生命上限
var Attack:float          
var Speed=[0,0,0]           #速度数组，记录不同情况下的速度，最多三种
var SpeedType:int=0         #值为0/1/2，代表当前速度为哪一种
var Camp:String             #阵营
var AggroValue:Dictionary   #记录仇恨值的字典，key为仇恨对象实例，value为仇恨值
var TargetEnermy=null       #仇恨最大的对象，若没有则为null 
var Ability={"melee_damage":1 , "ranged_damage":1 , "melee_defense":1 , "ranged_defense":1 , "knockback_defense":1}
#近战伤害、远程伤害、近战抗性、远程抗性倍率、击退抗性，默认为1
var navigation:Navigation2D #由Gloabl传入此参数，为当前地图的导航

func init(_Health:float,_MaxHealth:float,_Attack:float,_Speed:Array,_Camp:String,_CollisionShape,_Ablity:Array):#并非是默认的_init()函数！是自己写的一个设置各种参数的函数。。。
    Health=_Health
    MaxHealth=_MaxHealth
    Attack=_Attack
    Speed=_Speed
    Camp=_Camp
    $CollisionShape2D.shape=_CollisionShape
    Ability["melee_damage"]=_Ablity[0]
    Ability["ranged_damage"]=_Ablity[1]
    Ability["melee_defense"]=_Ablity[2]
    Ability["ranged_defense"]=_Ablity[3]

func set_navigation(_navigation):
    navigation=_navigation

func alive():
    return Health>0

func get_hurt(DMG:float,DMG_kind:String,src:Object):#此处的src为攻击的对象实例
    var hurt
    if DMG_kind=="melee_damage":
        hurt=DMG/Ability["melee_defense"]
    elif DMG_kind=="ranged_damage":
        hurt=DMG/Ability["ranged_defense"]
    Health-=hurt
    if Health<0:
        Health=0
        return
    add_aggro(hurt*10,src)#受到伤害会增加自身对于攻击者的仇恨

func add_aggro(value:int,src:Object):#增加仇恨值
    if src in AggroValue.keys():
        AggroValue[src]=log(exp(AggroValue[src])+value)
    else:
        AggroValue[src]=log(value)
    if TargetEnermy==null or AggroValue[src]>=AggroValue[TargetEnermy]:
        TargetEnermy=src

func dec_aggro(num:float,src:Object):#降低仇恨值
    if AggroValue.get(src)==null:
        return
    AggroValue[src]-=num
    if AggroValue[src]<=0:
        AggroValue.erase(src)
        if src==TargetEnermy:
            TargetEnermy=null

func find_way(target:Vector2):#寻路算法，并且在拐弯处修正移动，以防卡死
    if navigation==null:
        return Vector2()
#注意，碰撞遮罩中，layer1为障碍物，也是creature作为底层对象在实现寻路时考虑的
    var _Speed=Speed[SpeedType]
    var TargetPath=navigation.get_simple_path(global_position,target)
    if TargetPath.size()<=1:
        return Vector2(0,0)
    var TargetDirection=(TargetPath[1]-TargetPath[0]).normalized()
    var movement=_Speed*(TargetDirection.normalized())#首先根据速度和目标移动方向计算移动向量
    var original_position=position#因为移动并碰撞来进行检测后，需要回到原位，所以需要记录移动前的位置
    var collision=move_and_collide(movement)
    if collision:#如果碰撞到障碍物
         #############################################
        #这一段copy以前写的，固没有采用帕斯卡命名法，请见谅！#
       ############################################
        var collision_dir=movement-movement.slide(collision.normal)#计算出碰撞的位置，即来源的方向（上下左右）
        position=original_position
        var cornor_pos=$CollisionShape2D.shape.extents#记下自身碰撞矩形的长宽
        #从碰撞矩形的四个角分别发射与运动向量相同的射线，并进行碰撞检测
        var collision_top_left=Global.detect_collision_in_line(global_position-cornor_pos,global_position-cornor_pos+movement,[self], collision_mask)
        var collision_top_right=Global.detect_collision_in_line(global_position+Vector2(cornor_pos.x,-cornor_pos.y),global_position+Vector2(cornor_pos.x,-cornor_pos.y)+movement,[self], collision_mask)
        var collision_left_bottom=Global.detect_collision_in_line(global_position+Vector2(-cornor_pos.x,cornor_pos.y),global_position+Vector2(-cornor_pos.x,cornor_pos.y)+movement,[self], collision_mask)
        var collision_right_bottom=Global.detect_collision_in_line(global_position+cornor_pos,global_position+cornor_pos+movement,[self], collision_mask)
        #根据碰撞体形状（矩形）来确定修正角度
        var FixAngle=atan2($CollisionShape2D.shape.extents.y,$CollisionShape2D.shape.extents.x)
        if collision_dir.x>0 :#根据碰撞结果以及运动方向进行移动修正
            if collision_right_bottom && !collision_top_right && movement.angle()>=0 && movement.angle()<=FixAngle :
                movement=Vector2(0,-_Speed)
            elif !collision_right_bottom && collision_top_right && movement.angle()<=0 && movement.angle()>=-FixAngle :
                movement=Vector2(0,_Speed)
        elif collision_dir.x<0 :
            if collision_left_bottom && !collision_top_left && movement.angle()>=PI-FixAngle && movement.angle()<=PI:
                movement=Vector2(0,-_Speed)
            elif !collision_left_bottom && collision_top_left && movement.angle()>=-PI && movement.angle()<=FixAngle-PI:
                movement=Vector2(0,_Speed)
        elif collision_dir.y>0 :
            if collision_left_bottom && !collision_right_bottom && movement.angle()>=PI/2 && movement.angle()<=PI/2+FixAngle:
                movement=Vector2(_Speed,0)
            elif !collision_left_bottom && collision_right_bottom && movement.angle()<=PI/2 && movement.angle()>=FixAngle:
                movement=Vector2(-_Speed,0)
        elif collision_dir.y<0 :
            if collision_top_left && !collision_top_right && movement.angle()<=-PI/2 && movement.angle()>=FixAngle-PI :
                movement=Vector2(_Speed,0)
            elif !collision_top_left && collision_top_right && movement.angle()<=-FixAngle && movement.angle()>=-PI/2:
                movement=Vector2(-_Speed,0)
    else:
        position=original_position
    return movement


