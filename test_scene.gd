extends Node2D

onready var navigation=$Navigation2D

var Identifier="BattleScene"

func _ready():
    Global.set_navigation()
    Global.PlayerCamera.reset_camera_area(540,260,2300-640,1200-360)
    $NPCs/NPC.init("test_NPC","following")
    $Enermies/Enermy.init("test_enermy",Vector2(-1,0))
    $Enermies/Enermy2.init("test_enermy",Vector2(-1,0))
    $Enermies/Enermy3.init("test_enermy",Vector2(0,-1))

