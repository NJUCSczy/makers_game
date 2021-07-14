extends KinematicBody2D

var Identifier="NPC"
var Name:String                     #NPC名字，之后应在Global中有相应的查找表，以及避免某些名字
var Speed:float                     #即creature_status中的Speed[SpeedType]
var Target:Object                   #追踪中的目标
var DistanceToTarget:float          #自身到目标的距离
var EnermyInArea=[]                 #检测范围内的敌人
var TargetPosition:Vector2          #目标坐标
var WeightLimit                     #NPC的最大负重值
var AImode:String                   #NPC的AI模式，“home"，"defenive"，"following","fighting"，"healing"
#分别为家园模式、防御模式、跟随模式（未爆发冲突）、冲突模式、撤退模式
var TracingPlayer:bool              #是否处于离玩家过远、正在追踪玩家的状态
var FightMod:String                 #战斗策略，分为"ranged"，"melee",即远程和近战
var Task=null                       #在家园中分配的任务，待定，null代表无任务
var KnockBack:Vector3               #被击退值，三维向量，xy表示方向，z表示剩余击退距离，每一帧击退距离呈二次函数
var FollowDistance:Vector2          #跟随模式和撤退模式下，x代表离玩家超过此距离开始追逐，y代表离玩家小于此距离停止追逐
var FightingFollowDistance:Vector2  #冲突模式下跟随玩家的距离
var DistanceToPlayer:float=0        #距离玩家的距离，动态更新

onready var CreatureStatus=$creature_status
onready var Player=Global.CurrentScene.get_node("Player") 
onready var RangedWeapon=$RangedWeapon
onready var MeleeWeapon=$MeleeWeapon      

func init(_Name:String,_AImode:String):
    #应对根据名称在NPC列表中查询，并获取NPC以及装备的武器相关信息，之后实现
    Name=_Name
    AImode=_AImode
    match Name:
        "test_NPC":
            CreatureStatus.init(100,100,0,[5,5,5],"Player",$CollisionShape2D.shape,[1,1,1,1])
            RangedWeapon.init("test_ranged_weapon",self,CreatureStatus.Ability["ranged_damage"],1,1)
            RangedWeapon.set_bullet_num(2000)
            MeleeWeapon.init("test_melee_weapon",self,CreatureStatus.Ability["melee_damage"],1)
            FollowDistance=Vector2(200,100)
            FightingFollowDistance=Vector2(400,300)
        _:
            print("Invalid NPC name \"",Name,"\"!")
            queue_free()      
     
func _physics_process(delta):
    Speed=CreatureStatus.Speed[CreatureStatus.SpeedType]
    calc_distance_to_player_and_target()
    update_enermy_in_area()
    AIFunction()
    var movement=CreatureStatus.find_way(TargetPosition)
    move(movement)
    
func move(movement):#移动策略
    if (TargetPosition-global_position).length()<=Speed*0.5:#离目标位置足够近，不需要继续移动
        movement=Vector2()
    if KnockBack.z:#如果自身被击退，需要往击退方向移动（向量加）
        var KnockBackDistance=sqrt(KnockBack.z)#每一帧击退距离平方递减！
        movement+=Vector2(KnockBack.x,KnockBack.y).normalized()*KnockBackDistance
        KnockBack.z-=KnockBackDistance
        if KnockBack.z<=1:
            KnockBack.z=0
    var OriginalPosition=global_position
    var collision=move_and_collide(movement)
    if collision:
        movement = movement.slide(collision.normal).normalized()*(Speed-(global_position-OriginalPosition).length())
        move_and_collide(movement)

func calc_distance_to_player_and_target():#计算自身到玩家和到目标敌人的距离
    if CreatureStatus.navigation==null:
        return
    var TargetPath=CreatureStatus.navigation.get_simple_path(global_position,Player.global_position)
    DistanceToPlayer=0
    for i in range(TargetPath.size()-1):
        DistanceToPlayer+=(TargetPath[i+1]-TargetPath[i]).length()
    if Target==null or !Target.has_meta("Identifier"):
        DistanceToTarget=INF
    else:
        TargetPath=CreatureStatus.navigation.get_simple_path(global_position,Target.global_position)
    return

func AIFunction():#进行AI间的切换，以及执行不同的AI操作
    match AImode:
        "home":return#家园模式，待定
        "defensive":return#家园防御模式，待定
        "following":#未冲突状态
            if Target!=null:
                AImode="fighting"
            #根据自身距离玩家距离，决定是否要跟上玩家    
            if DistanceToPlayer>FollowDistance.x:
                TracingPlayer=true
            elif DistanceToPlayer<=FollowDistance.y:
                TracingPlayer=false
                
        "fighting":#冲突模式，进行战斗
            if Target==null:#失去目标则回到未冲突模式
                AImode="following"
                return
            var collision=Global.detect_collision_in_line(global_position,Target.global_position,[self], 1)
            if collision:#如果与目标之间有障碍物，则追踪目标
                TargetPosition=Target.global_position
            else:#如果无障碍物，则原地不动（在没有其他移动需求的情况下）
                TargetPosition=global_position  
            #如果远程武器可用    
            if RangedWeapon.AllBulletNum>0 or RangedWeapon.Bullet>0:
                if RangedWeapon.BulletNum<=0:#子弹不够自动换弹
                    RangedWeapon.reload()
                elif RangedWeapon.Attackable:#可攻击则自动攻击
                    #计算射击角度（考虑敌人移动的情况下）
                    var AimPosition=Target.global_position+calc_aim_position(global_position-Target.global_position,Target.FaceDirection,$RangedWeapon.BulletSpeed/Target.Speed)
                    collision=Global.detect_collision_in_line(global_position,AimPosition,[self], 1)
                    #如果不会碰到障碍物，则射击
                    if !collision and (AimPosition-global_position).length()<=RangedWeapon.MaxRange:
                        RangedWeapon.Direction=(AimPosition-global_position).normalized()
                        RangedWeapon.shoot()
            #如果敌人在近战武器范围内，则用近战武器攻击（不需要花时间切换）
            MeleeWeapon.Direction=(Target.global_position-global_position).normalized()
            if DistanceToTarget<=MeleeWeapon.MaxRange:
                MeleeWeapon.attack()
            #如果敌人与自身距离小于远程武器射程的一半（暂定），则试图远离敌人
            if DistanceToTarget<=RangedWeapon.MaxRange/2:
                #远离的方向即向后退
                var TempTargetPosition=(-Target.global_position+global_position).normalized()*Speed+global_position
                #但如果这样会离玩家过远，则向敌人————玩家的射线与跟随玩家距离圆形区域的交点处移动
                if (TempTargetPosition-Player.global_position).length()>FightingFollowDistance.x:
                    TempTargetPosition=(Player.global_position-Target.global_position).normalized()*(FightingFollowDistance.x-Speed)+Player.global_position
                TargetPosition=TempTargetPosition
            #如果自身离玩家过远或者足够近，修正移动方向，靠近玩家或者停止靠近
            if DistanceToPlayer>FightingFollowDistance.x:
                TracingPlayer=true
            elif DistanceToPlayer<=FightingFollowDistance.y:
                TracingPlayer=false
            
            if false:#在完善背包相关物品后修改，此处应为：自身当前hp+装备的药品恢复的hp<=满hp，且有剩余药瓶、可以使用，且目标敌人离自己不近
                AImode="healing"
        "healing":
            if false:#此处应为当前HP+药品恢复亮>满血，或没有药品了
                return
            if Target!=null and DistanceToTarget<RangedWeapon.MaxRange/2:
                return
            if $HealTimer.wait_time==0:
                $HealTimer.start()
    if TracingPlayer:#根据修正情况，靠近或停止靠近玩家
        TargetPosition=Player.global_position
    elif TargetPosition==Player.global_position:
        TargetPosition=global_position

func _on_EnermyDetectionArea_body_shape_entered(body_id, body, body_shape, local_shape):
    #当有敌人进入自身感应范围时
    if body in EnermyInArea or body.Identifier!="Enermy":
        return
    EnermyInArea.push_back(body)

func update_enermy_in_area():
    #更新自身感应范围内的敌人
    if Target!=null and !Target.Exist:
        Target=null
    var i=0
    while i< EnermyInArea.size():
        #遍历敌人，更新目标敌人
        if EnermyInArea[i]==null or !EnermyInArea[i].Exist:
            EnermyInArea.remove(i)
            i-=1
        elif EnermyInArea[i].Exist and EnermyInArea[i].AImode=="attacking":
            if DistanceToTarget*0.8<=(EnermyInArea[i].global_position-global_position).length():
                i+=1
                continue
            var collision=Global.detect_collision_in_line(global_position,EnermyInArea[i].global_position,[self], 1)
            if !collision:
                Target=EnermyInArea[i]
                DistanceToTarget=(EnermyInArea[i].global_position-global_position).length()
        i+=1

func calc_aim_position(v1:Vector2,v2:Vector2,k:float):
#用于计算瞄准敌人的方向（敌人是会动的！），参数v1代表敌人到自身的向量，v2代表敌人的移动方向，k代表子弹速度/敌人速度
#当前计算思路见res://log/子弹瞄准策略.gif
#当敌人切换移动方向时，可能会打歪
    var m=v1.x
    var n=v1.y
    var x1=v2.x
    var y1=v2.y
    var a=(k*k-1)*(x1*x1+y1*y1)
    var b=(2*m*x1+2*n*y1)
    var c=-(m*m+n*n)
    var res=(-b+sqrt(b*b-4*a*c))/(2*a)
    return v2.normalized()*res

func heal_finish():
    #加血，消耗药物
    pass # Replace with function body.
