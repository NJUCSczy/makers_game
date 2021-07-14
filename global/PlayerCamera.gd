extends Camera2D
#此实例也为单例，控制游戏的镜头位置（如跟着玩家移动），大小固定。
#注意，镜头尺寸与游戏窗口大小相同，为1280x720像素，镜头焦点为中心位置
var LimitArea=[640,360,640,360] #四个数字分别代表镜头焦点坐标的左边界、上边界、右边界、下边界

func reset_camera_area(x1:float,y1:float,x2:float,y2:float):#重设镜头边界
    if x1>x2 or y1>y2:
        print("Reset camera area failed! Invalid area size!")
        return
    LimitArea[0]=x1
    LimitArea[1]=y1
    LimitArea[2]=x2
    LimitArea[3]=y2

func set_camera(pos:Vector2):#重设镜头位置，如果超出边界会被锁定在边界
    global_position=pos
    if pos.x<LimitArea[0]:
        global_position.x=LimitArea[0]
    elif pos.x>LimitArea[2]:
        global_position.x=LimitArea[2]
    if pos.y<LimitArea[1]:
        global_position.y=LimitArea[1]
    elif pos.y>LimitArea[3]:
        global_position.y=LimitArea[3]

