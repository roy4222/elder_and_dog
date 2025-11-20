# Go2 智慧尋物系統 - 技術整合規劃文件

**版本：** v1.1
**日期：** 2025/11/20（根據 2025/11/19 會議決議更新）
**適用週次：** W6-W9（當前開發階段）
**負責團隊：** FJU Go2 專題組

🎯 **第一階段發表：2025/12/17**

---

## 📋 文件目的

本文件提供 Go2 智慧尋物系統從**基礎建設完成**（55%）到**端到端 Demo 就緒**（90%）的詳細整合路線圖。

---

## 🎯 整合目標

### 最終目標（W9 結束時）
實現完整的尋物流程：
```
使用者指令 "找遙控器"
  ↓
COCO VLM 識別影像中的遙控器位置（2D 像素座標）
  ↓
座標轉換系統將 2D 座標轉為 3D 世界座標
  ↓
尋物狀態機啟動導航（Nav2）前往目標位置
  ↓
機器狗到達目標區域，回報成功
```

### 成功指標
- ✅ VLM 物體識別準確率 > 85%（零樣本）
- ✅ 座標轉換誤差 < 15cm（水平方向）
- ✅ Nav2 導航成功率 > 90%（複雜環境）
- ✅ 端到端尋物成功率 > 70%（Isaac Sim 環境）

---

## 🏗️ 系統架構總覽

### 現有基礎（已完成 55%）
```
┌─────────────────────────────────────────────────────────┐
│ 已完成模組（go2_robot_sdk）                              │
├─────────────────────────────────────────────────────────┤
│ ✅ ROS2 驅動層（WebRTC/CycloneDDS）                      │
│ ✅ 感測器發佈（camera/image_raw, point_cloud2, IMU）     │
│ ✅ SLAM 建圖（slam_toolbox）                             │
│ ✅ Nav2 導航（避障、路徑規劃）                            │
│ ✅ TF 樹（odom → base_link → camera_link）               │
│ ✅ 相機內參（720p/1080p calibration）                    │
│ ✅ Foxglove 可視化                                       │
└─────────────────────────────────────────────────────────┘
```

### 待開發模組（W6-W9）
```
┌─────────────────────────────────────────────────────────┐
│ 新增模組（W6-W9 開發重點）                               │
├─────────────────────────────────────────────────────────┤
│ 🔴 COCO VLM 節點（vision_vlm）【Plan A 主力】           │
│    - 訂閱：camera/image_raw                              │
│    - 發佈：/detected_objects (Detection2DArray)         │
│    - 模型：TorchVision MobileNet SSD v2 (COCO 80 類)    │
│                                                          │
│ 🔴 座標轉換節點（coordinate_transformer）                │
│    - 訂閱：/detected_objects, point_cloud2, camera_info  │
│    - 發佈：/object_pose_world (PoseStamped)             │
│                                                          │
│ 🔴 尋物狀態機（search_logic）                            │
│    - 狀態：IDLE → PATROL → SCAN → NAVIGATE → SUCCESS    │
│    - 整合：Nav2 Action Client                           │
│                                                          │
│ 🟡 Isaac Sim 環境（go2_omniverse）                       │
│    - 模擬器：Isaac Sim 2023.1.1 + Orbit 0.3.0          │
│    - ROS2 橋接：與 go2_robot_sdk 互通                    │
└─────────────────────────────────────────────────────────┘
```

---

## 📅 四週開發時程

### Week 6：環境突破 + VLM 雛形（當前週）

#### 🎯 目標
解決環境依賴阻塞，建立 VLM 節點基礎框架。

#### 📋 任務清單

**A. 環境修復（優先級：🔴 最高）**
```bash
# 1. 修復 WSL 網路（DNS/Proxy）
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
export http_proxy=http://proxy:port  # 根據實際環境配置

# 2. 安裝 ROS2 Humble
sudo apt update
sudo apt install ros-humble-desktop-full
source /opt/ros/humble/setup.bash

# 3. 安裝專案依賴（使用 uv）
cd /Users/lubaiyu/elder_and_dog
uv pip install -r src/requirements.txt  # 使用 uv 而非 pip
rosdep install --from-paths src --ignore-src -r -y

# 4. 驗證編譯
colcon build
source install/setup.bash
```

**B. PyTorch 與 COCO 模型準備（Plan A 主力）**
- [ ] 安裝 PyTorch 與 TorchVision（CUDA 11.8）
- [ ] 載入 MobileNet SSD v2 預訓練模型
- [ ] 測試本地 GPU 推論（Python 腳本驗證）
- [ ] 備案：確認 Gemini Robotics API 申請狀態（Plan B）

**C. COCO VLM 節點框架建立**
```bash
# 建立新套件
cd src/
ros2 pkg create --build-type ament_python vision_vlm \
  --dependencies rclpy sensor_msgs vision_msgs cv_bridge

# 目錄結構（詳見 coco_vlm_development.md）
vision_vlm/
├── vision_vlm/
│   ├── __init__.py
│   ├── coco_detector_node.py     # 主節點（COCO Plan A）
│   ├── coco_classes.py            # COCO 80 類別映射（繁體中文）
│   └── detection_converter.py    # 轉換工具
├── package.xml
├── setup.py
├── config/
│   └── coco_params.yaml           # 參數配置
└── requirements-coco.txt          # PyTorch 依賴
```

**D. 初步驗證**
- [ ] 訂閱 `camera/image_raw` 正常
- [ ] PyTorch 模型推論成功（測試影像）
- [ ] 發佈 Detection2DArray 格式正確
- [ ] GPU 記憶體使用正常（< 2GB VRAM）

#### 📊 週末驗收標準
- ✅ ROS2 環境完全正常（`ros2 topic list` 無錯誤）
- ✅ COCO VLM 節點能訂閱影像並輸出偵測結果
- ✅ 至少能識別 COCO 80 類中的 5 種常見物品（遙控器、手機、杯子、書、椅子）

---

### Week 7：座標轉換開發 I（圖像 → 本體座標）

#### 🎯 目標
實現 2D 像素座標 → 3D 本體座標系（base_link）轉換。

#### 📋 任務清單

**A. 建立座標轉換套件**
```bash
ros2 pkg create --build-type ament_python coordinate_transformer \
  --dependencies rclpy sensor_msgs geometry_msgs vision_msgs tf2_ros cv_bridge message_filters
```

**B. 實作 Plan A：LiDAR 點雲投影法**
```python
# coordinate_transformer/lidar_projection_node.py
# 核心邏輯：
# 1. 同步 camera/image_raw + point_cloud2（message_filters）
# 2. 將點雲從 base_link 轉到 camera_link（tf2）
# 3. 投影 3D 點到 2D 圖像平面（相機內參）
# 4. 建立像素 → 3D 點的查找表
# 5. 查詢 VLM 輸出的 [u,v] 對應的 3D 座標
```

**C. 實作 Plan B：地面假設法（備用）**
```python
# coordinate_transformer/ground_assumption_node.py
# 假設物體在地面（z=0 in map frame）
# 使用射線-平面交點計算
```

**D. 校正與測試**
- [ ] 在已知位置（如地面標記）放置物體
- [ ] 記錄 VLM 輸出的像素座標
- [ ] 計算轉換後的 3D 座標與真實位置誤差
- [ ] 調整參數（如點雲密度閾值）

#### 📊 週末驗收標準
- ✅ 座標轉換節點能正常運行
- ✅ 水平誤差 < 20cm（W7-W8 驗收門檻，最終目標 < 15cm）
- ✅ 在 RViz 中可視化轉換結果（發佈 Marker）

---

### Week 8：座標轉換開發 II + Isaac Sim 整合

#### 🎯 目標
完成世界座標轉換 + 部署 Isaac Sim 環境。

#### 📋 任務清單

**A. 本體座標 → 世界座標（tf2 整合）**
```python
# 在 coordinate_transformer 中新增
# 使用 tf2_ros.Buffer.transform() 將 base_link → map
from tf2_ros import Buffer, TransformListener
from geometry_msgs.msg import PoseStamped

# 轉換邏輯
body_pose = PoseStamped()
body_pose.header.frame_id = "base_link"
body_pose.pose.position = detected_3d_point

world_pose = tf_buffer.transform(body_pose, "map", timeout=Duration(seconds=1.0))
self.world_pose_pub.publish(world_pose)
```

**B. 發佈 Nav2 目標**
```python
# 新增發佈器
self.goal_pub = self.create_publisher(PoseStamped, '/goal_pose', 10)
self.goal_pub.publish(world_pose)
```

**C. Isaac Sim 部署（詳見 isaac_sim_integration.md）**
```bash
# 1. 安裝 Isaac Sim 2023.1.1（Docker 推薦）
docker pull nvcr.io/nvidia/isaac-sim:2023.1.1

# 2. 安裝 Orbit 0.3.0
git clone https://github.com/isaac-sim/IsaacLab.git --branch v0.3.1
cd IsaacLab
export ISAACSIM_PATH="${HOME}/.local/share/ov/pkg/isaac-sim-2023.1.1"
./orbit.sh --conda
./orbit.sh --install --extra rsl_rl

# 3. 整合 go2_omniverse
git clone https://github.com/abizovnuralem/go2_omniverse --recurse-submodules
# 複製配置文件（Unitree_L1.json, material_files）
./run_sim.sh  # 驗證啟動
```

**D. ROS2 橋接驗證**
```bash
# 在模擬器運行時，檢查 topic
ros2 topic list | grep -E "(camera|scan|cmd_vel)"
ros2 topic hz camera/image_raw point_cloud2

# 啟動 SLAM/Nav2
export ROBOT_IP="sim"  # 特殊標記使用模擬器
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true
```

#### 📊 週末驗收標準
- ✅ 座標轉換完整鏈路通暢（2D → 3D → world）
- ✅ Isaac Sim 正常運行（WASD 控制）
- ✅ 在模擬器中完成一次 SLAM 建圖

---

### Week 9：尋物 FSM 端到端整合

#### 🎯 目標
實現完整尋物流程，在 Isaac Sim 驗證成功。

#### 📋 任務清單

**A. 尋物狀態機開發**
```bash
ros2 pkg create --build-type ament_python search_logic \
  --dependencies rclpy nav2_msgs action_msgs
```

**狀態轉移邏輯**：
```python
class SearchState(Enum):
    IDLE = 0       # 等待指令
    PATROL = 1     # 巡邏掃描
    SCAN = 2       # 檢測物體
    NAVIGATE = 3   # 導航到目標
    SUCCESS = 4    # 成功找到
    FAILED = 5     # 失敗重試

# 核心邏輯
def state_machine(self):
    if self.state == SearchState.IDLE:
        # 等待 /search_command (String)
        pass
    elif self.state == SearchState.PATROL:
        # 發送巡邏路徑點給 Nav2
        self.send_nav2_goal(patrol_points[self.patrol_idx])
    elif self.state == SearchState.SCAN:
        # 訂閱 /detected_objects，檢查是否有目標物
        if target_found:
            self.state = SearchState.NAVIGATE
    # ... 其他狀態
```

**B. Nav2 Action Client 整合**
```python
from nav2_msgs.action import NavigateToPose
from rclpy.action import ActionClient

self.nav_client = ActionClient(self, NavigateToPose, 'navigate_to_pose')
goal_msg = NavigateToPose.Goal()
goal_msg.pose = world_pose
self.nav_client.send_goal_async(goal_msg)
```

**C. 端到端測試（Isaac Sim）**
1. 場景設定：在辦公室環境放置目標物（如紅色杯子模擬眼鏡）
2. 啟動完整系統：
   ```bash
   # Terminal 1: 啟動模擬器
   cd go2_omniverse && ./run_sim.sh

   # Terminal 2: 啟動 ROS2 系統
   ros2 launch go2_robot_sdk robot.launch.py \
     slam:=true nav2:=true vlm:=true search:=true

   # Terminal 3: 發送尋物指令
   ros2 topic pub /search_command std_msgs/String "data: '找杯子'"
   ```

3. 觀察流程：
   - [ ] 機器狗開始巡邏
   - [ ] VLM 識別到目標物
   - [ ] 座標轉換發佈世界座標
   - [ ] Nav2 導航到目標位置
   - [ ] 狀態機轉為 SUCCESS

**D. 成功率測試**
- 重複測試 20 次，記錄：
  - VLM 識別成功率
  - 座標轉換誤差分佈
  - Nav2 導航成功率
  - 端到端成功率

#### 📊 週末驗收標準
- ✅ 完整尋物流程至少成功 1 次（Demo 級別）
- ✅ 端到端成功率 > 60%（20 次測試）
- ✅ 記錄完整測試數據（供期末報告使用）

---

## 🛠️ 技術整合要點

### 1. Topic 命名規範
所有新節點遵循現有專案的命名空間規則：

```yaml
# 單機模式（相對路徑）
camera/image_raw
point_cloud2
/detected_objects      # VLM 輸出（全局）
/object_pose_world     # 座標轉換輸出（全局）
/search_command        # 尋物指令（全局）

# 多機模式（自動添加前綴）
robot1/camera/image_raw
robot1/point_cloud2
/detected_objects      # 仍為全局
```

### 2. 參數管理
所有參數統一放置於 `config/` 目錄：

```yaml
# config/vision_vlm_params.yaml
gemini_vlm:
  ros__parameters:
    api_key: "${GEMINI_API_KEY}"
    detection_threshold: 0.7
    max_objects: 5
    publish_rate: 2.0  # Hz

# config/coordinate_transformer_params.yaml
coordinate_transformer:
  ros__parameters:
    method: "lidar_projection"  # or "ground_assumption"
    point_cloud_timeout: 0.5
    min_depth: 0.3
    max_depth: 10.0
```

### 3. Launch 文件整合
修改 `robot.launch.py` 添加新節點：

```python
# 在 Go2NodeFactory 中新增
if self.config.enable_vlm:
    nodes.append(Node(
        package='vision_vlm',
        executable='gemini_vlm_node',
        parameters=[config_dir / 'vision_vlm_params.yaml']
    ))

if self.config.enable_search:
    nodes.append(Node(
        package='search_logic',
        executable='search_fsm_node',
        parameters=[config_dir / 'search_params.yaml']
    ))
```

### 4. 依賴管理
所有新套件的 `package.xml` 必須聲明依賴：

```xml
<depend>rclpy</depend>
<depend>sensor_msgs</depend>
<depend>geometry_msgs</depend>
<depend>vision_msgs</depend>
<depend>nav2_msgs</depend>
<depend>tf2_ros</depend>
<depend>cv_bridge</depend>
```

---

## 🔧 開發工具與最佳實踐

### 1. 調試工具
```bash
# 監控 topic 流量
ros2 topic hz /detected_objects
ros2 topic echo /object_pose_world

# 檢查 TF 樹
ros2 run tf2_tools view_frames
evince frames.pdf

# RViz 可視化
# 新增 Marker 顯示 VLM 檢測框
# 新增 PoseStamped 顯示轉換結果
```

### 2. 日誌管理
使用 ROS2 標準日誌系統：

```python
self.get_logger().info(f"VLM detected: {object_name} at pixel [{u}, {v}]")
self.get_logger().warn(f"Coordinate transform timeout, using last known pose")
self.get_logger().error(f"Nav2 navigation failed: {error_msg}")
```

### 3. 單元測試
每個新節點都應有基本測試：

```bash
# vision_vlm/test/test_gemini_api.py
# coordinate_transformer/test/test_projection.py
# search_logic/test/test_state_machine.py

# 執行測試
colcon test --packages-select vision_vlm
colcon test-result --verbose
```

---

## 📊 風險管理與應變

### 風險矩陣（根據 2025/11/19 會議決議更新）

| 風險 | 影響 | 機率 | Plan A（主力） | Plan B（備案） | Plan C（最後手段） |
|------|------|------|----------------|----------------|-------------------|
| **COCO 本地推論不準確** | 🔴 高 | 低 | 調整 confidence threshold | Gemini API 補充 | 預錄結果 Demo |
| **Gemini API 審核失敗** | 🟡 中 | 中 | 使用 COCO 已足夠 | OpenAI Vision API | Claude Vision API |
| 座標轉換誤差大 | 🔴 高 | 中 | LiDAR 投影優化 | 地面假設 + 多點平均 | 人工標註 Demo |
| Isaac Sim 安裝失敗 | 🟡 中 | 低 | Docker 部署 | 實機測試 | 純影片展示 |
| Nav2 導航卡住 | 🟡 中 | 中 | 調整參數（inflation） | 超時重試 | 手動遙控 |
| **12/17 發表準備不足** | 🔴 高 | 中 | 優先實機 Demo | 模擬器影片 | 基礎動作展示 |

### 每週風險檢查
- W6 結束：環境是否完全就緒？
- W7 結束：座標轉換誤差是否可接受？
- W8 結束：Isaac Sim 是否能穩定運行？
- W9 結束：端到端成功率是否達標？

---

## 📚 相關文件索引

### VLM 方案文件（優先級排序）
- **[COCO VLM 開發指南](./coco_vlm_development.md)** - Plan A 主力方案
- [Gemini VLM 開發指南](./gemini_vlm_backup.md) - Plan B 備案方案

### 核心技術文件
- [座標轉換系統設計](./coordinate_transformation.md)
- [尋物 FSM 設計文件](./search_fsm_design.md)
- [Isaac Sim 整合指南](./isaac_sim_integration.md)
- [套件結構規劃](./package_structure.md)

### 測試與驗收文件
- [測試計畫](./testing_plan.md)
- [快速啟動指南](../01-guides/quickstart_w6_w9.md)
- [12/17 發表準備清單](./presentation_1217_plan.md)（待建立）

---

## 📞 聯絡與協作

- **技術問題回報**：建立 GitHub Issue（標籤：bug/question）
- **程式碼審查**：Pull Request 至 `develop` 分支
- **每週進度會議**：週五下午 3:00（RViz Demo + 問題討論）

---

**最後更新：** 2025/11/20（根據 2025/11/19 會議決議更新）
**下次審查日期：** W6 結束（週末）
**重大變更**：
- VLM 方案從 Gemini (Plan A) 調整為 COCO (Plan A)
- 新增 12/17 發表時程標註
- 所有 `pip install` 改為 `uv pip install`
