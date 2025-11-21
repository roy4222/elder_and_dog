# Go2 機器狗智慧尋物系統 — 合併版現況與計畫對照報告

報告日期：2025/11/16  
> 註記：原報告日期 2025/11/16，已於 2025/11/19 會議決議後復核內容（55% 完成度評估仍適用）  
分析範圍：[`Goal.md`](./Goal.md) 目標 vs. 專案實際實現（整合自 `claude_plan.md`、`SLAM_實現現況報告.md`）  
專案路徑：`/mnt/c/Users/User/Desktop/fju-go2-sdk`

---

## 1. 執行摘要

| 評估項目 | 完成度 | 說明 |
| --- | --- | --- |
| 基礎設施（ROS2、SDK、Clean Architecture） | 95%（程式） / 0%（環境） | 程式齊備、多機連線就緒；本機尚未安裝 ROS2 |
| 自主導航（SLAM + Nav2） | 100% | `slam_toolbox` + `nav2` 已在 launch 內整合 |
| 感測器整合（LiDAR/Camera/IMU） | 95% | 發佈/訂閱鏈路完整，部分 topic 需 remap |
| 視覺智慧（VLM + 座標轉換） | 15% | 僅有 camera_info / TF 基礎，核心節點未寫 |
| 尋物邏輯狀態機 | 0% | 未實作 |
| 模擬環境（Isaac Sim） | 0% | 專案中無相關檔案 |
| 使用者介面 | 30% | 只有 Foxglove Bridge，無自訂 Web UI |
| **總體完成度** | **約 55%** | W1–W5 基礎完備，W6–W9 核心待開發 |

**已完成亮點**
- Clean Architecture、單/多機模式、WebRTC/CycloneDDS 連線、相機內參（720p/1080p）。
- SLAM/Nav2 可即時使用；LiDAR 處理優化後約 7 Hz（較舊版 2 Hz）。

**主要缺口 / 風險**
- ROS2 未安裝；pip 因網路問題無法裝 requirements（需先解決 DNS/Proxy）。
- Gemini VLM、座標轉換節點、尋物 FSM、Isaac Sim、自訂 Web UI 均為 0%。
- COCO 節點訂閱絕對 `/camera/image_raw`，需 remap；SLAM `scan_topic` 設 `/scan`（絕對）與實際 `scan`（相對、多機前綴）需確認。
- 深度來源不明（Go2 無深度相機）；需設計 LiDAR 投影/地面假設。

---

## 2. 技術對照（[Goal.md](./Goal.md) vs 現況）

| 項目 | 目標 | 現況 | 備註 |
| --- | --- | --- | --- |
| OS/ROS | Ubuntu 22.04 + ROS2 Humble | ✅ 支援 humble/iron/rolling（但本機未裝 ROS2） | 需先安裝 |
| 機器狗 | Unitree Go2 | ✅ 支援 AIR/PRO/EDU | — |
| SLAM | slam_toolbox | ✅ `mapper_params_online_async.yaml` | launch include |
| 導航 | Nav2 | ✅ `nav2_params.yaml` | launch include |
| 模擬 | Isaac Sim | ❌ 無 | 需自行安裝 |
| 視覺 | Gemini VLM | ❌ 無（有 COCO 替代） | 自建節點 |
| 座標轉換 | 影像→世界 | ⚠️ 基礎（camera_info/TF） | 無節點 |
| 尋物邏輯 | FSM | ❌ 無 | 自建 |
| Web UI | 自訂前端 | ⚠️ 只有 Foxglove | 若要 UI 需另開發 |

---

## 3. 現有套件與功能

- **go2_robot_sdk**（主驅動，Python Clean Architecture）  
  - 主節點：`presentation/go2_driver_node.py`（發佈 `joint_states/imu/odom/camera/image_raw/point_cloud2`，訂閱 `cmd_vel`；TF odom→base_link 有 +0.07m z 補償）。  
  - 基礎：`infrastructure/ros2/ros2_publisher.py`、`sensors/camera_config.py`、連線模式 `ROBOT_IP`/`CONN_TYPE` 自動判斷單/多機。  

- **lidar_processor**（Python）  
  - 節點：`lidar_to_pointcloud_node.py`、`pointcloud_aggregator_node.py`。  
  - 參數（在 `robot.launch.py`）：max_range 20.0 / min_range 0.1 / height_filter -2~3 / downsample_rate 5 / publish_rate 10Hz；`pointcloud_to_laserscan` max_height 單機 0.5 / 多機 0.1。  

- **lidar_processor_cpp**（C++ 高效版）：PCL 實作替代。  

- **coco_detector**：FasterRCNN MobileNet V3，80 類；訂閱絕對 `/camera/image_raw`（需 remap），發布 `/detected_objects`、`/annotated_image`。  

- **speech_processor**：ElevenLabs TTS（需 `ELEVENLABS_API_KEY`）。  

- **go2_interfaces**：20+ 自訂訊息。  

- **啟動/配置**  
  - Launch：`go2_robot_sdk/launch/robot.launch.py`（一鍵：驅動、LiDAR、Teleop、Foxglove、SLAM、Nav2、RViz）。  
  - RViz：`config/single_robot_conf.rviz`、`multi_robot_conf.rviz`、`cyclonedds_config.rviz`。  
  - SLAM：`config/mapper_params_online_async.yaml`；Nav2：`config/nav2_params.yaml`；相機內參：`calibration/front_camera_720.yaml`、`front_camera_1080.yaml`。  
  - Topic：預設相對路徑（無 `/`），多機前綴 `robot{i}/`；`/map`/`/map_metadata` 為絕對。  

---

## 4. 主要參數快覽

- **SLAM（mapper_params_online_async.yaml）**  
  - `scan_topic: /scan`（絕對，若吃不到需 remap 到 `scan` / `robot{i}/scan`）  
  - `mode: mapping`、`resolution: 0.05`、`minimum_travel_distance: 0.5`、`do_loop_closing: true`

- **Nav2（nav2_params.yaml）**  
  - `controller_frequency: 3.0` Hz、`max_vel_x: 3.0 m/s`、`max_vel_theta: 3.0 rad/s`  
  - `xy_goal_tolerance: 0.25`（Goal Checker）、`xy_goal_tolerance: 0.3`（DWB）  
  - `inflation_radius: 0.25`、`obstacle_max_range: 2.5`、`tolerance: 3.0`

- **LiDAR 處理（launch 內）**  
  - `max_range: 20.0`、`min_range: 0.1`、`height_filter_min: -2.0`、`height_filter_max: 3.0`  
  - `downsample_rate: 5`、`publish_rate: 10.0`  

---

## 5. 啟動與驗證（含 SLAM 現況）

**前置**：需先安裝 ROS2（Humble/iron），修好網路後安裝 requirements。  

**標準啟動**（單機範例）：
```bash
export ROBOT_IP="192.168.x.x"
export CONN_TYPE="webrtc"   # 或 cyclonedds
source /opt/ros/humble/setup.bash
colcon build
source install/setup.bash
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true foxglove:=true
```

**檢查/驗證**：
```bash
ros2 topic list | grep -E "(scan|camera|imu|odom|map|cmd_vel)"
ros2 topic hz camera/image_raw point_cloud2 scan
ros2 run tf2_tools view_frames
```

**SLAM/導航 Demo**：
1. RViz → 2D Pose Estimate，手動遙控巡航建圖。  
2. SlamToolboxPlugin → Save/Serialize Map；或 `map_saver_cli -f ~/my_map`（在 nav2 map_server 環境下）。  
3. 載入地圖後 Nav2：設定 initial pose → 2D Nav Goal。  
4. Foxglove：`ws://<host>:8765` 監看。

**COCO 偵測（需 remap）**：
```bash
ros2 run coco_detector coco_detector_node --ros-args \
  -r /camera/image_raw:=camera/image_raw \
  -p device:=cuda
```

---

## 6. 類別/Topic/流程示意

- Topic 流：`camera/image_raw`、`point_cloud2` → `scan` → `slam_toolbox`→ `/map`；`scan` → Nav2 → `cmd_vel`；Foxglove 監看影像/scan/map。  
- TF：`map → odom → base_link`（odom→base_link 有 +0.07m z），其餘關節/相機由 robot_state_publisher 發布。

---

## 7. 未完成與待補強

- 安裝 ROS2、修復 pip 下載（DNS/Proxy）。  
- VLM（Gemini）節點：影像→API→Detection2DArray。  
- 座標轉換節點：影像像素 + 深度/點雲 + camera_info + TF → 世界座標 → Nav2 目標。  
- 尋物 FSM：巡邏→掃描→導航→成功/失敗。  
- Isaac Sim 整合：安裝、ROS bridge。  
- Web UI：若需自訂，需新前端。  
- Topic 修正：COCO 訂閱絕對路徑、SLAM `scan_topic` 絕對路徑，啟動時 remap。

---

## 8. 風險與應變

| 風險 | 影響 | 應變 |
| --- | --- | --- |
| ROS2/依賴安裝受阻 | 高 | 先解決網路，必要時用 Docker/離線套件 |
| 深度/座標轉換誤差 | 高 | 先用地面假設/多點平均，後續做 LiDAR 投影與同步 |
| VLM API 延遲/額度 | 中 | 快取、降頻，失敗降級 COCO 或預錄結果 |
| Topic/命名空間錯置 | 中 | 啟動時統一 remap，相對/多機前綴確定後寫入 launch |

---

## 9. 接下來 4 週行動建議（W6–W9 對應）

1) 安裝 ROS2 + 修網路，完整編譯與跑通標準啟動。  
2) 開發 VLM 節點（Gemini API 包裝，輸出 Detection2D Array）。  
3) 開發座標轉換節點（影像/點雲同步 + camera_info + TF → PoseStamped）。  
4) 開發尋物 FSM（巡邏→掃描→導航），並用 Nav2 action 客戶端送目標。  
5) 視需要開始 Isaac Sim 橋接，或留作備援 Demo。  
6) 若要 Web UI，在 Foxglove WS 基礎上開發前端（影像、BBox、地圖、導航狀態）。

---

## 10. 疑問/待確認項

- ROS2 版本與安裝方式：是否採用 Humble？需不需要 Docker 化？  
- 網路環境：WSL 的 DNS/Proxy 能否開通，以便 pip/apt？  
- 深度來源策略：可接受地面假設先行，還是要 LiDAR 投影精準版？  
- VLM API：Gemini 帳號/額度是否已申請？  
- 是否需要自訂 Web UI，或直接用 Foxglove 即可？
