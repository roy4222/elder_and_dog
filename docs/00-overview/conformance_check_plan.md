# Go2 智慧尋物系統計畫符合度檢查與修正規劃

**報告日期：** 2025/11/16  
**分析基礎：** [Goal.md](./Goal.md)（目標計畫） vs [claude_plan.md](./claude_plan.md)（現況報告） vs go2_omniverse/README.md（模擬器專案）

## 1. 計畫符合度評估
| 項目 | [Goal.md](./Goal.md) 目標 | [claude_plan.md](./claude_plan.md) 現況 | 符合度 | 備註 |
|------|--------------|---------------------|--------|------|
| **基礎建設 (ROS2 + SDK)** | Ubuntu 22.04 + ROS2 Humble + Clean Arch. | 95% (程式齊備，多機/WebRTC/CycloneDDS) | ✅ 高 | 僅缺本機 ROS2 安裝 & pip 網路修復 |
| **SLAM + Nav2** | slam_toolbox + Nav2 | 100% (launch 整合，參數優化) | ✅ 完備 | 可即時使用，LiDAR 7Hz |
| **感測器整合** | LiDAR/Camera/IMU | 95% (topic 鏈路完整，TF 補償) | ✅ 高 | COCO 需 remap `/camera/image_raw` |
| **模擬器** | Isaac Sim (Orbit) | 0% (無安裝) | ⚠️ 缺 | **go2_omniverse 完美匹配**：支援 ROS2 bridge、Nav2/SLAM、LiDAR/Camera/IMU/關節同步、鍵盤控制。僅需安裝 Isaac Sim 2023.1.1 + Orbit 0.3.0 |
| **VLM 視覺** | Gemini Robotics (Zero-shot) | 15% (COCO 替代，camera_info/TF 基礎) | ❌ 低 | 需新節點：影像 → Gemini API → Detection2DArray |
| **座標轉換** | 2D像素 → 3D世界 (LiDAR深度 + tf2) | 基礎 (camera_info/TF) | ⚠️ 中 | 需新節點：像素 + LiDAR投影/地面假設 + tf2 → PoseStamped |
| **尋物邏輯** | FSM (巡邏→掃描→導航) | 0% | ❌ 低 | 需新狀態機節點，使用 Nav2 action client |
| **Web UI** | 自訂前端 (影像/地圖/結果) | 30% (Foxglove Bridge) | ⚠️ 中 | 可擴 Foxglove 或新 React UI |
| **總體** | 4個月時程 | **約55%** | 🟡 中等 | 基礎強，核心 (VLM/轉換/FSM/模擬) 待補 |

**結論：** 現況高度符合 [Goal.md](./Goal.md) 基礎與導航部分，模擬器由 go2_omniverse 解決（非零開發），關鍵缺口為 VLM/轉換/FSM（W6-W9）。風險低，利用現有加速。

## 2. 修正後系統架構圖 (整合 go2_omniverse)

```mermaid
graph TD
    subgraph Web["Web 前端 (Foxglove 或自訂)"]
        User[使用者指令: 找眼鏡] --> WebBridge[ROS2 Web Bridge/WebSocket]
        Stream[即時影像/地圖] <--> WebBridge
    end

    subgraph ROS2["ROS2 核心 (伺服器/VM)"]
        WebBridge --> SearchFSM[尋物 FSM 節點]
        CameraRaw[/camera/image_raw] --> VLMNode[Gemini VLM 節點]
        LidarPC[point_cloud2] --> CoordXform[座標轉換節點]
        VLMNode --> Det2D[Detection2DArray]
        Det2D --> CoordXform
        CoordXform --> WorldPose[PoseStamped 世界座標]
        SearchFSM --> Nav2[Nav2 堆疊]
        WorldPose --> Nav2
        Nav2 --> CmdVel[/cmd_vel]
        SLAM[slam_toolbox] --> Map[/map]
    end

    subgraph Sim["Isaac Sim (go2_omniverse)"]
        CmdVel --> Go2Ctrl[Go2 控制器]
        Go2Ctrl <--> Go2Sim[Go2 數位孿生]
        Go2Sim --> LidarPC
        Go2Sim --> CameraRaw
        Go2Sim --> IMUOdom[joint_states/odom/IMU]
    end

    subgraph Real["實機 Go2 (選用)"]
        Go2Ctrl <--> Go2Real[實機 Go2]
        Go2Real --> LidarPC
        Go2Real --> CameraRaw
        Go2Real --> IMUOdom
    end

    Map --> WebBridge
    IMUOdom --> SLAM
    LidarPC --> SLAM[/scan]
```

## 3. 更新時程規劃 (W1-W16，加速版利用現況 & go2_omniverse)

| 月 | 週 | 任務重點 | 里程碑 | 狀態 |
|----|----|----------|--------|------|
| **1** | W1 | 環境配置 (ROS2 Humble + pip修復 + colcon build) | ✅ ROS2 跑通 robot.launch.py | 立即 |
| | W2 | 實機/Sim 感測器驗證 (LiDAR 7Hz, COCO remap) | ✅ topic hz 正常，SLAM 建圖 | 已近 |
| | W3 | SLAM/Nav2 測試 (save/load map, 導航成功率) | ✅ 複雜環境避障 | 已近 |
| | W4 | **Isaac Sim + go2_omniverse 整合** | ✅ run_sim.sh 跑通，ROS2 bridge 串 go2_robot_sdk | 新重點 |
| **2** | W5 | Nav2 優化 (多機/模擬) | ✅ 成功率>90% | 擴展 |
| | W6 | **Gemini VLM 節點** (API + Detection2DArray) | ✅ 零樣本辨識 (眼鏡/鑰匙) | 新 |
| | W7 | **座標轉換 I** (像素 + LiDAR投影/深度) | ✅ 本體座標誤差<10cm | 新 |
| | W8 | **座標轉換 II** (tf2 → 世界座標 + Nav2 目標) | ✅ VLM → 導航閉環 | 新 |
| **3** | W9 | **尋物 FSM** (巡邏/掃描/鎖定/導航) | ✅ 端到端尋物 (模擬) | 新 |
| | W10 | Web UI 擴展 (Foxglove + BBox/狀態) | ✅ 即時顯示結果 | 擴展 |
| | W11 | 使用者測試 (高齡情境) | ✅ 回饋優化 | 新 |
| | W12 | 穩定性測試 (1hr 連跑) | ✅ 邊緣案例 fix | 新 |
| **4** | W13-W16 | Demo 準備/文件/最終檢查 | ✅ 影片 + Plan B/C | 後期 |

## 4. 模擬器整合具體步驟 (go2_omniverse)
1. 安裝 Ubuntu 22.04 + NVIDIA Driver 545+ + Isaac Sim 2023.1.1 (Omniverse Launcher 或 Docker)。
2. 安裝 ROS2 Humble + Orbit 0.3.0 (`./orbit.sh --install --extra rsl_rl`)。
3. `git clone https://github.com/abizovnuralem/go2_omniverse --recurse-submodules` 到專案外目錄。
4. 複製 Unitree_L1.json & material_files 到 Orbit 路徑。
5. `./run_sim.sh` (Go2) 或 `./run_sim_g1.sh`，WASD 控制，驗證 ROS2 topic (camera/lidar/imu/cmd_vel)。
6. 串接：go2_omniverse ROS2 ws src 加 go2_interfaces，colcon build，launch robot.launch.py + sim bridge。
7. 驗證：SLAM/Nav2 在 Sim 環境建圖導航。

## 5. 資源確認清單
| 項目 | 需求 | 狀態 | 行動 |
|------|------|------|------|
| GPU 伺服器 | ✅ **Quadro RTX 8000 48GB（遠端 SSH）** | ✅ 已確認 | ROY 完成驗證 |
| Gemini API | 開發額度 10K/月 | Waiting List | 立即申請/追蹤（備案：本地 LLaVA） |
| 網路/DNS | pip apt 正常 (WSL proxy) | ❌ 待修復 | 設 proxy/http_proxy 或 Docker |
| Isaac Sim | 2023.1.1 + Orbit 0.3.0 | ❌ 待部署至遠端伺服器 | W7-W8 安裝（詳見 ../01-guides/remote_gpu_setup.md） |

## 6. 風險管理 (Plan A/B/C)
| 風險 | 等級 | 緩解 | Plan B (Demo) | Plan C (最低) |
|------|------|------|---------------|---------------|
| 座標誤差 | 🔴 高 | LiDAR 投影 + 多點平均 | 導大致區域 + Web 標 VLM BBox | COCO + 手動導航 |
| Isaac Sim 阻 | 🔴 高 | 跟 README 步驟，Docker 備援 | 實機 SLAM/Nav2 + 預錄 VLM | 純實機無 VLM |
| VLM 延遲 | 🟡 中 | 快取 + 降頻 (1Hz) | 預錄結果 + 實機導航 | COCO 80類 |
| ROS2/pip | 🟡 中 | proxy/Docker | Docker compose up | 手動依賴 |

**總結：** 計畫高度可行，go2_omniverse 大幅降低模擬風險。預計 W9 端到端 Demo 就緒。建議立即 W1 環境 fix 起跑。
