SIMULATION = AddModule("Simulation")                                        --设置模块
SCENE = AddParameter(SIMULATION, nil, "scene", "Choose a scene")            --添加场景参数
SPEED = AddParameter(SIMULATION, nil, "value", "Simulation speed", 1)       --添加仿真速度参数

--仓库库位间隔为1.5，第一个库位坐标为（1，0，1）
--AGV速度为1，指令执行时间为1.5，指令有前进F（x轴正方向），后退B，右移R，左移L，装载M，卸载U
function Simulation()                                                       --仿真模块

    

    
    --shelf={m = LoadObject(SCENE, "shelf.3ds"), id =#shelfsContainer+1}
    function newShelfsContainer()
        local containers={l=0}
        
        --新入库
        function containers.ad(shelf)
            index=#containers+1
            containers[index]=shelf
            containers.l=containers.l+1
        end
        
        function containers.rm(i)
            containers[i]=nil
            containers.l=containers.l-1
        end

        function containers.clear()
            containers.l=0
            for i=1,#containers do
                table.remove(containers,1)
            end           
        end
        
        --从上到下，从右到左依次填满
        function containers.shelfMap(index,n)
            local border=0.25
            --第1列，坐标位置应该在3(3+1-1)
            local col=(n+1)-(math.floor((index-0.01)/n)+1)
            local row=n-(index-1)%n
            return col,row
        end
        return containers
    end
    
    function newQueue()
        queue={}
        EngineX=CreateRandEng (1,"exponential", 1)                --泊松分布中，事件的到达服从指数分步
        function queue.generate()
            qt=os.clock()
            local x = GetNextRandom(EngineX)
            function queue.check(t)
                if (t-qt)>=5*x then
                    x=GetNextRandom(EngineX)
                    queue.push()
                    qt=t
                end
            end
        end

        function queue.push()
            queue[#queue+1] =1
        end

        function queue.pop()
            queue[#queue] =nil 
        end
    
        return queue
        
    end
    
    
    local shelfs = newShelfsContainer()                                                       --定义货架数组
    
    
    for i = 1, 100 do
        local shelf = {m = GetObject(SCENE, "SHELF"..i), id = i}            --得到场景中的货架i
        if shelf.m then                                                     --如果货架i存在
            shelfs.ad(shelf)                                               --存入货架数组中
            print("id "..shelf.id)
        end
    end
    
    
    
    function NewAGV(m)                                                      --AGV工厂函数
        local agv = {}                                                      --AGV表，用来存放接口
        agv.m = m                                                           --AGV的三维模型
        agv.v = 1                                                           --速度
        SetPosition(agv.m, -0.5, 0, 1)                                      --AGV初始位置

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
                    
                elseif cmd[cur] == 'L' then                                 --如果当前指令为向左
                    local x,y,z = pos[1], pos[2], pos[3] - t%1.5           --根据指令执行时间计算位置
                    if (x - 1)%1.5 < 0.01 or (x - 1)%1.5 > 1.49 then        --如果极为接近1.5的整数倍
                        x = math.floor((x - 1)/1.5 + 0.5)*1.5 + 1           --修正x为1.5的整数倍
                    end
                    SetPosition(agv.m, x, y, z)                             --设置AGV的位置  
                
                elseif cmd[cur] == 'R' then                                 --如果当前指令为向右
                    local x,y,z = pos[1], pos[2], pos[3] + t%1.5           --根据指令执行时间计算位置
                    if (x - 1)%1.5 < 0.01 or (x - 1)%1.5 > 1.49 then        --如果极为接近1.5的整数倍
                        x = math.floor((x - 1)/1.5 + 0.5)*1.5 + 1           --修正x为1.5的整数倍
                    end
                    SetPosition(agv.m, x, y, z)  
                
                elseif cmd[cur] == 'M' and not finish then                  --如果当前指令为装载货架
                    if pos[1] < 0 then                                      --如果在仓库外
                        local shelf = {m = LoadObject(SCENE, "shelf.3ds"), id = #shelfs+1}  --加载新货架
                        shelfs.ad(shelf)                         --加入到货架数组
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
                                    print()
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
                            shelfs.rm(agv.shelf.id)                      --删除货架数组中的相应元素
                        end
                        agv.shelf = nil                                     --设置AGV的货架属性
                        finish = true                                       --设置完成标志，避免重复
                    end
                end
            end
        end
        
        function agv.bein(index,n,shelfs)
            
            ---指定小车运行轨迹
            dx,dy=shelfs.shelfMap(index,n)
            for i=1,dx do
                agv.cmd('F')
            end            
            for i=1,dy-1 do
                agv.cmd('R')            
            end    

        end
        
        function agv.beout(index,n,shelfs)
            ---指定小车退出轨迹
            dx,dy=shelfs.shelfMap(index,n)
            for i=1,dy-1 do
                agv.cmd('L')
            end            
            for i=1,dx do
                agv.cmd('B')            
            end   
        end
        
        function agv.intask(tasks,n,shelfs)
            --执行几个任务
            local start=shelfs.l+1
            for i=start,start+tasks-1 do
                agv.cmd('M')
                agv.bein(i,n,shelfs)
                agv.cmd('U')
                agv.beout(i,n,shelfs)
            end
        end
        
        function agv.outtask(tasks,n,shelfs)
            --执行几个任务
            local start=shelfs.l
            local tail=1
            if start>tasks then
                tail=start-tasks
            end
            
            for i=start,tail,-1 do
                agv.bein(i,n,shelfs)
                agv.cmd('M')
                agv.beout(i,n,shelfs)
                agv.cmd('U')
            end
        end
        
        function agv.assignTask(shelfs,queue,n)
            if #queue>0 and shelfs.l<n*n  then           ---优先进(有空闲)
                local space=n*n-shelfs.l
                if #queue<space then
                    space=#queue
                end
                agv.intask(space,n,shelfs)
                
            elseif shelfs.l==n*n  then                  ---出(满载)
                agv.outtask(n*n,n,shelfs)   
            end             
        end
        
        return agv                                                          --返回接口表
        
        
    end
    

    
    

    
    local simt = 0                                                          --初始仿真时间
    local realt = os.clock()                                                --初始现实时间
    
    
    
    
    shelfs.clear()
    local agv1 = NewAGV(GetObject(SCENE, "AGV1"))                           --使用工厂函数创建AGV
    waitingQueue=newQueue()

    agv1.intask(4,3,shelfs)
    agv1.outtask(3,3,shelfs)
    
    -- agv1.cmd('F')                                                           --插入前进指令
    -- agv1.cmd('F')
    -- agv1.cmd('M')                                                           --插入装载货架指令
    -- agv1.cmd('B')                                                           --插入后退指令
    -- agv1.cmd('B')
    -- agv1.cmd('U')                                                           --插入卸载货架指令
    -- agv1.cmd('M')                                                           --插入装载货架指令
    -- agv1.cmd('F')                                                           --插入前进指令
    -- agv1.cmd('U')                                                           --插入卸载指令
    -- agv1.cmd('B')                                                           --插入后退指令
    agv1.exec()                                                             --执行所有指令
    waitingQueue.generate()
  
  

    
    while GetReady() do                                                     --当系统就位时循环
        local realdt = os.clock() - realt                                   --计算现实时间间隔
        realt = os.clock()                                                  --为下一次计算记录现实时间
        local simdt = realdt*SPEED                                          --计算仿真时间间隔
        simt = simt + simdt                                                 --计算仿真时间
        agv1.assignTask(shelfs,waitingQueue,3)
        agv1.state(simt)                                                    --设置AGV状态
    end
end