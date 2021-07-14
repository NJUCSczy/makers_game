extends Area2D

var Number:int              #自身编号
var CursorOn:bool=false     #鼠标是否放在此物品栏上

onready var BackPack=get_parent().get_parent()

func _ready():
    Number=int(name.right(9))

func _on_Inventory_mouse_entered():
    CursorOn=true
    BackPack.inventory_focus_get(Number)


func _on_Inventory_mouse_exited():
    CursorOn=false
    BackPack.inventory_focus_lose(Number)
