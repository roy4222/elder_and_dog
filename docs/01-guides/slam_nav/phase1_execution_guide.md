# Phase 1 執行指南書 - SLAM + Nav2 小空間驗證

**日期：** 2025/11/21
**目標：** 驗證 SLAM + Nav2 基本通訊與流程（1-2 坪小空間）
**總耗時：** 約 30-40 分鐘
**預期成果：** 確認系統能運作，為 Phase 2 大空間測試做準備

---

## 🚀 快速開始 - 複製貼上版本

如果你趕時間，就按照這個順序執行各個 Terminal 指令。

### Terminal 1：啟動驅動
```bash
cd /home/roy422/elder_and_dog
bash start_go2_simple.sh
# 等待看到：[INFO] [go2_driver_node-3]: Video frame received for robot 0
# 若沒看到，檢查機器狗電源與 WiFi 連接
```

### Terminal 2：ROS2 環境 + 頻寬監控
```bash
# 先設定環境
source /opt/ros/humble/setup.bash
cd /home/roy422/elder_and_dog
source install/setup.bash
export ROBOT_IP="192.168.12.1"

# 監控頻寬（這個要一直開著）
ros2 topic hz /scan
# 應顯示 "average rate: 7.XX hz"
# 如果 < 5 Hz，代表頻寬有問題（見下方故障排查）
```

### Terminal 3：啟動 SLAM + Nav2
```bash
export ROBOT_IP="192.168.12.1"
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=true

# 等待 RViz 開啟（可能需要 10-15 秒）
# RViz 開啟後立刻執行下一步
```

### 【關鍵】RViz 頻寬優化（RViz 開啟後立即執行）
```
1. 在 RViz 左側 Displays 清單中找到 "Image" 並取消勾選 (uncheck)
2. 在 RViz 左側 Displays 清單中找到 "PointCloud2" 並取消勾選
3. 確保以下還保留勾選：
   - Map ✓
   - TF ✓
   - RobotModel ✓
   - Costmap... (if visible) ✓

說明：Camera 影像和 PointCloud 會耗盡 WiFi，導致 SLAM 掃描頻率崩潰
```

### Terminal 2（分離視窗）：驗證頻寬恢復
```bash
# 關閉前一個 "ros2 topic hz /scan"，重新執行
ros2 topic hz /scan
# 應恢復到 > 5 Hz（通常 6-7 Hz）
# 如果仍 < 5 Hz，見故障排查「頻寬耗盡」
```

### Terminal 4：建圖操作
```bash
# 在 RViz 中操作：
# 1. 確認 Fixed Frame = "map"（左上角 Fixed Frame 下拉選單）
# 2. 尋找 SlamToolboxPlugin（RViz 右上方可能有、或 Displays 清單中）
# 3. 點擊 "Start At Dock" 按鈕

# 之後執行移動命令
bash TEST.sh forward    # 機器狗前進 3 秒
sleep 1
bash TEST.sh left       # 機器狗左轉 3 秒
sleep 1
bash TEST.sh forward    # 再前進 3 秒

# 觀察 RViz 的地圖視窗
# 應看到白色和黑色網格逐漸填充（白=開放，黑=牆壁或機器狗掃過的邊界）
```

### Terminal 2（分離視窗）：驗證地圖發佈
```bash
ros2 topic hz /map
# 應顯示 "average rate: 0.95 hz" （約 1 Hz）
# 若沒有，表示 SLAM 未正常運作
```

### Terminal 2（分離視窗）：驗證 TF 樹
```bash
ros2 run tf2_tools view_frames
# 會產生 frames.pdf，打開檢查：
# 應看到完整鏈路：map → odom → base_link
# 若有斷鏈，表示某處出問題
```

### Terminal 2（分離視窗）：儲存地圖
```bash
# 建立地圖目錄
mkdir -p /home/roy422/elder_and_dog/src/go2_robot_sdk/maps

# 儲存地圖
ros2 run nav2_map_server map_saver_cli -f /home/roy422/elder_and_dog/src/go2_robot_sdk/maps/phase1_test

# 應看到類似輸出：
# Saving map to /home/roy422/elder_and_dog/src/go2_robot_sdk/maps/phase1_test.*

# 驗證檔案
ls -lh /home/roy422/elder_and_dog/src/go2_robot_sdk/maps/phase1_test*
# 應列出：phase1_test.yaml 和 phase1_test.pgm
```

### 驗證 Nav2 Costmap 初始化
```bash
# RViz 中觀察：
# 1. 應看到機器狗周圍有彩色的「膨脹層」（Local Costmap）
# 2. 地圖周圍應有一層淡色邊框（Global Costmap）
# 如果沒有，等待 5-10 秒（Nav2 還在啟動），或重新啟動系統

# Terminal 2（分離視窗）確認節點：
ros2 node list | grep nav2
# 應看到：/amcl_node, /planner_server, /controller_server 等
```

### Terminal 2：測試單點導航
```bash
# RViz 操作：
# 1. 點擊 Navigation2 Plugin 的 "2D Goal" 按鈕（或叫 "Nav2 Goal"）
# 2. 在地圖上點擊距離機器狗 0.3-0.5 公尺的位置
# 3. 拖曳設定朝向（箭頭方向）
# 4. 釋放滑鼠

# 觀察：
# - 是否出現綠色路徑線
# - 機器狗是否開始自動移動
# - 機器狗是否到達目標位置並停止

# Terminal 2 監控導航進度
ros2 topic echo /amcl_pose --max-count 1
# 應看到機器狗的位置估計

# ✅ 自動化版本（不想在 RViz 拖箭頭時可改跑腳本）
python scripts/nav2_goal_autotest.py --distance 0.4
# 腳本流程：
# 1. 從 /amcl_pose 讀到目前位姿（務必先在 RViz 執行 2D Pose Estimate）
# 2. 計算沿著朝向前進 0.4 公尺的新位置
# 3. 透過 NavigateToPose action 送 Goal、等待結果並印出 SUCCEEDED/失敗原因
# 如需調整距離、等待逾時等，參數請執行 `python scripts/nav2_goal_autotest.py -h` 查看
```

---

## 📋 Phase 1 完整檢查清單

在你執行上述指令後，請核對以下檢查項：

```
□ Terminal 1: 驅動啟動，出現 "Video frame received"
□ Terminal 2: /scan 頻率 > 5 Hz（關閉 Image/PointCloud 後）
□ Terminal 3: RViz 開啟，Fixed Frame = "map"
□ RViz: 地圖視窗顯示網格並逐漸填充
□ Terminal 2: /map 頻率 ~1 Hz
□ Terminal 2: view_frames 確認 TF 鏈完整（map → odom → base_link）
□ Terminal 2: phase1_test.yaml 和 phase1_test.pgm 檔案存在
□ RViz: 看到 Local Costmap（機器狗周圍彩色層）和 Global Costmap（地圖周圍邊框）
□ RViz: "2D Goal" 導航成功，機器狗自動到達目標
```

**若所有項都打勾，恭喜！Phase 1 通過，可以進行 Phase 2。**

---

## 🔴 故障排查

### 問題 1：/scan 頻率低於 5 Hz（頻寬耗盡）

**症狀：**
- `ros2 topic hz /scan` 顯示 1-2 Hz 而非 7 Hz
- 地圖建不起來或建圖很慢
- RViz 非常卡頓

**解決方案：**
1. **RViz 關閉高頻寬顯示：**
   - Displays → 取消勾選 "Image"
   - Displays → 取消勾選 "PointCloud2"
   - Displays → 如果有 "DepthCloud" 也取消勾選

2. **確認 WiFi 訊號：**
   ```bash
   # Terminal 2：檢查 WiFi 強度
   iwconfig wlan0 | grep "Signal level"
   # 應 > -50 dBm（信號良好）
   ```

3. **若仍未改善，重啟系統：**
   ```bash
   # Terminal 3 按 Ctrl+C 停止 ros2 launch
   # Terminal 1 按 Ctrl+C 停止驅動
   # 等待 5 秒
   # 重新執行：驅動 → ROS2 → ros2 launch
   ```

---

### 問題 2：地圖沒有更新或為空白

**症狀：**
- RViz 的地圖視窗空白或無變化
- `/map` 頻率為 0 Hz

**原因與解決：**

| 原因 | 檢查步驟 | 解決方案 |
|------|--------|--------|
| SLAM 未啟動 | `ros2 node list \| grep slam` | 重新執行 `ros2 launch` 時確保 `slam:=true` |
| /scan 無輸入 | `ros2 topic echo /scan --max-count 1` | 檢查機器狗驅動是否正常（Terminal 1 日誌） |
| LiDAR 故障 | 機器狗遠程查看 LiDAR 是否轉動 | 機器狗可能需要重啟 |
| SlamToolbox 未按 "Start At Dock" | RViz 檢查 SlamToolboxPlugin | 再次點擊 "Start At Dock" |

---

### 問題 3：看不到 SlamToolboxPlugin

**症狀：** RViz 中找不到 SlamToolboxPlugin 或 "Start At Dock" 按鈕

**解決方案：**
1. **在 Displays 清單中新增：**
   - Displays 面板 → "Add" 按鈕
   - 搜尋 "SlamToolboxPlugin"
   - 點擊添加

2. **若找不到，檢查 SLAM Toolbox 是否安裝：**
   ```bash
   apt list --installed | grep slam-toolbox
   # 應看到 slam-toolbox 相關套件
   ```

---

### 問題 4：導航目標（2D Goal）沒有反應

**症狀：**
- 點擊 "2D Goal" 後無反應
- 或機器狗不動

**檢查步驟：**
1. **確認 Costmap 已初始化：**
   ```bash
   # Terminal 2
   ros2 topic echo /global_costmap/costmap --max-count 1
   # 應有資料輸出
   ```

2. **確認 Nav2 節點都在運行：**
   ```bash
   ros2 node list | grep nav2
   # 應看到：/amcl_node, /planner_server, /controller_server
   ```

3. **若 Costmap 還未出現，等待 10 秒（Nav2 啟動慢）：**
   ```bash
   # 等待期間觀察 RViz，應逐漸看到彩色層出現
   ```

4. **若仍無反應，檢查機器狗位置與地圖對齐：**
   ```bash
   # Terminal 2：查看定位
   ros2 topic echo /amcl_pose --max-count 1
   # 應有數值（如 x: 0.1, y: 0.2）而非全 0
   ```

   **若位置全為 0，需手動初始化：**
   - RViz → "Initialpose" 或 "2D Pose Estimate" 按鈕
   - 在地圖上點擊機器狗實際位置
   - 拖曳設定朝向

---

### 問題 5：地圖存檔失敗

**症狀：**
- `map_saver_cli` 執行後無輸出或出錯

**解決方案：**
```bash
# 確認目錄存在
mkdir -p /home/roy422/elder_and_dog/src/go2_robot_sdk/maps

# 確認有寫入權限
ls -ld /home/roy422/elder_and_dog/src/go2_robot_sdk/maps
# 應看到 drwx...（可寫）

# 重新執行存檔
ros2 run nav2_map_server map_saver_cli -f /home/roy422/elder_and_dog/src/go2_robot_sdk/maps/phase1_test
```

---

## 📝 完成後的動作

1. **記錄結果：**
   - 打開 `/home/roy422/elder_and_dog/docs/04-notes/dev_notes/20251121_slam_test.md`
   - 填寫所有「Phase 1」的欄位（時間、頻率、結果等）

2. **準備 Phase 2：**
   - 清出 4-5 坪的空間
   - 放置 3-5 個障礙物（椅子、盒子）
   - 標記起點位置
   - 準備好後按照 `PHASE2_EXECUTION_GUIDE.md` 進行

3. **若出問題：**
   - 檢查故障排查部分
   - 記錄下遇到的問題與解決方案
   - 這些資訊對後續 VLM + 尋物 FSM 開發很有幫助

---

**祝測試順利！有任何問題隨時回報。** 🚀
