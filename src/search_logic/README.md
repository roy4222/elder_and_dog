# Search Logic - 簡單巡邏與導航測試套件

**版本：** v0.1.0
**用途：** 快速測試 Nav2 導航功能，不依賴 VLM 或座標轉換
**開發階段：** 方案 A - 純導航測試

---

## 📋 功能概述

這個套件提供：
- ✅ Nav2 Action Client 封裝（`nav2_client.py`）
- ✅ 簡單巡邏節點（`simple_patrol_node.py`）
- ✅ 固定路徑點巡邏功能
- ✅ 循環巡邏支援
- ✅ 導航成功/失敗監控

**不包含：**
- ❌ VLM 物體識別
- ❌ 座標轉換
- ❌ 複雜狀態機（SCANNING, APPROACHING）

---

## 🛠️ 編譯與安裝

### 步驟 1：編譯套件

```bash
cd ~/ros2_ws
colcon build --packages-select search_logic
source install/setup.bash
```

### 步驟 2：驗證安裝

```bash
# 檢查套件是否被 ROS2 識別
ros2 pkg list | grep search_logic

# 檢查節點是否可執行
ros2 run search_logic simple_patrol_node --help
```

---

## 🚀 使用方法

> **說明：** 本套件提供單一節點 `simple_patrol_node`，以下是三種不同的**操作模式**（非三個不同節點）。

### 方法 A：自動開始巡邏（推薦用於測試）

#### Terminal 1: 啟動 Go2 + Nav2 系統

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
source "$HOME/.local/bin/env"  # 如果使用 uv
source .venv/bin/activate      # 如果使用虛擬環境
source install/setup.bash

# 設定機器人 IP（必須！）
export ROBOT_IP="192.168.1.100"  # 替換成實際 IP
export CONN_TYPE="webrtc"         # 或 "cyclonedds"

# 啟動系統
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=true
```

#### Terminal 2: 啟動巡邏節點（自動模式）

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

# 啟動節點並自動開始巡邏
ros2 run search_logic simple_patrol_node --ros-args -p auto_start:=true
```

---

### 方法 A-2：使用 Launch 檔案（推薦）

#### Terminal 2: 使用 Launch 檔案啟動

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

# 使用 launch 檔案啟動（自動開始巡邏）
ros2 launch search_logic patrol.launch.py auto_start:=true

# 或使用手動模式
ros2 launch search_logic patrol.launch.py auto_start:=false loop_patrol:=true
```

---

### 方法 B：手動控制巡邏

#### Terminal 2: 啟動巡邏節點（手動模式）

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

# 啟動節點但不自動開始
ros2 run search_logic simple_patrol_node
```

#### Terminal 3: 發送控制指令

```bash
# 啟動巡邏
ros2 topic pub /patrol_command std_msgs/String "data: 'start'" --once

# 停止巡邏
ros2 topic pub /patrol_command std_msgs/String "data: 'stop'" --once

# 重置進度（從第一個點重新開始）
ros2 topic pub /patrol_command std_msgs/String "data: 'reset'" --once
```

---

### 方法 C：使用配置檔案

#### Terminal 2: 使用自訂參數啟動

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

# 使用配置檔案
ros2 run search_logic simple_patrol_node --ros-args \
  --params-file src/search_logic/config/patrol_params.yaml
```

---

## ⚙️ 參數配置

### 編輯配置檔案

打開 `config/patrol_params.yaml` 修改參數：

```yaml
simple_patrol_node:
  ros__parameters:
    # 巡邏路徑點（map 座標系）
    patrol_points: [
      [2.0, 1.0],    # 巡邏點 1
      [4.0, 2.5],    # 巡邏點 2
      [1.5, 4.0],    # 巡邏點 3
      [3.5, 0.5]     # 巡邏點 4
    ]

    # 循環巡邏（true: 重複巡邏，false: 巡邏一次後停止）
    loop_patrol: true

    # 自動開始（true: 節點啟動後立即開始）
    auto_start: false
```

### 如何獲取正確的巡邏點座標？

#### 方法 1：使用 RViz 的 Publish Point 工具

1. 在 RViz 中點擊上方工具列的 "Publish Point"
2. 在地圖上點擊你想設為巡邏點的位置
3. 在 Terminal 查看輸出的座標：
   ```bash
   ros2 topic echo /clicked_point
   ```
4. 將座標複製到 `patrol_params.yaml`

#### 方法 2：在 RViz 中使用 Nav2 Goal 手動測試

1. 使用 "Nav2 Goal" 工具在地圖上點擊目標點
2. 觀察機器狗是否能成功導航到該點
3. 如果可以，記下該座標並加入 `patrol_params.yaml`

---

## 📊 監控與調試

### 查看巡邏狀態

```bash
# 監控巡邏狀態訊息
ros2 topic echo /patrol_status

# 查看所有 topic
ros2 topic list

# 查看 Nav2 導航狀態
ros2 topic echo /navigate_to_pose/_action/status
```

### 查看節點日誌

節點的所有訊息會直接輸出到啟動節點的 Terminal，包括：
- Nav2 服務連接狀態
- 當前巡邏進度
- 導航成功/失敗訊息

### 在 RViz 中觀察

確保 RViz 中啟用以下顯示：
- **Map**：SLAM 建立的地圖
- **RobotModel**：機器狗模型
- **Global Costmap**：全局代價地圖
- **Local Costmap**：局部代價地圖
- **Global Plan**：全局路徑（綠色線）
- **Local Plan**：局部路徑（紅色線）
- **Goal Pose**：當前導航目標點

---

## 🐛 常見問題排查

### 問題 1：Nav2 服務未啟動

**錯誤訊息：**
```
Nav2 服務未啟動！請確認已啟動 nav2_bringup
```

**解決方法：**
```bash
# 確認已在 Terminal 1 啟動 Nav2
ros2 launch go2_robot_sdk robot.launch.py nav2:=true

# 檢查 Nav2 服務是否運行
ros2 action list | grep navigate_to_pose
```

---

### 問題 2：機器狗不移動

**可能原因：**
1. 未正確設定 `ROBOT_IP`
2. SLAM 未建立地圖
3. 巡邏點座標超出地圖範圍

**排查步驟：**
```bash
# 1. 檢查 ROBOT_IP 是否設定
echo $ROBOT_IP

# 2. 檢查地圖是否存在
ros2 topic echo /map --once

# 3. 在 RViz 手動使用 Nav2 Goal 測試
# 如果手動也無法導航，問題在 Nav2 配置而非本套件
```

---

### 問題 3：導航失敗（無法到達某些點）

**錯誤訊息：**
```
導航失敗，無法到達巡邏點 X
```

**可能原因：**
- 巡邏點被障礙物阻擋
- 巡邏點在地圖外
- Nav2 路徑規劃超時

**解決方法：**
1. 在 RViz 中檢查該巡邏點是否可達（沒有障礙物）
2. 調整巡邏點座標到開闊區域
3. 增加 Nav2 的超時時間（修改 `nav2_params.yaml`）

---

### 問題 4：import 錯誤

**錯誤訊息：**
```
ModuleNotFoundError: No module named 'search_logic'
```

**解決方法：**
```bash
# 重新編譯並 source
cd ~/ros2_ws
colcon build --packages-select search_logic
source install/setup.bash
```

---

## 📈 效能指標

測試時可記錄以下指標：

| 指標 | 建議目標 | 實際值 |
|------|---------|--------|
| **導航成功率** | > 90% | _____ |
| **平均到達一個點的時間** | < 30 秒 | _____ |
| **完整巡邏一輪時間** | < 3 分鐘 | _____ |

---

## 🔄 未來擴充

### 升級為完整尋物系統

完成測試後，可以擴充為完整的尋物 FSM（search_fsm_design.md）：

1. **新增 VLM 支援**
   - 訂閱 `/detected_objects`
   - 新增 SCANNING 狀態

2. **新增座標轉換**
   - 訂閱 `/object_pose_world`
   - 新增 NAVIGATING (to object) 狀態

3. **新增精細調整**
   - 新增 APPROACHING 狀態
   - 新增 SUCCESS/FAILED 狀態

**重用率：** 目前的 `nav2_client.py` 和巡邏邏輯可以直接重用 90%！

---

## 🧪 自動化測試

### 執行 pytest 測試

```bash
cd ~/ros2_ws
source install/setup.bash

# 執行所有測試
colcon test --packages-select search_logic

# 查看測試結果
colcon test-result --verbose

# 或直接執行 pytest
python3 src/search_logic/test/test_import.py
```

### 測試內容

本套件包含以下 pytest 測試：
- ✅ ROS2 核心 imports 測試
- ✅ 訊息類型 imports 測試
- ✅ 套件本身 imports 測試
- ✅ Nav2Client 類別結構測試
- ✅ PatrolState 枚舉測試
- ✅ SimplePatrolNode 類別結構測試

**預期輸出：**
```
test_import.py::test_rclpy_imports PASSED
test_import.py::test_message_imports PASSED
test_import.py::test_search_logic_imports PASSED
test_import.py::test_nav2_client_class PASSED
test_import.py::test_patrol_state_enum PASSED
test_import.py::test_simple_patrol_node_class PASSED

====== 6 passed in 0.25s ======
```

---

## 📝 測試記錄範例

```
測試日期：2025-11-XX
測試環境：實機 / Isaac Sim
巡邏點數量：4 個
循環次數：3 次

結果：
- 巡邏點 1: ✅ 成功（25 秒）
- 巡邏點 2: ✅ 成功（30 秒）
- 巡邏點 3: ❌ 失敗（障礙物阻擋）
- 巡邏點 4: ✅ 成功（20 秒）

成功率：75% (3/4)
總時長：2 分鐘 15 秒

改進建議：
- 調整巡邏點 3 座標，避開障礙物
```

---

## 📞 問題回報

遇到問題請提供以下資訊：
1. 錯誤訊息（完整的 Terminal 輸出）
2. 使用的指令
3. `patrol_params.yaml` 內容
4. ROS2 環境資訊（`ros2 doctor --report`）

---

**維護者：** FJU Go2 Team
**最後更新：** 2025-11-17
**版本：** v0.1.0
