# Ubuntu 環境配置指南（ROS2 + fju-go2-sdk）

**適用對象：** 在 Ubuntu 上開發本專案（包含導航、尋物、Isaac Sim 等）的開發者  
**建議版本：** Ubuntu 22.04 + ROS2 Humble

---

## 1️⃣ 系統基本工具安裝（只需一次）

```bash
sudo apt update
sudo apt install -y \
  build-essential git curl \
  python3-pip python3-venv
```

如有打算使用 RViz、Nav2 等圖形工具，請確認系統有 GPU 驅動並可正常啟動桌面環境。

### （可選，但推薦）安裝 uv 作為 Python 套件管理工具

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh

# 讓 uv 立即可用（sh / bash / zsh）
source "$HOME/.local/bin/env"

# 驗證安裝
uv --version
```

---

## 2️⃣ 安裝 ROS2 Humble Desktop

> 若系統已安裝 ROS2 Humble，可略過本節，直接看下一節「rosdep 初始化」。

```bash
# 啟用必要套件庫
sudo apt install software-properties-common
sudo add-apt-repository universe
sudo apt install curl gnupg lsb-release

# 新增 ROS2 軟體源 GPG key
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
  -o /usr/share/keyrings/ros-archive-keyring.gpg

# 新增 ROS2 軟體源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 安裝 ROS2 Humble Desktop + 開發工具
sudo apt update
sudo apt install -y ros-humble-desktop ros-dev-tools
```

每次開新 Terminal 時，請先載入 ROS2 環境：

```bash
source /opt/ros/humble/setup.bash
```

可以將此指令寫進 `~/.bashrc`，避免每次手動輸入：

```bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
```

---

## 3️⃣ rosdep 初始化（安裝 ROS 相依套件的基礎）

`rosdep` 會幫你安裝像 `nav2_bringup`、`slam_toolbox` 等 ROS 套件，是後面導航與 SLAM 可以正常啟動的前提。

第一次使用時執行（只需一次）：

```bash
sudo rosdep init
rosdep update
```

之後若套件有更新，只要偶爾重跑 `rosdep update` 即可。

---

## 4️⃣ 建立 ROS2 Workspace 並載入本專案 (已clone的話可跳過這個步驟)

建議 Workspace 結構（可依需要調整）：

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src

# 若尚未 clone 專案
git clone https://github.com/your-org/fju-go2-sdk.git

cd ~/ros2_ws
```

之後所有 `colcon build`、`rosdep install` 指令，都在 `~/ros2_ws`（workspace 根目錄）執行。

---

## 5️⃣ 安裝專案相依套件（ROS + Python）

確保已經：

- 在 `~/ros2_ws` 底下
- 已 `source /opt/ros/humble/setup.bash`

### 5.1 ROS 相依（包含 Nav2 / SLAM 等）

```bash
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
```

這一步會根據 `src/` 底下所有 ROS2 套件的 `package.xml`，自動安裝：

- `nav2_bringup`, `nav2_map_server`, `nav2_amcl` 等導航相關套件  
- `slam_toolbox` 等建圖相關套件  
- 其他 sensor / perception 相依（若有）

### 5.2 Python 相依（requirements.txt）

#### 方式 A：使用 uv（推薦）

```bash
cd ~/ros2_ws

# 建立虛擬環境（放在 .venv 資料夾）
uv venv .venv
source .venv/bin/activate

# 安裝本專案所需的 Python 套件
uv pip install -r src/fju-go2-sdk/requirements.txt
```

#### 方式 B：使用系統 pip（備用）

```bash
cd ~/ros2_ws
pip install -r src/fju-go2-sdk/requirements.txt
```

目前 `requirements.txt` 主要包含：

- `torch`, `torchvision`：深度學習框架  
- `opencv-python`, `open3d`, `numpy`：影像、點雲與數值處理  
- `aiortc`, `aiohttp`, `paho-mqtt`, `python-dotenv`, `pycryptodome` 等通訊與工具套件

---

## 6️⃣ 編譯與基本驗證

完成前面步驟後，可以先確認專案可以成功編譯：

```bash
cd ~/ros2_ws
colcon build

# 載入編譯後的 overlay
source install/setup.bash
```

簡單驗證：

```bash
ros2 pkg list | grep go2_robot_sdk
```

若可以看到 `go2_robot_sdk`，代表專案已成功被 ROS2 辨識。

---

## 7️⃣ 導航與尋物相關的啟動示例

### 7.1 啟動帶 SLAM + Nav2 的機器狗系統

```bash
cd ~/ros2_ws
source install/setup.bash

ros2 launch go2_robot_sdk robot.launch.py \
  slam:=true nav2:=true
```

此時可以開啟 RViz，使用 Nav2 的 Goal 工具送目標點，確認導航功能正常。

### 7.2 與後續套件（VLM / 座標轉換 / 尋物 FSM）整合

完成上述環境後，即可依照以下文件繼續開發：

- `docs/gemini_vlm_development.md`：VLM 節點  
- `docs/coordinate_transformation.md`：座標轉換  
- `docs/search_fsm_design.md`：尋物狀態機與 Nav2 呼叫流程

---

## 8️⃣ 常見問題建議檢查項

- `ros2` 指令找不到：確認有沒有 `source /opt/ros/humble/setup.bash`
- `go2_robot_sdk` 找不到：確認有沒有在 Workspace 根目錄 `colcon build`，並 `source install/setup.bash`
- Nav2 / SLAM 無法啟動：重新檢查 `rosdep install --from-paths src --ignore-src -r -y` 是否有成功執行，且沒有未解決的依賴錯誤。
- **啟動時出現 `Expected 'value' to be one of [...], but got '()' of type '<class 'tuple'>'` 錯誤**：
  - **原因**：未設定 `ROBOT_IP` 環境變數時，空的 list `[]` 被 ROS2 參數系統轉換成 tuple `()` 導致型別檢查失敗
  - **解決方法**：已在 `robot.launch.py:200` 修正，空 list 會自動轉換為 `['']`
  - **建議**：啟動前務必設定正確的機器人 IP：
    ```bash
    export ROBOT_IP="192.168.1.100"  # 單機器人
    # 或
    export ROBOT_IP="192.168.1.100,192.168.1.101"  # 多機器人
    ```
