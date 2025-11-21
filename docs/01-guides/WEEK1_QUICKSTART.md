# Week 1 Quick Start（複製貼上版本）

**用途：** 快速參考，不需看長文檔
**耗時：** 1 小時完整執行（有 UTM 經驗時）

---

## 🚀 今週必做三件事

### 任務 1：Linux 機器 Phase 1 測試（2-3 小時）

**Terminal 1：**
```bash
cd /home/roy422/elder_and_dog
bash start_go2_simple.sh
# 等待看到：[INFO] Video frame received for robot 0
```

**Terminal 2：**
```bash
source /opt/ros/humble/setup.bash
cd /home/roy422/elder_and_dog && source install/setup.bash
export ROBOT_IP="192.168.12.1"

# 驗證 /scan 頻率
ros2 topic hz /scan
# 應 > 5 Hz
```

**Terminal 3：**
```bash
export ROBOT_IP="192.168.12.1"
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=false
# 無紅色 ERROR
```

**結果記錄：**
```bash
# 填寫這些數值到 20251121_slam_test.md
/scan 頻率：_______ Hz
/map 頻率：_______ Hz
TF 樹：完整 / 有斷鏈
```

✅ **通過條件：** 7 項都通過（詳見 phase1_quick_check.md）

---

### 任務 2：Mac 虛擬機安裝（3-4 小時）

#### Step A：下載 UTM
```bash
# 方案 1：官網下載（推薦）
# https://mac.getutm.app → 下載 arm64 版本

# 方案 2：Homebrew
brew install utm
```

#### Step B：建立虛擬機
1. 打開 UTM，點「+」
2. 選「Virtualize」 → 「Linux」
3. 下載 Ubuntu 22.04 LTS ISO
4. **配置：**
   - CPU：6 核
   - RAM：10 GB
   - 磁碟：80 GB
   - **網路：Bridge**（最重要！）

#### Step C：安裝 Ubuntu 22.04
```
1. 語言：English
2. 鍵盤：English (US)
3. 網路：skip（稍後手動配置）
4. 磁碟：Use entire disk
5. 用戶：ros / 密碼
6. 勾選：OpenSSH Server
```

#### Step D：ROS2 安裝（複製整個代碼塊執行）
```bash
#!/bin/bash
set -e

sudo apt-get update && sudo apt-get upgrade -y

sudo curl -sSL https://repo.ros2.org/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros2.org/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt-get update
sudo apt-get install -y ros-humble-desktop
sudo apt-get install -y python3-colcon-common-extensions python3-rosdep ros-humble-rmw-cyclonedds-cpp ros-humble-rviz2 git curl wget vim

sudo rosdep init
rosdep update

echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc

echo "✅ ROS2 安裝完成"
```

#### Step E：複製並編譯專案
```bash
cd ~
git clone https://github.com/YOUR_ORG/elder_and_dog.git
cd elder_and_dog

source /opt/ros/humble/setup.bash
pip install -r src/requirements.txt
rosdep install --from-paths src --ignore-src -r -y

colcon build
# 等待完成（10-20 分鐘）
```

#### Step F：配置 bashrc
```bash
nano ~/.bashrc
# 在末尾添加：
source /opt/ros/humble/setup.bash
source ~/elder_and_dog/install/setup.bash
export ROBOT_IP="192.168.12.1"

# Ctrl+O, Enter, Ctrl+X 保存
source ~/.bashrc
```

✅ **通過條件：** 虛擬機能 `ros2 --version` 和 `colcon` 指令可用

---

### 任務 3：虛擬機 Phase 1 驗證（30 分鐘）

在虛擬機中執行（連接 Go2 Wi-Fi）：

```bash
# 1. 驗證網路
ping 192.168.12.1
# 應通，表示網路橋接成功

# 2. 啟動驅動 (Terminal 1)
bash start_go2_simple.sh
# 看到 "Video frame received"

# 3. 驗證 /scan (Terminal 2)
source ~/.bashrc
ros2 topic hz /scan
# 應 > 5 Hz

# 4. 啟動 SLAM + Nav2 (Terminal 3)
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true rviz2:=false

# 5. 驗證 /map (Terminal 2 新窗口)
ros2 topic hz /map
# 應 ~1 Hz

# 6. 檢查 TF (Terminal 2 新窗口)
ros2 run tf2_tools view_frames
open frames.pdf
# 應看到 map → odom → base_link 完整鏈路
```

✅ **通過條件：** 同 Linux 機器的 7 項全通過

---

## 📋 進度檢查表

```
Week 1 完成狀況表

□ Linux Phase 1：___/7 項
□ UTM 虛擬機安裝完成
□ 虛擬機 Phase 1：___/7 項
□ 記錄頻率數據到測試日誌
□ 與柏翊確認模擬器進度

目標：全 ✅ 才能開始 Week 2
```

---

## ⚠️ 常見卡點

### 「虛擬機無法連 Go2 Wi-Fi」
```
原因：網路模式是 NAT，不是 Bridge
解決：
1. 關閉虛擬機
2. UTM 設定 → Network → 改為 "Bridged"
3. 重啟虛擬機
4. 虛擬機內執行：ip addr show
   應看到 192.168.12.x 或 192.168.1.x（不是 192.168.122.x）
```

### 「colcon build 卡住」
```
解決：
1. Ctrl+C 停止
2. 清理快取：cd ~/elder_and_dog && rm -rf build install
3. 重新執行：colcon build
```

### 「Git clone 權限拒絕」
```
解決：生成 SSH 密鑰
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub
# 複製到 GitHub Settings → SSH Keys
```

---

## 🎯 本週目標達成檢查

**滿分 = 全部 ✅**

```
Week 1 成就：

✅ Linux Phase 1 驗證通過
  └─ /scan > 5 Hz ✅
  └─ /map > 0.5 Hz ✅
  └─ TF 樹完整 ✅

✅ UTM 虛擬機可用
  └─ 網路橋接正常 ✅
  └─ ROS2 環境就緒 ✅
  └─ 能 ping 192.168.12.1 ✅

✅ 虛擬機 Phase 1 驗證通過
  └─ 同樣 7 項檢查 ✅

✅ 模擬器清點完成
  └─ 與柏翊確認進度 ✅

👉 一切就緒，可開始 Week 2 開發！
```

---

## 📞 遇到問題

**優先順序：**

1. 先查本檔案「常見卡點」
2. 再查 `mac_utm_vm_setup.md` 「常見問題」
3. 再查 `phase1_quick_check.md` 「快速故障排查」
4. 仍無法解決 → 聯繫我

---

**準備好了嗎？開始吧！** 🚀

