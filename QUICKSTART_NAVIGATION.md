# 快速開始：導航功能測試（方案 A）

**目標：** 快速測試 Nav2 導航功能，不依賴 VLM 或座標轉換
**預估時間：** 半天到一天
**狀態：** ✅ 已完成套件建立

---

## 📦 已建立的套件

```
src/search_logic/
├── search_logic/
│   ├── __init__.py
│   ├── nav2_client.py          ✅ Nav2 Action Client 封裝
│   └── simple_patrol_node.py   ✅ 簡單巡邏節點
├── config/
│   └── patrol_params.yaml       ✅ 巡邏參數配置
├── resource/
│   └── search_logic
├── package.xml                  ✅ 套件依賴定義
├── setup.py                     ✅ Python 套件設定
├── setup.cfg                    ✅ 安裝配置
└── README.md                    ✅ 完整使用文件
```

---

## 🚀 三步開始測試

### Step 1: 編譯套件

```bash
cd ~/ros2_ws
colcon build --packages-select search_logic
source install/setup.bash
```

**預期輸出：**
```
Starting >>> search_logic
Finished <<< search_logic [1.23s]

Summary: 1 package finished [1.45s]
```

---

### Step 2: 啟動系統

#### Terminal 1: 啟動 Go2 + Nav2

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
source "$HOME/.local/bin/env"    # 如果使用 uv
source .venv/bin/activate        # 如果使用虛擬環境
source install/setup.bash

# 設定機器人 IP（必須！）
export ROBOT_IP="192.168.1.100"  # 替換成實際 IP
export CONN_TYPE="webrtc"

# 啟動系統
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=true
```

**等待看到：**
- RViz 視窗開啟
- 地圖顯示（SLAM 建圖）
- Nav2 服務啟動訊息

---

#### Terminal 2: 啟動巡邏節點

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

# 自動開始巡邏
ros2 run search_logic simple_patrol_node --ros-args -p auto_start:=true
```

**預期輸出：**
```
[INFO] [simple_patrol_node]: 等待 Nav2 服務啟動...
[INFO] [simple_patrol_node]: Nav2 服務已就緒
[INFO] [simple_patrol_node]: 簡單巡邏節點已啟動
[INFO] [simple_patrol_node]: 巡邏點數量: 4
[INFO] [simple_patrol_node]: 自動開始巡邏
[INFO] [simple_patrol_node]: 前往巡邏點 1/4: (2.00, 1.00)
[INFO] [simple_patrol_node]: 發送導航目標: (2.00, 1.00)
[INFO] [simple_patrol_node]: 導航目標已接受
```

---

### Step 3: 在 RViz 觀察

你應該能看到：
1. ✅ 機器狗模型在地圖上移動
2. ✅ 綠色的全局路徑（Global Plan）
3. ✅ 紅色的局部路徑（Local Plan）
4. ✅ 當前目標點標記

---

## ⚙️ 自訂巡邏點

### 方法 1：使用 RViz Publish Point 獲取座標

1. 在 RViz 上方工具列點擊 "Publish Point"
2. 在地圖上點擊你想設為巡邏點的位置
3. 在另一個 Terminal 查看座標：
   ```bash
   ros2 topic echo /clicked_point
   ```
4. 記下座標（例如 `x: 2.5, y: 1.8`）

### 方法 2：編輯配置檔案

打開 [src/search_logic/config/patrol_params.yaml](src/search_logic/config/patrol_params.yaml)：

```yaml
simple_patrol_node:
  ros__parameters:
    patrol_points: [
      [2.0, 1.0],    # 改成你的座標
      [4.0, 2.5],
      [1.5, 4.0],
      [3.5, 0.5]
    ]
```

儲存後重新啟動節點。

---

## 🎮 控制指令

如果啟動時沒有設定 `auto_start:=true`，可以用指令控制：

```bash
# 啟動巡邏
ros2 topic pub /patrol_command std_msgs/String "data: 'start'" --once

# 停止巡邏
ros2 topic pub /patrol_command std_msgs/String "data: 'stop'" --once

# 重置進度
ros2 topic pub /patrol_command std_msgs/String "data: 'reset'" --once
```

---

## 📊 監控狀態

```bash
# 查看巡邏狀態
ros2 topic echo /patrol_status

# 查看 Nav2 導航進度
ros2 topic echo /navigate_to_pose/_action/feedback
```

---

## 🐛 常見問題

### Q1: 出現 "Nav2 服務未啟動" 錯誤

**解決方法：**
```bash
# 確認 Terminal 1 已啟動 Nav2
ros2 action list | grep navigate_to_pose

# 應該要看到：
# /navigate_to_pose
```

如果沒有，重新執行 Terminal 1 的指令，確保 `nav2:=true`。

---

### Q2: 機器狗不移動

**檢查清單：**
1. ✅ 確認 `ROBOT_IP` 已設定（`echo $ROBOT_IP`）
2. ✅ 確認 SLAM 有建立地圖（RViz 中看到地圖）
3. ✅ 嘗試用 RViz 的 "Nav2 Goal" 手動測試導航
4. ✅ 確認巡邏點座標在地圖範圍內

---

### Q3: import 錯誤

```bash
# 重新編譯並 source
cd ~/ros2_ws
colcon build --packages-select search_logic
source install/setup.bash
```

---

## 📈 驗收標準

完成測試後，你應該能：

✅ 機器狗自動訪問 3-5 個預設巡邏點
✅ 在 RViz 中看到清晰的導航路徑
✅ Terminal 顯示正確的導航狀態訊息
✅ 理解如何修改巡邏點座標
✅ 知道如何用指令控制巡邏行為

---

## 🔄 下一步

### 選項 A：繼續測試導航

- 新增更多巡邏點
- 測試不同地圖環境
- 調整 Nav2 參數（速度、避障等）

### 選項 B：升級為完整尋物系統

按照以下順序補充功能：
1. **W6**: 建立 `vision_vlm` 套件（物體識別）
2. **W7-W8**: 建立 `coordinate_transformer` 套件（座標轉換）
3. **W9**: 將 `simple_patrol_node.py` 升級為 `search_fsm_node.py`

詳見：[docs/quickstart_w6_w9.md](docs/quickstart_w6_w9.md)

---

## 📚 詳細文件

- **完整使用指南**：[src/search_logic/README.md](src/search_logic/README.md)
- **環境配置**：[docs/environment_setup_ubuntu.md](docs/environment_setup_ubuntu.md)
- **尋物 FSM 設計**：[docs/search_fsm_design.md](docs/search_fsm_design.md)

---

## ✅ 檢查清單

開始測試前請確認：

- [ ] 已完成 `environment_setup_ubuntu.md` 的環境配置
- [ ] 已成功編譯 `go2_robot_sdk`
- [ ] 已知道機器狗的 IP 位址
- [ ] 已成功編譯 `search_logic`
- [ ] 已開啟兩個 Terminal 準備測試

開始測試！🚀

---

**建立日期：** 2025-11-17
**版本：** v0.1.0
**維護者：** FJU Go2 Team
