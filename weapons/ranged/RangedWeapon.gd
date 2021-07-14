extends Node2D

var Identifier="RangedWeapon"
var Name:String
var Enable:bool=false           #是否处于战斗状态
var Attackable:bool=true        #是否可以发射子弹，要考虑到发射冷却和换弹
var Direction:Vector2           #武器对准的方向，也决定子弹和动画的方向
var Attack:float                #攻击力
var AutoAttack:bool             #是否可以连射
var Shooting:bool=false         #是否按住攻击键，连射的武器在按住时持续攻击
var AllBulletNum:int            #剩余背包中子弹数量（未装填的）
var MagazineCapacity:int        #弹夹容量
var BulletNum:int               #弹夹剩余子弹数量
var RandomAngle:float           #子弹偏转角
var MaxRange:float              #最大射程
var BulletSpeed:float           #子弹飞行速度，供AI计算射击方向
var KnockBack:float             #击退能力，单位为像素
var GuardingValue:float         #攻击造成的警戒值
var Owner                       #武器的使用者
var BulletType:String           #子弹型号

var Bullet=preload("res://weapons/ranged/bullet/bullet.tscn")

signal bullet_consume

func init(_Name:String,_Owner,_AttackAbility:float,_ReloadAbility:float,_KnockBackAbility:float):
    Name=_Name
    Owner=_Owner
    Enable=true
    match(Name):
        "test_ranged_weapon":
            Attack=1
            AutoAttack=true
            BulletType="test_bullet"
            MagazineCapacity=50
            BulletNum=MagazineCapacity              #暂定
            $ColdTimer.wait_time=0.2
            $ReloadTimer.wait_time=3
            RandomAngle=2
            MaxRange=500
            KnockBack=10
            BulletSpeed=15
            GuardingValue=1200
        _:
            print("Invalid ranged weapon name \"",Name,"\"!")
            queue_free()    
    Attack*=_AttackAbility
    $ReloadTimer.wait_time*=_ReloadAbility
    KnockBack*=_KnockBackAbility
    
func _physics_process(delta):
    if AutoAttack and Shooting:
        shoot()

func shoot():#（试图）开枪
    if !Enable or !Attackable:
        return
    get_tree().call_group("enermy","raise_guard",global_position,GuardingValue)
    var NewBullet=Bullet.instance()
    Global.CurrentScene.add_child(NewBullet)
    var TempAngle=(randf()-0.5)*RandomAngle*PI/180
    var RandomDirection=Vector2(Direction.x*cos(TempAngle)+Direction.y*sin(TempAngle),-Direction.x*sin(TempAngle)+Direction.y*cos(TempAngle))
    NewBullet.init("test_bullet",global_position,Attack,RandomDirection,MaxRange,Owner,KnockBack)
    $ColdTimer.start()
    BulletNum-=1
    Attackable=false

func reload():#重新装弹
    if AllBulletNum<=0 or $ReloadTimer.time_left:
        return
    $ReloadTimer.start()

func set_bullet_num(_AllBulletNum:int):#初始化此武器需要的子弹的背包数量，中途增加的话也通过此函数更改
    AllBulletNum=_AllBulletNum

func _on_ColdTimer_timeout():
    if BulletNum>0:
        Attackable=true

func _on_ReloadTimer_timeout():#重新装弹完成
    if AllBulletNum>=MagazineCapacity:
        AllBulletNum-=MagazineCapacity
        BulletNum=MagazineCapacity
    else:
        BulletNum=AllBulletNum
        AllBulletNum=0
    emit_signal("bullet_consume",BulletNum)
    if $ColdTimer.time_left==0:
        Attackable=true
