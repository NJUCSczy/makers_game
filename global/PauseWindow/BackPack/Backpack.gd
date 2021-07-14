extends Node2D

var InventoryChosen:int=0       #选中的物品栏
var InventoryFocused:int=0      #鼠标聚焦的物品栏（可能没有选中） 

func _ready():
    $InventoryList/InventoryChosen.hide()
    $InventoryList/InventoryFocused.hide()

func _input(event):
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
        if InventoryFocused!=0 and InventoryChosen!=InventoryFocused:
            InventoryChosen=InventoryFocused
            $InventoryList/InventoryChosen.global_position=$InventoryList.get_node("Inventory"+String(InventoryChosen)).global_position
            $InventoryList/InventoryChosen.show()

func inventory_focus_get(Num:int):
    InventoryFocused=Num
    $InventoryList/InventoryFocused.global_position=$InventoryList.get_node("Inventory"+String(InventoryFocused)).global_position
    $InventoryList/InventoryFocused.show()

func inventory_focus_lose(Num:int):
    if InventoryFocused==Num:
        InventoryFocused=0
        $InventoryList/InventoryFocused.hide()
