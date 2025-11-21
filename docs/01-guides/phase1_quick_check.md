# Phase 1 快速驗證清單（3-5 分鐘版）

**版本：** v1.0
**用途：** 在 Mac UTM 虛擬機或 Linux 機器上快速驗證 SLAM + Nav2 基本環境
**耗時：** 3-5 分鐘（假設硬體已准備好）

---

## 🎯 前置條件

- ✅ 虛擬機已安裝 ROS2 Humble
- ✅ 專案已 `colcon build` 完成
- ✅ 機器狗 Go2 已開機並 Wi-Fi 可用
- ✅ 虛擬機能 `ping 192.168.12.1`（Go2 IP）

---

## 📋 7 項快速檢查

### ✅ 檢查項 1：ROS2 環境（30 秒）

```bash
# 應看到版本號
ros2 --version
# 輸出：ROS 2 humble release
```

**✓ 通過條件：** 看到版本號

---

### ✅ 檢查項 2：工作空間（30 秒）

```bash
# 確保在虛擬機/開發機的專案根目錄
cd ~/elder_and_dog

# 應看到 install 資料夾
ls -d install/
```

**✓ 通過條件：** `install/` 存在

---

### ✅ 檢查項 3：啟動驅動（30 秒）

**Terminal 1 執行：**
```bash
bash start_go2_simple.sh
```

**預期輸出：**
```
✓ 環境已準備
[INFO] Robot IPs: ['192.168.12.1']
[INFO] Video frame received for robot 0
```

**✓ 通過條件：** 看到「Video frame received」（表示 WebRTC 連接正常）

---

### ✅ 檢查項 4：ROS2 Topic 頻率（60 秒）

**Terminal 2 執行：**
```bash
source /opt/ros/humble/setup.bash
cd ~/elder_and_dog && source install/setup.bash
ros2 topic hz /scan
```

**預期輸出：**
```
average rate: 7.XX hz
	min: X.XXXs max: X.XXXs std dev: X.XXXs window: X
```

**✓ 通過條件：** 頻率 > 5 Hz

---

### ✅ 檢查項 5：啟動 SLAM + Nav2（60 秒）

**Terminal 3 執行：**
```bash
export ROBOT_IP="192.168.12.1"
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=false
```

**預期：** 無重大錯誤，看到節點列表

**✓ 通過條件：** 沒有「ERROR」或「FATAL」

---

### ✅ 檢查項 6：驗證地圖發佈（30 秒）

**Terminal 2 執行（同時執行檢查項 5）：**
```bash
ros2 topic hz /map
```

**預期輸出：**
```
average rate: 0.9X hz
```

**✓ 通過條件：** 頻率 > 0.5 Hz（表示 SLAM 在運作）

---

### ✅ 檢查項 7：TF 樹完整性（30 秒）

**Terminal 2 執行：**
```bash
ros2 run tf2_tools view_frames
# 會產生 frames.pdf

# 打開查看
open frames.pdf
# 或在 Linux 上用：xdg-open frames.pdf
```

**✓ 通過條件：** PDF 中看到完整鏈路 `map → odom → base_link`

---

## 📊 檢查結果

| # | 項目 | 結果 | 備註 |
|---|------|------|------|
| 1 | ROS2 環境 | ✅ / ❌ | |
| 2 | 工作空間 | ✅ / ❌ | |
| 3 | 啟動驅動 | ✅ / ❌ | |
| 4 | /scan 頻率 | ✅ / ❌ | ___ Hz |
| 5 | SLAM + Nav2 | ✅ / ❌ | |
| 6 | /map 發佈 | ✅ / ❌ | ___ Hz |
| 7 | TF 樹 | ✅ / ❌ | |

**總評：** ___ / 7 ✅

---

## ✅ 合格標準

- **7/7 全通過** → 環境完全就緒，可進行完整 Phase 1 & 2 測試
- **6/7 通過** → 環境基本可用，但建議排查失敗項
- **< 6/7** → 環境有問題，建議檢查故障排查章節

---

## 🔴 快速故障排查

### 檢查項 3 失敗：「Video frame received」沒出現

```bash
# 可能原因：WebRTC 未連接
# 解決：
1. 確認虛擬機能 ping 192.168.12.1
ping 192.168.12.1

2. 重啟驅動
Ctrl+C 停止 start_go2_simple.sh
再執行一次

3. 檢查 Go2 Wi-Fi（遠端 app 查看連接狀態）
```

### 檢查項 4 失敗：/scan 頻率 < 5 Hz

```bash
# 可能原因：頻寬耗盡或網路不穩
# 解決：
1. 檢查網路
ping -c 10 192.168.12.1

2. 重啟虛擬機網路
# 在虛擬機中：
sudo systemctl restart networking

3. 虛擬機網路橋接檢查
# 在 UTM 設定中確認網路模式為 "Bridged"
```

### 檢查項 5 失敗：看到 ERROR

```bash
# 可能原因：ROS2 環境未載入
# 解決：
source /opt/ros/humble/setup.bash
source ~/elder_and_dog/install/setup.bash
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true
```

### 檢查項 7 失敗：TF 有斷鏈

```bash
# 可能原因：某些節點未啟動
# 解決：
# 確保 Terminal 3 的 ros2 launch 正在運行
# 檢查節點列表：
ros2 node list
# 應看到：go2_driver_node, slam_toolbox, nav2_* 等
```

---

## 📝 記錄頻率數值

為了後續對比，記下這些值：

```
虛擬機 Phase 1 快速驗證（日期：________）

/scan 頻率：_______ Hz（預期 > 5 Hz）
/map 頻率：_______ Hz（預期 > 0.5 Hz）
Go2 IP 可達：✅ / ❌
TF 樹完整：✅ / ❌

通過項數：____ / 7
```

---

## ✅ 完成後

所有 7 項都通過後，你的虛擬機環境已準備好進行：

1. **完整 Phase 1 & 2 測試** → 進度詳見 [Phase 1 執行指南](./slam_nav/phase1_execution_guide.md)
2. **VLM 物體偵測開發**（第 2 週）
3. **座標轉換開發**（第 2 週）
4. **尋物 FSM 開發**（第 3 週）

**預祝測試順利！** 🚀

