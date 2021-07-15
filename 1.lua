
SIMULATION = AddModule("Simulation")                                        --设置模块
SCENE = AddParameter(SIMULATION, nil, "scene", "Choose a scene")            --添加场景参数
SPEED = AddParameter(SIMULATION, nil, "value", "Simulation speed", 1)       --添加仿真速度参数

--仓库库位间隔为1.5，第一个库位坐标为（1，0，1）
--AGV速度为1，指令执行时间为1.5，指令有前进F（x轴正方向），后退B，右移R，左移L，装载M，卸载U
function Simulation()                                                       --仿真模块

    local shelfs = {}                                                       --定义货架数组
    for i = 1, 100 do
        local shelf = {m = GetObject(SCENE, "SHELF"..i), id = i}            --得到场景中的货架i
        if shelf.m then                                                     --如果货架i存在
            shelfs[i] = shelf                                               --存入货架数组中
        end
    end
    
    function NewAGV(m)                                                      --AGV工厂函数
        local agv = {}                                                      --AGV表，用来存放接口
        agv.m = m                                                           --AGV的三维模型
        agv.v = 1                                                           --速度
        SetPosition(agv.m, -0.5, 0, 1)                                      --AGV初始位置
        --SetPosition(agv.m, -0.5, 0, 1)
        
        local cmd = {}                                                      --初始化指令列表
        function agv.cmd(o)                                                 --插入指令函数
            table.insert(cmd, o)
        end
        
        function agv.exec()                                                 --执行指令
            local pos                                                       --用来记录指令执行前的位置
            local finish                                                    --用来判断指令是否执行完成
            local cur0 = 0                                                  --记录前一个指令指针
            
            function agv.state(t)                                           --AGV状态函数
                local cur = math.floor(t/1.5) + 1                           --计算当前指令指针（指令执行时间1.5）
                if cur ~= cur0 then                                         --如果与前一个指令指针不同（执行新指令）
                    pos = {GetPosition(agv.m)}                              --初始化位置
                    finish = false                                          --设置完成标志
                    cur0 = cur                                              --设置前一个指令指针
                end
                
                if cmd[cur] == 'F' then                                     --如果当前指令为前进
                    local x,y,z = pos[1] + t%1.5, pos[2], pos[3]            --根据指令执行时间计算位置
                    if (x - 1)%1.5 < 0.01 or (x - 1)%1.5 > 1.49 then        --如果极为接近1.5的整数倍
                        x = math.floor((x - 1)/1.5 + 0.5)*1.5 + 1           --修正x为1.5的整数倍
                    end
                    SetPosition(agv.m, x, y, z)                             --设置AGV的位置        
                    
                elseif cmd[cur] == 'B' then                                 --如果当前指令为后退
                    local x,y,z = pos[1] - t%1.5, pos[2], pos[3]            --根据指令执行时间计算位置
                    if (x - 1)%1.5 < 0.01 or (x - 1)%1.5 > 1.49 then        --如果极为接近1.5的整数倍
                        x = math.floor((x - 1)/1.5 + 0.5)*1.5 + 1           --修正x为1.5的整数倍
                    end
                    SetPosition(agv.m, x, y, z)                             --设置AGV的位置        
                
                elseif cmd[cur] == 'M' and not finish then                  --如果当前指令为装载货架
                    if pos[1] < 0 then                                      --如果在仓库外
                        local shelf = {m = LoadObject(SCENE, "agv.3ds"), id = #shelfs+1}  --加载新货架
                        table.insert(shelfs, shelf)                         --加入到货架数组
                        SetObjectID(shelf.m, "SHELF"..shelf.id)             --设置货架在场景中的ID
                        SetPosition(shelf.m, unpack(pos))                   --设置货架位置
                        SetParent(shelf.m, agv.m)                           --设置货架父对象
                        agv.shelf = shelf                                   --设置AGV的货架属性
                        finish = true                                       --设置完成标志
                    else
                        for i = 1, #shelfs do                               --遍历货架
                            if shelfs[i] then                               --如果货架存在
                                local x,y,z = GetPosition(shelfs[i].m)      --得到货架i的位置
                                if x == pos[1] and z == pos[3] then         --判断是否在AGV的位置上
                                    SetParent(shelfs[i].m, agv.m)           --设置货架父对象为AGV
                                    agv.shelf = shelfs[i]                   --设置AGV的货架属性
                                    finish = true                           --设置完成标志，避免重复
                                    break                                   --退出循环
                                end
                            end
                        end
                    end
                elseif cmd[cur] == 'U' and not finish then                  --如果当前指令为卸载货架
                    if agv.shelf then                                       --如果AGV带有货架属性
                        SetParent(agv.shelf.m, nil)                         --设置货架的父对象为无
                        if pos[1] < 0 then                                  --如果卸载在仓库外
                            DelObject(agv.shelf.m)                          --删除货架
                            shelfs[agv.shelf.id] = nil                      --删除货架数组中的相应元素
                        end
                        agv.shelf = nil                                     --设置AGV的货架属性
                        finish = true                                       --设置完成标志，避免重复
                    end
                end
            end
        end
        return agv                                                          --返回接口表
    end

    function generateShelf()
        
    end
    
    local simt = 0                                                          --初始仿真时间
    local realt = os.clock()                                                --初始现实时间
    
    local agv1 = NewAGV(GetObject(SCENE, "AGV1"))                           --使用工厂函数创建AGV
    agv1.cmd('F')                                                           --插入前进指令
    agv1.cmd('M')                                                           --插入装载货架指令
    agv1.cmd('B')                                                           --插入后退指令
    agv1.cmd('U')                                                           --插入卸载货架指令
    agv1.cmd('M')                                                           --插入装载货架指令
    agv1.cmd('F')                                                           --插入前进指令
    agv1.cmd('U')                                                           --插入卸载指令
    agv1.cmd('B')                                                           --插入后退指令
    agv1.exec()                                                             --执行所有指令

    while GetReady() do                                                     --当系统就位时循环
        --| | | |
        --| | | |
        --|  |  |
        local realdt = os.clock() - realt                                   --计算现实时间间隔
        realt = os.clock()                                                  --为下一次计算记录现实时间
        local simdt = realdt*SPEED                                          --计算仿真时间间隔
        simt = simt + simdt                                                 --计算仿真时间
        agv1.state(simt)                                                    --设置AGV状态
    end
end