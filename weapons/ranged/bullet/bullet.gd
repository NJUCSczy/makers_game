extends Area2D

var identifier="Bullet"
var Name:String                     #用于辨别子弹种类
var Exist:bool=false                #子弹是否仍然有效，用于防止子弹在一帧内多次判定
var Attack:float     
var Speed:float
var Direction:Vector2
var Owner                           #发射这颗子弹的对象实例
var Camp:String="Player"            #这颗子弹的阵营，和发射者一致，决定会对谁造成伤害
var MaxRange:float                  #子弹的最大射程
var KnockBack:float                 #击退力
var TempDistance:float=0            #子弹当前已经飞行的距离

func init(_Name,_Position,_Attack,_Direction,_MaxRange,_Owner,_KnockBack):
    Name=_Name
    global_position=_Position
    Attack=_Attack
    Direction=_Direction
    rotation_degrees=Direction.angle()*180/PI
    MaxRange=_MaxRange
    Owner=_Owner
    Camp=Owner.CreatureStatus.Camp
    KnockBack=_KnockBack
    Exist=true
    match(Name):
        "test_bullet":
            Speed=15#别看现在只有一个speed，还要考虑动画和碰撞呢
        _:
            print("Invalid bullet name \"",Name,"\"!")
            queue_free() 
            
            
func _physics_process(delta):
    move_and_detect()

func move_and_detect():
    if !Exist:#子弹命中之后不会马上消失，但是造成伤害之后无法再次进行判定
        return
    var collision
    if Camp=="Player":
        collision=Global.detect_collision_in_line(global_position,global_position+Direction.normalized()*Speed,[self], 0b101)
    elif Camp=="Enermy":
        collision=Global.detect_collision_in_line(global_position,global_position+Direction.normalized()*Speed,[self], 0b11)
    if !collision:#向飞行方向发射探测射线，没有碰撞，直接往前飞
        global_position+=Direction.normalized()*Speed
        TempDistance+=Speed
        if TempDistance>MaxRange:
            Exist=false
            queue_free()
        return
    if collision.collider.Identifier=="Obstacle":#撞到障碍物，则销毁自身
        Exist=false
        global_position=collision.position
        hit_target(null)
    #撞到敌对阵营实例，造成伤害并摧毁自身
    elif collision.collider.CreatureStatus.Camp=="Enermy" and Camp=="Player":#自身属于敌人阵营并命中玩家，则伤害玩家
        Exist=false
        global_position=collision.position
        hit_target(collision.collider)
    elif collision.collider.CreatureStatus.Camp=="Player" and Camp=="Enermy":#自身属于玩家阵营并命中玩家，则伤害玩家
        Exist=false
        global_position=collision.position
        hit_target(collision.collider)
    else:
        global_position+=Direction.normalized()*Speed
        TempDistance+=Speed
        if TempDistance>MaxRange:
            Exist=false
            queue_free()

func hit_target(target):#对于命中的对象，造成伤害和击退
    if target!=null:
        target.CreatureStatus.get_hurt(Attack,"ranged_damage",Owner)
        var tempKnockback=Vector2(target.KnockBack.x,target.KnockBack.y)*target.KnockBack.z+Direction*KnockBack
        target.KnockBack.z=tempKnockback.length()
        target.KnockBack.x=tempKnockback.normalized().x
        target.KnockBack.y=tempKnockback.normalized().y
    $HitAnimationTimer.start()

func _on_HitAnimationTimer_timeout():
    queue_free()
