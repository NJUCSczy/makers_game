extends Area2D
signal hit_with_synthesis

# 这里只是一个用于交互的结点
#var whether_in = false#采用帕斯卡命名格式
var WhetherIn=false


func _ready():
    pass # Replace with function body.


func _input(event):
    if event is InputEventKey and event.pressed:
        if event.scancode == KEY_F && WhetherIn:
            if self.name =="Synthesis_table":
                Global.change_scene("res://Synthesis_table/Synthesis_table_scene.tscn")

func _on_Synthesis_table_body_shape_entered(body_id, body, body_shape, local_shape):
#    if body_id==1304:#id貌似是动态生成的，再次进入这个场景之后会不一样
#        whether_in = true
    if body.Identifier=="Player":
        WhetherIn=true



func _on_Synthesis_table_body_shape_exited(body_id, body, body_shape, local_shape):
#    if body_id==1304:
#        whether_in = false
    if body.Identifier=="Player":
        WhetherIn=false
