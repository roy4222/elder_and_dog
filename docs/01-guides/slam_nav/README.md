# SLAM + Nav2 測試計畫 - 總覽文件

**建立日期：** 2025/11/21
**專題組別：** FJU Go2 專題組
**測試目標：** 驗證 SLAM + Nav2 系統在 Go2 機器人上的運作，為後續 VLM + 尋物 FSM 開發奠定基礎

---

## 📂 本目錄檔案說明

### 核心文件

| 檔案名稱 | 用途 | 適用場景 |
|---------|------|--------|
| [Phase 1 執行指南](../../01-guides/slam_nav/phase1_execution_guide.md) | Phase 1 詳細執行指南 | 第一次做小空間驗證 |
| [Phase 2 執行指南](../../01-guides/slam_nav/phase2_execution_guide.md) | Phase 2 詳細執行指南 | 擴大環境後的完整測試 |
| [SLAM/Nav2 速查表](../../01-guides/slam_nav/quick_reference.md) | 速查表（複製貼上指令版） | 快速查詢、故障排查 |
| **20251121_slam_test.md** | 測試日誌表單 | 填寫實驗結果 |
| **README.md** | 本檔案 | 整體規劃與概覽 |

### 使用說明

#### 🚀 第一次做測試？
1. 先讀本檔案（整體了解）
2. 打開 [Phase 1 執行指南](../../01-guides/slam_nav/phase1_execution_guide.md)（逐步執行）
3. 邊做邊填 `20251121_slam_test.md`（記錄結果）
4. 遇到問題查 [SLAM/Nav2 速查表](../../01-guides/slam_nav/quick_reference.md)（故障排查）

#### ⏩ 熟悉流程後？
1. 直接查 [SLAM/Nav2 速查表](../../01-guides/slam_nav/quick_reference.md) 的「複製貼上版本」
2. 平行執行多個 Terminal（加快速度）
3. 仍然記錄到日誌檔，方便比較

#### 🔧 遇到問題？
1. 查 [SLAM/Nav2 速查表](../../01-guides/slam_nav/quick_reference.md) 的「5 大常見陷阱」
2. 或查該指南檔的「故障排查」章節
3. 無法解決時查詢相關錯誤日誌

---

## 🎯 整體測試流程

### Phase 1：小空間驗證（1-2 坪）
**目標：** 確認 SLAM + Nav2 系統基本能運作
**耗時：** 30-40 分鐘
**環境：** 當前空間

**核心檢查項：**
- [x] WebRTC 連接正常 (機器狗視頻、/scan 有資料)
- [x] /scan 頻率 > 5 Hz
- [x] /map 發佈且頻率 ~1 Hz
- [x] TF 鏈完整 (map → odom → base_link)
- [x] SLAM 建圖 (地圖可視化)
- [x] 地圖存檔成功 (.yaml + .pgm)
- [x] Nav2 定位初始化
- [x] 單點導航成功 (RViz "2D Goal" 可用)

**合格標準：** 上述 8 項中至少 6 項通過

**參考檔案：** [Phase 1 執行指南](../../01-guides/slam_nav/phase1_execution_guide.md)

---

### Phase 2：大空間評估（4-5 坪+）
**目標：** 評估 SLAM 迴圈閉合、Nav2 導航、避障、巡邏性能
**耗時：** 60-90 分鐘
**環境：** 擴大到 4-5 坪連續空間，放置 3-5 個障礙物

**核心檢查項：**
- [x] 迴圈閉合成功 (偏移 < 5 cm)
- [x] 5 點導航成功率 >= 80%
- [x] 避障反應時間 < 3 秒
- [x] 完整巡邏迴圈 2 次，穩定性 >= 90%

**合格標準：** 上述 4 項全部通過

**參考檔案：** [Phase 2 執行指南](../../01-guides/slam_nav/phase2_execution_guide.md)

---

## 🔑 核心知識點

### 1. 頻寬管理（最重要）
```
❌ 錯誤做法：同時開啟 Camera 影像 + PointCloud 顯示
   後果：WiFi 頻寬耗盡 → /scan 掉到 2 Hz → SLAM 建圖失敗

✅ 正確做法：
   - ros2 launch 後立刻進 RViz
   - 取消勾選 Displays 中的 "Image" 和 "PointCloud2"
   - 驗證 ros2 topic hz /scan 恢復到 > 5 Hz
```

**影響範圍：** Phase 1 和 Phase 2 都適用

---

### 2. 地圖存檔標準化
```
❌ 錯誤做法：RViz SlamToolboxPlugin "Serialize Map"
   輸出：.posegraph 和 .data（只供 SLAM 續建圖用）

✅ 正確做法：
   ros2 run nav2_map_server map_saver_cli -f ~/path/to/map_name
   輸出：map_name.yaml + map_name.pgm（Nav2 導航標準格式）
```

**影響範圍：** Phase 1 Step 6 和 Phase 2 Step 2

---

### 3. 座標系一致性
```
❌ 錯誤做法：在 patrol_params.yaml 寫死座標 [[1.0, 0.0], [2.0, 1.0], ...]
   問題：環境改變或地圖偏移後，這些座標可能撞牆

✅ 正確做法：
   1. 地圖建完、加載到 RViz 後
   2. Navigation2 Plugin → "Publish Point" 工具
   3. 點擊地圖上的白色區域（安全區）
   4. Terminal 輸出座標 → 複製到 YAML
```

**影響範圍：** Phase 2 Step 5 巡邏測試

---

### 4. Nav2 啟動時序
```
⚠️ 常見問題：ros2 launch 下去後馬上測導航，結果失敗
   原因：Nav2 還在啟動中（Configuring → Active），Costmap 未初始化

✅ 解決方法：
   - 先看 RViz，確認出現彩色障礙物層（Local Costmap）
   - 再等 5-10 秒看地圖周圍膨脹層（Global Costmap）
   - 兩個都出現了才開始測導航
```

**影響範圍：** Phase 1 Step 7 和 Phase 2 Step 3

---

## 📊 預期成果

### Phase 1 完成後
- ✅ 確認系統通訊正常
- ✅ 確認頻寬管理方案有效
- ✅ 確認地圖存檔與載入流程
- ✅ 為 Phase 2 大空間測試做準備

### Phase 2 完成後
- ✅ 確認系統穩定性與性能指標
- ✅ 確認 SLAM 在複雜環境的表現
- ✅ 確認 Nav2 導航與避障能力
- ✅ 確認巡邏節點長時間運行穩定性
- ✅ **系統評估為「Ready for VLM + 尋物 FSM 開發」**

---

## 🛠️ 關鍵工具與指令

### ROS2 命令
```bash
# 啟動系統
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=true

# 監控話題
ros2 topic hz /scan
ros2 topic hz /map
ros2 topic echo /patrol_status

# 驗證 TF 樹
ros2 run tf2_tools view_frames

# 儲存地圖
ros2 run nav2_map_server map_saver_cli -f ~/path/to/map_name

# 運行巡邏
ros2 run search_logic simple_patrol_node --ros-args -p auto_start:=true

# 查看節點列表
ros2 node list
```

### TEST.sh 命令
```bash
bash TEST.sh sit        # 坐下
bash TEST.sh stand      # 站起
bash TEST.sh forward    # 前進 3 秒
bash TEST.sh backward   # 後退 3 秒
bash TEST.sh left       # 左轉 3 秒
bash TEST.sh right      # 右轉 3 秒
bash TEST.sh stop       # 停止
```

### RViz 操作
- **SlamToolboxPlugin** → "Start At Dock"：啟動建圖
- **Navigation2 Plugin** → "2D Goal"：發送導航目標
- **Navigation2 Plugin** → "Publish Point"：取得座標
- **Displays** → 取消勾選：移除高頻寬顯示

---

## ⚡ 時間管理

| 階段 | 耗時 | 備註 |
|------|------|------|
| **環境準備** | 2 分鐘 | 檢查時間同步、WiFi、清空空間 |
| **Phase 1** | 30-40 分鐘 | 小空間基本驗證 |
| **環境改建** | 10-15 分鐘 | 擴大到 4-5 坪、放障礙物 |
| **Phase 2** | 60-90 分鐘 | 大空間完整測試 |
| **結果整理** | 10 分鐘 | 填寫日誌、參數調整記錄 |
| **總計** | 2-3 小時 | 含故障排查和調整 |

**建議分開兩天執行：**
- **Day 1**：環境準備 + Phase 1（1 小時）
- **Day 2**：Phase 2 + 結果分析（1-2 小時）

---

## 📝 測試後的交付物

完成測試後應產生以下檔案：

```
docs/04-notes/dev_notes/
├── 20251121_slam_test.md          # 測試日誌（已填寫）
├── 2025-11-18-dev.md / 2025-11-19-dev.md
└── README.md                      # 本檔案

docs/01-guides/slam_nav/
├── phase1_execution_guide.md      # Phase 1 指南
├── phase2_execution_guide.md      # Phase 2 指南
└── quick_reference.md             # 速查表

src/go2_robot_sdk/maps/
├── phase1_test.yaml               # Phase 1 地圖
├── phase1_test.pgm
├── phase2_large.yaml              # Phase 2 地圖
└── phase2_large.pgm
```

---

## 🎓 後續開發指引

### VLM + 物體偵測整合
完成此測試後，系統已具備：
- ✅ 穩定的 SLAM 建圖能力
- ✅ 可靠的 Nav2 導航與避障
- ✅ 自動巡邏框架（search_logic）

下一步可進行：
1. **視覺語言模型 (VLM)** 物體偵測集成
2. **座標轉換**（2D 影像座標 → 3D 世界座標）
3. **完整尋物 FSM**（視覺 → 定位 → 導航 → 互動）

### 參數優化方向
根據測試結果：
- 若 **迴圈閉合失敗**：調整 `mapper_params_online_async.yaml` 的迴圈檢測敏感度
- 若 **導航不穩定**：調整 `nav2_params.yaml` 的速度和加速度
- 若 **避障不靈敏**：增加 `inflation_radius` 或調整代價地圖參數

---

## 🆘 常見問題快速導航

| 問題 | 參考位置 |
|------|--------|
| **/scan 頻率太低** | [速查表](../../01-guides/slam_nav/quick_reference.md) → 頻寬管理 |
| **地圖為空白** | [Phase 1 指南](../../01-guides/slam_nav/phase1_execution_guide.md) → 故障排查 |
| **導航不動** | [速查表](../../01-guides/slam_nav/quick_reference.md) → 5 大常見陷阱 |
| **巡邏點撞牆** | [Phase 2 指南](../../01-guides/slam_nav/phase2_execution_guide.md) → 座標選擇 |
| **Costmap 不見** | [速查表](../../01-guides/slam_nav/quick_reference.md) → Nav2 未啟動完成 |
| **地圖存檔失敗** | [Phase 1 指南](../../01-guides/slam_nav/phase1_execution_guide.md) → 問題 5 |

---

## 🎯 成功標準一覽

### Phase 1 合格條件
```
✅ 至少 6 / 8 檢查項通過
✅ 無致命頻寬問題 (/scan > 5 Hz)
✅ 系統穩定運行 15+ 分鐘
```

### Phase 2 合格條件
```
✅ 4 / 4 檢查項全部通過
✅ 迴圈閉合偏移 < 5 cm
✅ 導航成功率 >= 80%
✅ 巡邏穩定性 >= 90%
```

### 整體系統評估
```
✅ 兩個階段都合格
✅ 已記錄所有測試數據和參數
✅ 為後續 VLM 開發已準備好

→ 系統評估：✅ Ready for next phase
```

---

## 📞 聯繫與支援

### 遇到問題時
1. 查詢 [SLAM/Nav2 速查表](../../01-guides/slam_nav/quick_reference.md) 的故障排查
2. 檢查 Terminal 日誌（紅色錯誤訊息）
3. 嘗試重啟（驅動 → ROS2 → ros2 launch）
4. 如問題持續，記錄錯誤訊息並聯繫開發組

### 測試反饋
記錄任何發現的問題、改進建議到：
- [x] 填寫測試日誌 (20251121_slam_test.md)
- [ ] 更新文件（若發現步驟有誤或遺漏）
- [ ] 建立 GitHub Issue（複雜問題）

---

## 📚 相關文件

- **專案 README**：`/home/roy422/elder_and_dog/README.md`
- **環境設置指南**：`docs/01-guides/environment_setup_ubuntu.md`
- **設計文件**：`docs/02-design/`
- **其他測試文件**：`docs/03-testing/testing_and_verification.md`
- **SLAM/Nav2 指南**：`docs/01-guides/slam_nav/`

---

## 更新記錄

| 日期 | 版本 | 變更內容 |
|------|------|--------|
| 2025/11/21 | v1.0 | 初版，包含 Phase 1 & 2 完整指南 |

---

**祝測試順利！有任何疑問或建議，歡迎回報。** 🚀

**最後提醒：** 遇到頻寬問題時，立刻想到「關閉 Image/PointCloud」；遇到地圖格式問題時，立刻想到「用指令存檔，不用 GUI」。這兩個是 80% 的問題根源。
