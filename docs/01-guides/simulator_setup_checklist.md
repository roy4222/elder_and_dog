# 模擬器環境確認清單（Isaac Sim + go2_omniverse）

**版本：** v1.0
**日期：** 2025/11/21
**負責人：** 柏翊（依 conformance_check_plan.md 決議）
**目標：** 確認 Isaac Sim + go2_omniverse 部署進度，並為 12/17 Demo 做準備

---

## 📋 環境概述

根據 conformance_check_plan.md（11/19 會議決議），Demo 採用「實機 + 模擬器」雙環境驗證：

```
實機環節：Mac M1 (UTM Ubuntu) + Go2 Wi-Fi
  └─ SLAM + Nav2 + VLM + FSM

模擬環節：系上 VM/遠端 GPU + Isaac Sim go2_omniverse
  └─ 同一套 Nav2 參數 + topic 介面
```

本清單用於**清點模擬器部署進度**，並確保與實機環節同步。

---

## 🔍 部署進度檢查

### Phase 0：基礎環境（11/19～11/26 完成）

| 項目 | 狀態 | 檢查方法 | 備註 |
|------|------|--------|------|
| **Ubuntu 22.04** | ⏳ / ✅ / ❌ | `lsb_release -a` | 系上 VM 或遠端 GPU 機器 |
| **NVIDIA Driver 545+** | ⏳ / ✅ / ❌ | `nvidia-smi` | 版本應 > 545 |
| **CUDA Toolkit** | ⏳ / ✅ / ❌ | `nvcc --version` | 建議 CUDA 11.8+ |
| **cuDNN** | ⏳ / ✅ / ❌ | `/usr/local/cuda/lib64/libcudnn*` | 用於 Isaac Sim |
| **ROS2 Humble** | ⏳ / ✅ / ❌ | `ros2 --version` | 同本專案環境 |

**11/26 前行動：** 確認上述環境都就緒，記錄版本號

---

### Phase 1：Isaac Sim 部署（11/26 前完成）

| 項目 | 狀態 | 驗證命令 | 說明 |
|------|------|--------|------|
| **Omniverse Launcher** | ⏳ / ✅ / ❌ | 能打開 GUI | 用於下載 Isaac Sim |
| **Isaac Sim 2023.1.1** | ⏳ / ✅ / ❌ | 能啟動 Sim | 約 100GB，首次下載慢 |
| **Orbit Framework 0.3.0** | ⏳ / ✅ / ❌ | `./orbit.sh --help` | Sim 上的 ROS2 橋接 |
| **Isaac Sim + ROS2 通訊** | ⏳ / ✅ / ❌ | `./run_sim.sh` 後看 `/camera`, `/lidar` topics | 關鍵驗證點 |

**檢查步驟：**

```bash
# 1. 啟動 Isaac Sim（需要 GUI 或 X11 轉發）
./run_sim.sh
# 應看到 Isaac Sim 視窗啟動，模擬器開始運行

# 2. 在另一個 Terminal 驗證 ROS2 topics
source /opt/ros/humble/setup.bash
ros2 topic list | grep -E "(camera|lidar|cmd_vel|odom|joint_states)"
# 應看到：
#   /camera/image_raw
#   /point_cloud2
#   /cmd_vel
#   /odom
#   /joint_states
#   /imu
```

**11/26 前行動：** Isaac Sim 能啟動，ROS2 topics 能看到

---

### Phase 2：go2_omniverse 集成（11/26 前完成）

| 項目 | 狀態 | 檢查方法 | 說明 |
|------|------|--------|------|
| **go2_omniverse 倉庫** | ⏳ / ✅ / ❌ | `git clone https://github.com/abizovnuralem/go2_omniverse` | 包含 Go2 模型 |
| **Go2 模型檔** | ⏳ / ✅ / ❌ | 存在 `Unitree_L1.json` | USD 模型定義 |
| **Orbit 路徑配置** | ⏳ / ✅ / ❌ | `./run_sim.sh` 能啟動 Go2 模擬 | 模型應在 Orbit 預期位置 |
| **ROS2 Bridge 配置** | ⏳ / ✅ / ❌ | `ros2 launch` 文件正確 | topic 映射完整 |

**檢查步驟：**

```bash
# 1. 克隆 go2_omniverse
cd /path/to/parent_dir
git clone https://github.com/abizovnuralem/go2_omniverse --recurse-submodules

# 2. 進入目錄
cd go2_omniverse

# 3. 啟動模擬器
./run_sim.sh
# 應看到 Isaac Sim 中出現 Go2 模型，可用 WASD 控制

# 4. 驗證 ROS2 輸出
# 在另一個 Terminal：
ros2 topic echo /camera/image_raw --max-count 1
ros2 topic echo /point_cloud2 --max-count 1
# 應有影像和點雲輸出
```

**11/26 前行動：** go2_omniverse 能啟動，WASD 控制有反應

---

### Phase 3：與本專案整合（11/27～12/03）

| 項目 | 狀態 | 檢查方法 | 說明 |
|------|------|--------|------|
| **workspace 合併** | ⏳ / ✅ / ❌ | go2_robot_sdk src 加入 go2_omniverse/src | 統一編譯環境 |
| **topic 映射驗證** | ⏳ / ✅ / ❌ | `/camera/image_raw`, `/point_cloud2`, `/cmd_vel` 對齊 | 實機和模擬器相同名稱 |
| **colcon build** | ⏳ / ✅ / ❌ | `colcon build` 完整編譯 | 無紅色 ERROR |
| **robot.launch.py 適配** | ⏳ / ✅ / ❌ | `ros2 launch go2_robot_sdk robot.launch.py sim:=true` | 同時支援實機和模擬 |

**檢查步驟：**

```bash
# 1. 建立統一工作空間
cd /workspace
mkdir -p go2_sim_ws/src
cd go2_sim_ws/src

# 2. 複製 go2_robot_sdk（使用符號連結或複製）
ln -s /path/to/elder_and_dog/src/go2_robot_sdk .
ln -s /path/to/elder_and_dog/src/go2_interfaces .

# 3. 複製 go2_omniverse 的相關套件
ln -s /path/to/go2_omniverse/src/go2_sim_driver .

# 4. colcon build
cd ..
colcon build

# 5. 測試 SLAM + Nav2 在模擬器上執行
source install/setup.bash
# 在一個 Terminal 啟動模擬器
/path/to/go2_omniverse/run_sim.sh
# 在另一個 Terminal 啟動 ROS2 stack
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true sim:=true
```

**11/27～12/03 行動：** 實現模擬器 + SLAM + Nav2 的完整整合

---

### Phase 4：VLM 集成（12/02～12/09）

| 項目 | 狀態 | 檢查方法 | 說明 |
|------|------|--------|------|
| **COCO 推論節點** | ⏳ / ✅ / ❌ | `ros2 run vision_vlm coco_detector_node` | 模擬器上能推論 |
| **座標轉換節點** | ⏳ / ✅ / ❌ | `ros2 run vision_vlm image_to_3d_node` | 2D→3D 座標轉換 |
| **FSM 整合** | ⏳ / ✅ / ❌ | `ros2 run search_logic search_fsm_node` | 尋物邏輯在模擬器上執行 |
| **端到端測試** | ⏳ / ✅ / ❌ | 完整搜尋流程：巡邏→掃描→導航→找到 | 模擬器上無 Wi-Fi 延遲，測試最穩定 |

**檢查步驟：**

```bash
# 1. 啟動模擬器和 SLAM/Nav2
source install/setup.bash
/path/to/go2_omniverse/run_sim.sh &
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true sim:=true &

# 2. 啟動 VLM 節點
ros2 run vision_vlm coco_detector_node &
ros2 run vision_vlm image_to_3d_node &
ros2 run search_logic search_fsm_node &

# 3. 發送搜尋指令
ros2 topic pub /search_command std_msgs/String "data: 'search_cup'" --once

# 4. 監控狀態
ros2 topic echo /search_status
# 應看到：PATROL → SCANNING → NAVIGATING → FOUND
```

---

## 📊 進度表

```
11/19～11/26：基礎環境 + Isaac Sim 部署
    ├─ ✅ 完成：Ubuntu, NVIDIA Driver, ROS2
    ├─ ⏳ 進行中：Isaac Sim 下載和安裝
    └─ ⏳ 進行中：go2_omniverse 克隆和基礎驗證

11/27～12/03：與本專案整合
    ├─ ⏳ 待開始：workspace 合併
    ├─ ⏳ 待開始：colcon build
    └─ ⏳ 待開始：SLAM/Nav2 在模擬器上驗證

12/02～12/09：VLM + FSM 整合
    ├─ ⏳ 待開始：COCO 在模擬器上推論
    ├─ ⏳ 待開始：座標轉換驗證
    └─ ⏳ 待開始：端到端測試

12/10～12/17：Demo 準備
    ├─ ⏳ 待開始：腳本優化和備案準備
    └─ ⏳ 待開始：Demo 預演和影片錄製
```

---

## 🔗 關鍵資源

| 項目 | 鏈接 | 說明 |
|------|------|------|
| **go2_omniverse** | https://github.com/abizovnuralem/go2_omniverse | Go2 模擬器 |
| **Isaac Sim 文檔** | https://docs.omniverse.nvidia.com/isaacsim/latest/ | 官方文檔 |
| **Orbit 框架** | https://github.com/isaac-sim/orbit | ROS2 整合工具 |
| **本專案 conformance_check_plan** | `docs/00-overview/conformance_check_plan.md` | Demo 規劃 |

---

## 📝 重要事項

### 網路連接方式

- **本地 VM：** 直接啟動 Isaac Sim GUI
- **遠端 GPU：** 使用 X11 轉發或 NoMachine 遠端桌面
  ```bash
  # SSH 連接時啟用 X11 轉發
  ssh -X user@gpu_server
  ```

### Topic 命名一致性

**實機和模擬器必須相同：**
```
/camera/image_raw         # 相機影像
/point_cloud2             # 點雲
/cmd_vel                  # 命令速度
/odom                     # 里程計
/joint_states             # 關節狀態
/scan                     # LiDAR 掃描
/map                      # SLAM 地圖
/amcl_pose                # 定位估計
```

### 已知差異（實機 vs 模擬）

| 項目 | 實機 | 模擬 |
|------|------|------|
| **Wi-Fi 延遲** | 50-200ms | 0ms |
| **點雲頻率** | ~7 Hz | 可調 |
| **物理精度** | 實際運動 | USD 模擬 |
| **光照條件** | 真實環境 | 可控 |

---

## ✅ 完成標誌

**11/26 前必達：**
- [ ] Isaac Sim 能啟動
- [ ] go2_omniverse 能運行
- [ ] ROS2 topics 能看到（camera, lidar, cmd_vel）

**12/03 前必達：**
- [ ] SLAM + Nav2 在模擬器上運行
- [ ] 自動建圖和導航驗證通過

**12/09 前必達：**
- [ ] COCO + 座標轉換 + FSM 完整集成
- [ ] 端到端搜尋流程驗證通過

**12/17 Demo 當日：**
- [ ] 實機展示：5 分鐘完整流程
- [ ] 模擬器展示：5 分鐘完整流程
- [ ] 備案影片：已錄製

---

## 📞 聯繫

- **負責人：** 柏翊
- **技術問題：** 請提交 GitHub Issue 或聯繫專題組
- **進度同步：** 每週一次，與 SLAM + Nav2 + VLM 進度對齊

---

**Let's build this Demo together! 🚀**

