extends Node
#相当于是一个全局的数据访问文档，只读
var ItemRference={
    "木材":{
        "ID":1,                                 #ID，代表物品编号，也可以认为是另一种代号
        "Type":"Material",                      #类型，便于区分
        "Weight":1,                             #单个物品重量
        "Usable":false,                         #是否可以直接在背包中使用
        "Price":1,                              #单价（出售）
        "Description":"一小堆木材，常见的建筑材料。" 
        },
    "0.9mm子弹":{
        "ID":11,
        "Type":"Bullet",
        "Weight":0.01,
        "Usable":false,
        "Price":0.5,
        "Description":"0.5毫米子弹，常用于冲锋枪。"
       }
   }
