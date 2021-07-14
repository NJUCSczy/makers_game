extends Node2D
#这是一个全局的实例，也是单例。它以及他的子节点进行一系列全局控制工作。
#全局任意代码段可以通过Global来访问此实例，调用全局函数。
var Root                                #场景根节点
var CurrentScene                        #当前场景，很明显只会存在一个（全局场景之外的）
var PlayerAndNPCs=[]                    #当前场景中的玩家和NPC对象
var GameStatus:String                   #游戏状态
#不同状态对应的情况：（暂定）
#“MainMenu"：在主菜单界面
#“PlayerControl”：玩家控制中，可以自由移动
#“AnimationPlaying"：动画播放中，游戏暂停
#"Paused"：玩家暂停游戏
var GoodInHome = {}                     #家中的物品
var GoodInBackpack = {}                 #背包中的物品

onready var PlayerCamera=$PlayerCamera  #游戏镜头对象实例
onready var SceneChanger=$PlayerCamera/SceneChanger

func _ready():#游戏最开始会执行一次，之后就不会了
    Root=get_tree().get_root()
    CurrentScene=Root.get_child(Root.get_child_count() - 1)
    GameStatus="PlayerControl"
    $PlayerCamera.current=true
    set_scnene_info()

func _input(event):
    if event.is_action_pressed("ui_pause"):
        if GameStatus=="Paused":
            get_tree().paused=false
            GameStatus="PlayerControl"
            $PauseWindow.hide()
        elif GameStatus=="PlayerControl":
            GameStatus="Paused"
            get_tree().paused=true
            $PauseWindow.show()

func set_scnene_info():#在进入新场景的时候，记录场景中的所有玩家和NPC，供敌人查看
    PlayerAndNPCs=[]
    PlayerAndNPCs.push_back(CurrentScene.get_node("Player"))
    PlayerAndNPCs+=CurrentScene.get_node("NPCs").get_children()

func set_navigation():#给所有生物初始化navigation，用于导航
    get_tree().call_group("creature","set_navigation",CurrentScene.navigation)

func detect_collision_in_line(Pos1:Vector2,Pos2:Vector2,Ignore:Array,CollisionMask:int):
    #将探测射线功能封装，便于调用，参数Ignore为碰撞检测中忽略的对象数组
    var space_state = get_world_2d().direct_space_state#获取2D空间，准备发射碰撞检测射线
    var collision=space_state.intersect_ray(Pos1,Pos2,Ignore, CollisionMask)
    return collision

func change_scene(path):#切换场景
    SceneChanger.get_node("ColorRect").show()
    SceneChanger.get_node("AnimationPlayer").play("scenechange")
    yield(SceneChanger.get_node("AnimationPlayer"), "animation_finished")
    CurrentScene.queue_free()
    var NextScene=load(path).instance()
    CurrentScene=NextScene
    if CurrentScene.Identifier=="BattleScene":
        set_scnene_info()
    Root.add_child(NextScene)
    SceneChanger.get_node("AnimationPlayer").play_backwards("scenechange")
    yield(SceneChanger.get_node("AnimationPlayer"), "animation_finished")
    SceneChanger.get_node("ColorRect").hide()


