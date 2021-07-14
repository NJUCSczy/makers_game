extends Node2D

func _ready():
    $Backpack.hide()
    $Options.hide()
    hide()

func _physics_process(delta):
    global_position=Global.PlayerCamera.global_position


func _on_CloseButton_pressed():
    hide()
    get_tree().paused=false
    Global.GameStatus="PlayerControl"


func _on_QuitGameButton_pressed():
    get_tree().quit()


func _on_PlayerButton_pressed():
    $PlayerInfo.show()
    $Backpack.hide()
    $Options.hide()
    
func _on_BackpackButton_pressed():
    $PlayerInfo.hide()
    $Backpack.show()
    $Options.hide()


func _on_OptionButton_pressed():
    $PlayerInfo.hide()
    $Backpack.hide()
    $Options.show()

