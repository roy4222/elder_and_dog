# Mac M1 + UTM 虛擬機完全部署指南

**版本：** v1.0
**更新日期：** 2025/11/21
**適用對象：** 在 Mac M1 上進行 Go2 機器人開發
**目標環境：** Ubuntu 22.04 + ROS2 Humble + 本專案（go2_robot_sdk）

---

## 📋 目錄

1. [為什麼選 UTM](#為什麼選-utm)
2. [前置條件](#前置條件)
3. [Step 1：下載 UTM](#step-1下載-utm)
4. [Step 2：創建虛擬機](#step-2創建虛擬機)
5. [Step 3：安裝 Ubuntu 22.04](#step-3安裝-ubuntu-2204)
6. [Step 4：配置網路橋接](#step-4配置網路橋接關鍵)
7. [Step 5：安裝 ROS2 Humble](#step-5安裝-ros2-humble)
8. [Step 6：配置本專案環境](#step-6配置本專案環境)
9. [Step 7：驗證環境](#step-7驗證環境)
10. [常見問題](#常見問題)

---

## 為什麼選 UTM

| 特性 | UTM | Parallels | VirtualBox |
|------|-----|----------|-----------|
| **價格** | 免費 | $80/年 | 免費 |
| **M1 優化** | 優秀 | 最佳 | 不佳 |
| **網路橋接** | 完整支援 | 完整支援 | 困難 |
| **GUI 性能** | 良好 | 最佳 | 一般 |
| **推薦度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

**我們選 UTM 因為：**
- ✅ 完全免費
- ✅ M1 原生優化（沒有 Intel 翻譯層開銷）
- ✅ 網路橋接配置清晰
- ✅ 社群文件豐富

---

## 前置條件

- ✅ Mac M1/M2/M3（Apple Silicon）
- ✅ 至少 16GB RAM（本指南分配 10GB 給虛擬機）
- ✅ 100GB 可用磁碟空間（包含 PyTorch 編譯）
- ✅ 已下載本專案 (`git clone ...`)

---

## Step 1：下載 UTM

### 方案 A：官方網站下載（推薦）

1. **訪問 UTM 官網：** https://mac.getutm.app
2. **點擊「Download」**
3. **下載「arm64」版本**（因為你是 M1/M2/M3）
4. **拖到「Applications」資料夾**

### 方案 B：Homebrew 安裝

```bash
brew install utm
```

### 驗證安裝

```bash
# 在 Finder 的 Applications 中應看到 UTM
open /Applications/UTM.app
```

---

## Step 2：創建虛擬機

### 2.1 啟動 UTM

```bash
open /Applications/UTM.app
```

### 2.2 建立新虛擬機

1. 點擊「**+**」按鈕（左下角「Create a New Virtual Machine」）
2. 選擇「**Virtualize**」（不選 Emulate）
3. 選擇「**Linux**」
4. 點擊「**Browse**」下載 Ubuntu 22.04 ISO

### 2.3 ISO 下載

**UTM 會幫你選擇合適的 ISO，但如果需要手動下載：**

```bash
# 下載 Ubuntu 22.04 LTS (ARM64 版本)
# 去 https://cdimage.ubuntu.com/releases/jammy/release/
# 選擇：ubuntu-22.04-live-server-arm64.iso
```

### 2.4 虛擬機配置

| 設定項 | 值 | 說明 |
|--------|-----|------|
| **CPU Cores** | 6 | 留 2 核給 Mac OS |
| **Memory** | 10 GB | RAM 總量 16GB，虛擬機分 10GB |
| **Disk Size** | 80 GB | 包含 PyTorch、编譯、资料 |
| **Network** | Bridge | 關鍵！稍后詳細配置 |

**完成建立後虛擬機會進入安裝畫面。**

---

## Step 3：安裝 Ubuntu 22.04

### 3.1 安裝步驟

1. **啟動虛擬機後** UTM 會自動進入 Ubuntu 安裝嚮導
2. **語言選擇：** 選「English」（便於後續指令）
3. **鍵盤布局：** 選「English (US)」或你熟悉的配置
4. **網路設定：** 先用「Continue without network」（稍後手動配置）
5. **磁碟設定：**
   - 選「Use entire disk」
   - 確認磁碟大小（應為 80GB 之前設定的值）
6. **用戶設定：**
   - **用戶名：** `ros` (建議)
   - **密碼：** 自己設，記住它
   - **主機名：** `go2-dev-vm`

7. **軟體選擇：**
   - 勾選「**OpenSSH Server**」（方便後續遠端連接）
   - 勾選「**Standard system utilities**」

8. **確認安裝** 並等待完成（約 10-15 分鐘）

### 3.2 首次啟動

安裝完成後虛擬機自動重啟，進入登入畫面。

```bash
# 用你設定的用戶名和密碼登入
Username: ros
Password: xxxxxx
```

---

## Step 4：配置網路橋接（關鍵！）

**為什麼需要橋接：** 只有橋接模式，虛擬機才能連接 Go2 的 Wi-Fi（192.168.12.x）。

### 4.1 UTM 中配置橋接

1. **關閉虛擬機**（點「Power Off」）
2. **在 UTM 主視窗中右鍵點虛擬機** → 選「**Edit**」
3. **進入「Network」標籤**
4. **Network Mode 改為「Bridged」**
   - 如果看不到「Bridged」選項，往下拉選單找
   - 選擇 Mac 的 Wi-Fi 網卡（應是「en0」或類似的）

5. **確認並重啟虛擬機**

### 4.2 驗證橋接成功

虛擬機啟動後，在虛擬機內執行：

```bash
# 列出網路介面
ip addr show

# 應看到有效的 IP（例如 192.168.1.x 或 192.168.12.x）
# 而不是 192.168.122.x (NAT 的預設範圍)
```

**如果看到 192.168.1.x 或 192.168.12.x，說明橋接成功！**

### 4.3 測試網路連接

```bash
# 測試網路可達性
ping 8.8.8.8
# 應成功 ping 到

# 查看虛擬機的 IP
hostname -I
# 記下這個 IP（例如 192.168.1.100）
```

---

## Step 5：安裝 ROS2 Humble

### 5.1 快速安裝指令

複製以下指令到虛擬機內，一次執行（需 sudo）：

```bash
#!/bin/bash
set -e

# 更新系統
sudo apt-get update && sudo apt-get upgrade -y

# 添加 ROS2 金鑰和倉庫
sudo curl -sSL https://repo.ros2.org/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros2.org/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 更新包列表
sudo apt-get update

# 安裝 ROS2 Humble
sudo apt-get install -y ros-humble-desktop

# 安裝依賴工具
sudo apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-rviz2 \
    git \
    curl \
    wget \
    vim

# 初始化 rosdep
sudo rosdep init
rosdep update

# 配置 zshrc（預設 shell 為 zsh；若你改用 bash，請將下列檔名改為 .bashrc，setup.zsh 改為 setup.bash）
echo "source /opt/ros/humble/setup.zsh" >> ~/.zshrc
source ~/.zshrc

echo "✅ ROS2 Humble 安裝完成！"
```

### 5.2 驗證 ROS2 安裝

```bash
# 應看到 ROS2 版本信息
ros2 --version
# 輸出：ROS 2 humble release

# 測試 ROS2 環境
source /opt/ros/humble/setup.zsh
ros2 topic list  # 應輸出空清單（目前沒運行的節點）
```

---

## Step 6：配置本專案環境

### 6.1 複製專案

```bash
# 進入家目錄
cd ~

# 複製專案（假設你已有 GitHub 存取權限）
git clone https://github.com/<your-org>/elder_and_dog.git
cd elder_and_dog

# 如果是私有倉庫，需要 SSH 密鑰設置
# 參考：https://docs.github.com/en/authentication/connecting-to-github-with-ssh
```

### 6.2 安裝依賴

```bash
# 切到專案目錄
cd ~/elder_and_dog

# 安裝 Python 依賴（預設使用系統環境；若想隔離可先 uv venv ~/elder_and_dog/.venv && source ~/elder_and_dog/.venv/bin/activate）
uv pip install -r requirements.txt --force-reinstall

# 安裝系統依賴（需 rosdep）
sudo apt-get update
rosdep install --from-paths src --ignore-src -r -y
```

### 6.3 編譯專案

```bash
# 在專案根目錄執行
source /opt/ros/humble/setup.zsh
colcon build

# 首次編譯會花時間（10-20 分鐘）
# 等待出現「Build will continue ...」和「Success」訊息
```

### 6.4 配置虛擬機 zshrc

為了每次登入都自動載入 ROS2 環境，編輯 `~/.zshrc`（若用 bash，改為 `.bashrc` 並將 `setup.zsh` 換成 `setup.bash`）：

```bash
# 編輯 zshrc
nano ~/.zshrc

# 在檔案末尾添加以下行：
source /opt/ros/humble/setup.zsh
source ~/elder_and_dog/install/setup.zsh
export ROBOT_IP="192.168.12.1"
export CONN_TYPE="webrtc"

# 保存：Ctrl+O, Enter, Ctrl+X

# 重新讀取 zshrc
source ~/.zshrc
```

---

## Step 7：驗證環境

### 7.1 快速檢查清單

```bash
# 1. 檢查 ROS2
ros2 --version
# 應輸出：ROS 2 humble release

# 2. 檢查工作空間
source ~/elder_and_dog/install/setup.zsh
ros2 pkg list | grep go2
# 應看到：go2_robot_sdk, go2_interfaces, search_logic 等

# 3. 檢查編譯結果
ls -la ~/elder_and_dog/install/
# 應看到多個文件夾（go2_robot_sdk, search_logic 等）

# 4. 檢查網路（當 Mac 連 Go2 Wi-Fi 時執行）
ping 192.168.12.1
# 應能 ping 到機器狗
```

### 7.2 完整驗證（需要實機 Go2）

等虛擬機完全準備好後，再做 [Phase 1 快速驗證清單](./phase1_quick_check.md)。

---

## 📝 常見問題

### Q1：虛擬機無法連接網路（顯示 192.168.122.x）

**原因：** 網路模式仍為 NAT，沒有設置為橋接。

**解決：**
```bash
# 在 Mac 上，關閉虛擬機
# 進入 UTM 虛擬機設定 → Network → 改為 "Bridged"
# 重新啟動虛擬機
```

### Q2：編譯時出現「command 'colcon' not found」

**原因：** colcon 未安裝。

**解決：**
```bash
sudo apt-get install -y python3-colcon-common-extensions
source ~/.bashrc
```

### Q3：Git clone 時出現「Permission denied」

**原因：** SSH 密鑰未設置。

**解決：**
```bash
# 在虛擬機中生成 SSH 密鑰
ssh-keygen -t ed25519 -C "your@email.com"

# 查看公鑰
cat ~/.ssh/id_ed25519.pub

# 複製公鑰到 GitHub Settings → SSH Keys
# 再重新 clone
```

### Q4：編譯時「No space left on device」

**原因：** 80GB 磁碟空間不足。

**解決：**
```bash
# 查看磁碟使用情況
df -h

# 清理 apt 快取
sudo apt-get clean
sudo apt-get autoclean

# 或重新分配虛擬機磁碟（需重啟虛擬機）
# 在 UTM 設定中修改 Disk Size
```

### Q5：虛擬機性能很慢

**原因：** CPU 或 RAM 分配不足。

**解決：**
```bash
# 在 UTM 設定中增加：
# - CPU Cores：改為 8
# - Memory：改為 12GB（如果 Mac 有 18GB+ RAM）

# 然後重啟虛擬機
```

### Q6：無法連接 Go2 Wi-Fi（橋接已設置但無法 ping 192.168.12.1）

**原因：**
- Mac 連接的 Wi-Fi 和虛擬機橋接的網卡不同
- 或 Go2 Wi-Fi 有連接限制

**排查步驟：**
```bash
# 1. 在 Mac 上檢查連接的 Wi-Fi
networksetup -listallhardwareports

# 2. 在虛擬機中檢查橋接的網卡
ip addr show

# 3. 檢查 Go2 的 Wi-Fi IP 段
# 應該是 192.168.12.x

# 4. 嘗試連接
ping 192.168.12.1

# 5. 如果仍無法連接，重新啟動 Go2 和虛擬機
```

---

## 📚 下一步

虛擬機環境準備好後，進行 **Phase 1 快速驗證**：

- [Phase 1 快速驗證清單](./phase1_quick_check.md)

這會驗證虛擬機能否正確運行 SLAM + Nav2。

---

## 🔗 參考資料

- [UTM 官方文檔](https://docs.getutm.app/)
- [ROS2 Humble 官方安裝指南](https://docs.ros.org/en/humble/Installation.html)
- [Medium：UTM 專為 Mac 設計的虛擬機實做](https://medium.com/@b3121404/utm-%E5%B0%88%E7%82%BAmac%E8%A8%AD%E8%A8%A1%E7%9A%84%E8%99%9B%E6%93%AC%E6%A9%9F-%E5%AF%A6%E8%A3%9Dubuntu%E6%B5%81%E7%A8%8B-39f6ab0fa687)

---

**有問題隨時回報，我會更新本指南！** 🚀
