# 快速參考卡 - SLAM + Nav2 測試速查表

## 📌 重點速記

### 頻寬管理（最重要！）
```
❌ 常見錯誤：同時開 Image + PointCloud → /scan 掉到 2 Hz → 建圖失敗

✅ 正確做法：
1. ros2 launch 後 → RViz 開啟
2. 立刻取消勾選 "Image" 和 "PointCloud2"
3. ros2 topic hz /scan → 應恢復到 > 5 Hz
```

### 地圖存檔（不用 GUI，用指令）
```bash
# ❌ 不要用：RViz SlamToolboxPlugin "Serialize Map"（輸出 .posegraph，不是導航格式）

# ✅ 要用：
ros2 run nav2_map_server map_saver_cli -f ~/path/to/map_name
# 輸出：map_name.yaml + map_name.pgm
```

### 座標系一致性（不要寫死坐標）
```
❌ 錯誤：patrol_params.yaml 寫 [[1.0, 0.0], [2.0, 1.0], ...]
       新環境這些座標可能撞牆

✅ 正確：
1. 建圖完成，地圖加載後
2. RViz → "Publish Point" 工具
3. 點擊 Costmap 白色區域，取座標
4. 複製到 YAML，確認座標在安全區
```

---

## 🎯 Phase 1 核心流程（複製貼上版）

```bash
# ===== Terminal 1 =====
cd /home/roy422/elder_and_dog
bash start_go2_simple.sh
# 等待：Video frame received

# ===== Terminal 2 =====
source /opt/ros/humble/setup.bash
cd /home/roy422/elder_and_dog && source install/setup.bash
export ROBOT_IP="192.168.12.1"
ros2 topic hz /scan        # 監控 > 5 Hz

# ===== Terminal 3 =====
export ROBOT_IP="192.168.12.1"
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=true
# RViz 開啟後 → 取消勾選 Image + PointCloud

# ===== Terminal 4 =====
bash TEST.sh forward && sleep 1 && bash TEST.sh left && sleep 1 && bash TEST.sh forward
# 觀察 RViz 地圖填充

# ===== Terminal 2 驗證指令 =====
ros2 topic hz /map                    # 應 ~1 Hz
ros2 run tf2_tools view_frames        # 應 map → odom → base_link 完整
ros2 run nav2_map_server map_saver_cli -f ~/elder_and_dog/src/go2_robot_sdk/maps/test1
```

---

## 🎯 Phase 2 核心流程

```bash
# ===== 前置（同 Phase 1 的 Terminal 1-3） =====

# ===== Step 1：建圖（10-15 分鐘） =====
bash TEST.sh forward && bash TEST.sh left && bash TEST.sh forward # 重複覆蓋環境

# ===== Step 2：儲存地圖 =====
ros2 run nav2_map_server map_saver_cli -f ~/elder_and_dog/src/go2_robot_sdk/maps/test2_large

# ===== Step 3：多點導航（RViz） =====
# Navigation2 Plugin → "Publish Point" → 點 5 個白色區域，記座標
# 逐點用 "2D Goal" 測試，記成功率

# ===== Step 4：避障測試 =====
# RViz 設置長距離導航，機器狗移動中放置障礙物，觀察反應

# ===== Step 5：巡邏測試 =====
# 編輯 src/search_logic/config/patrol_params.yaml
# 替換 patrol_points（用 Step 3 的座標）
ros2 run search_logic simple_patrol_node --ros-args -p auto_start:=true -p loop_patrol:=true
# 監控 2 圈，記錄成功率
```

---

## 📊 合格標準速查

### Phase 1 合格（至少 6/8 項）
```
□ /scan 頻率 > 5 Hz
□ /map 頻率 ~1 Hz
□ TF 鏈完整（map → odom → base_link）
□ 地圖存檔成功（.yaml + .pgm）
□ Costmap 可見（Local + Global）
□ 單點導航成功
□ 無致命頻寬問題
□ 系統運行 15+ 分鐘無崩潰
```

### Phase 2 合格（須全部達標）
```
□ 迴圈閉合偏移 < 5 cm
□ 5 點導航成功率 >= 80%
□ 避障反應時間 < 3 秒
□ 完整巡邏迴圈 2 次無失敗 (或 >= 90% 成功)
□ 無頻寬崩潰或卡頓現象
```

---

## 🔧 常用指令速查

| 任務 | 指令 |
|------|------|
| **環境準備** | `source /opt/ros/humble/setup.bash && cd ~/elder_and_dog && source install/setup.bash && export ROBOT_IP="192.168.12.1"` |
| **啟動驅動** | `bash start_go2_simple.sh` |
| **啟動 SLAM+Nav2** | `ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=true` |
| **檢查 /scan** | `ros2 topic hz /scan` |
| **檢查 /map** | `ros2 topic hz /map` |
| **檢查 TF** | `ros2 run tf2_tools view_frames` |
| **儲存地圖** | `ros2 run nav2_map_server map_saver_cli -f ~/elder_and_dog/src/go2_robot_sdk/maps/my_map` |
| **查看節點** | `ros2 node list` |
| **移動機器狗** | `bash TEST.sh forward/backward/left/right/sit/stand/balance` |
| **啟動巡邏** | `ros2 run search_logic simple_patrol_node --ros-args -p auto_start:=true` |
| **監控巡邏** | `ros2 topic echo /patrol_status` |
| **編輯巡邏點** | `nano src/search_logic/config/patrol_params.yaml` |

---

## 🚨 5 大常見陷阱

| # | 陷阱 | 症狀 | 秒殺方案 |
|---|------|------|--------|
| 1 | **頻寬耗盡** | /scan < 3 Hz，地圖斷裂 | RViz 取消 Image/PointCloud |
| 2 | **地圖格式錯誤** | `map_saver_cli` 不出 .yaml | 無視 RViz Plugin，只用 CLI 指令 |
| 3 | **座標撞牆** | 巡邏點無法到達 | 用 "Publish Point" 重新選座標 |
| 4 | **Nav2 未啟動完成** | Costmap 不見 | 等 10 秒，再看 RViz |
| 5 | **SLAM 未按 Start** | 地圖為空白 | RViz SlamToolboxPlugin → "Start At Dock" |

---

## 📱 RViz 快捷操作

| 操作 | 按鈕位置 | 效果 |
|------|--------|------|
| **啟動 SLAM** | SlamToolboxPlugin → "Start At Dock" | 設置地圖原點 |
| **發送導航** | Navigation2 Plugin → "2D Goal" | 機器狗自動導航 |
| **取座標** | Navigation2 Plugin → "Publish Point" | Terminal 輸出座標 |
| **設初始位置** | Navigation2 Plugin → "2D Pose Estimate" | 手動校正定位 |
| **移除高頻顯示** | Displays → 滑鼠右鍵 → Delete | 節省頻寬 |

---

## 📁 關鍵檔案位置

| 檔案 | 用途 | 路徑 |
|------|------|------|
| **SLAM 參數** | 迴圈閉合靈敏度調整 | `go2_robot_sdk/config/mapper_params_online_async.yaml` |
| **Nav2 參數** | 速度、避障調整 | `go2_robot_sdk/config/nav2_params.yaml` |
| **巡邏點** | 設置巡邏路徑 | `src/search_logic/config/patrol_params.yaml` |
| **測試日誌** | 記錄實驗結果 | `docs/04-notes/dev_notes/20251121_slam_test.md` |
| **Phase 1 指南** | 詳細步驟 | `docs/01-guides/slam_nav/phase1_execution_guide.md` |
| **Phase 2 指南** | 詳細步驟 | `docs/01-guides/slam_nav/phase2_execution_guide.md` |
| **地圖存檔** | 建圖結果 | `src/go2_robot_sdk/maps/` |

---

## ⏱️ 時間估計

| 階段 | 耗時 | 備註 |
|------|------|------|
| **環境準備** | 2 分鐘 | 檢查時間/WiFi/清空空間 |
| **Phase 1 完整** | 30-40 分鐘 | 包括所有驗證步驟 |
| **環境擴大準備** | 10-15 分鐘 | 清出大空間、放障礙物 |
| **Phase 2 建圖** | 15-20 分鐘 | 覆蓋 4-5 坪區域 |
| **Phase 2 導航測試** | 20-30 分鐘 | 5 點導航 + 避障 |
| **Phase 2 巡邏測試** | 20-30 分鐘 | 2 圈完整巡邏 |
| **結果整理** | 10 分鐘 | 填寫日誌、參數調整 |
| **總計** | 2-3 小時 | 含環境切換、故障排查 |

---

## 💡 訣竅與最佳實踐

### 建圖訣竅
```
1. 移動要 SLOW（給 SLAM 時間配準掃描）
2. 轉向要大幅（幫助特徵識別）
3. 走過牆角（SLAM 最喜歡轉角特徵）
4. 最後一定要回起點附近（驗證迴圈閉合）
```

### 導航訣竅
```
1. 座標選在「開放空間中心」，不靠牆
2. 先測「短距離」(0.5m)，再測「長距離」(2m+)
3. 若導航卡住，不要等太久，按 Ctrl+C 終止重試
4. 觀察 Costmap，黑色=障礙，應避開
```

### 故障排查訣竅
```
1. 第一步：重啟驅動和 ROS2（90% 問題解決）
2. 第二步：檢查頻寬（RViz 移除高頻顯示）
3. 第三步：檢查檔案日誌（Terminal 上方是否有紅色錯誤）
4. 最後步：調整參數（SLAM/Nav2 YAML 改值）
```

---

## 📞 緊急聯繫

遇到以下問題，立即檢查：

```
❌ "ROS2 環境未載入"
   → source /opt/ros/humble/setup.bash && source install/setup.bash

❌ "/scan 頻率低於 3 Hz"
   → RViz 取消 Image/PointCloud，或重啟系統

❌ "地圖為空白"
   → RViz SlamToolboxPlugin "Start At Dock" 沒按

❌ "導航不動"
   → 等待 Nav2 啟動完成（看 Costmap 出現），或手動 "2D Pose Estimate" 初始化

❌ "巡邏點撞牆"
   → 用 "Publish Point" 重新選座標，避免靠近黑色（障礙物）
```

---

**最後提醒：遇到任何問題，先檢查故障排查部分，90% 的問題都有標準解法！** 🎯
