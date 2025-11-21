# 🚀 Quadro RTX 8000 快速啟動指南

**GPU 規格：** NVIDIA Quadro RTX 8000 48GB（遠端 SSH）
**重大優勢：** 性能遠超需求，可啟用所有高級功能！

---

## ✅ 您的優勢

| 項目 | 您的配置 | Isaac Sim 最低需求 | 評價 |
|------|---------|-------------------|------|
| **VRAM** | 48GB | 6GB | ✅ **8 倍超標** |
| **性能** | Turing 架構 + RT 核心 | Maxwell+ | ✅ **頂級** |
| **可用功能** | RTX 光線追蹤 + 多機器人 + VLM 本地推論 | 基礎模擬 | ✅ **全開** |

---

## 🎯 三步快速開始

### Step 1：連線到遠端 GPU 伺服器（5 分鐘）

**方法 A：SSH + X11（測試用）**
```bash
# 本地 Windows 安裝 VcXsrv（X Server）
# 下載：https://sourceforge.net/projects/vcxsrv/

# WSL/PowerShell 連線
export DISPLAY=localhost:0.0
ssh -X user@remote-server-ip

# 測試
nvidia-smi  # 應顯示 Quadro RTX 8000
```

**方法 B：NoMachine（推薦，最佳體驗）**
```bash
# 遠端安裝 NoMachine Server
wget https://download.nomachine.com/download/8.11/Linux/nomachine_8.11.3_1_amd64.deb
sudo dpkg -i nomachine_8.11.3_1_amd64.deb

# 本地安裝 NoMachine Client
# https://www.nomachine.com/download
# 連線到伺服器 IP，享受接近本地的體驗
```

**方法 C：VSCode Remote SSH（開發推薦）**
```bash
# VSCode 安裝擴充功能：Remote - SSH
# 配置 ~/.ssh/config:
Host gpu-server
    HostName your-server-ip
    User your-username
    ForwardX11 yes

# VSCode: Ctrl+Shift+P → "Remote-SSH: Connect to Host"
# 直接在遠端開發，零延遲
```

**📖 詳細文件：** [../01-guides/remote_gpu_setup.md](../01-guides/remote_gpu_setup.md)

---

### Step 2：安裝 Isaac Sim + go2_omniverse（30-60 分鐘）

```bash
# SSH 連入伺服器後

# 1. 檢查 GPU
nvidia-smi

# 2. 安裝 Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
conda config --set auto_activate_base false

# 3. 安裝 Isaac Sim 2023.1.1
# 使用 Omniverse Launcher 或 Docker
# 詳見：../02-design/isaac_sim_integration.md

# 4. 安裝 IsaacLab (Orbit 0.3.0)
cd ~/workspace
git clone https://github.com/isaac-sim/IsaacLab.git --branch v0.3.1
cd IsaacLab
export ISAACSIM_PATH="${HOME}/.local/share/ov/pkg/isaac-sim-2023.1.1"
ln -s ${ISAACSIM_PATH} _isaac_sim
./orbit.sh --conda
conda activate orbit
./orbit.sh --install --extra rsl_rl

# 5. 安裝 go2_omniverse
cd ~/workspace
git clone https://github.com/abizovnuralem/go2_omniverse.git --recurse-submodules
cd go2_omniverse

# 複製配置文件
mkdir -p ~/workspace/IsaacLab/source/data/sensors/lidar
cp Isaac_sim/Unitree/Unitree_L1.json \
   ~/workspace/IsaacLab/source/data/sensors/lidar/

# 6. 測試啟動（選擇方法）
# 方法 A: 完整 GUI（透過 NoMachine/VNC）
./run_sim.sh

# 方法 B: WebRTC Streaming（瀏覽器查看）
./run_sim.sh --streaming
# 本地瀏覽器：http://server-ip:8211/streaming/webrtc-client/

# 方法 C: Headless（純 ROS2，無 GUI）
xvfb-run -a ./run_sim.sh --headless
```

**📖 詳細文件：** [../02-design/isaac_sim_integration.md](../02-design/isaac_sim_integration.md)

---

### Step 3：啟動完整系統（5 分鐘）

```bash
# 1. 克隆專案（若未克隆）
cd ~/workspace
git clone <your-repo-url> fju-go2-sdk
cd fju-go2-sdk

# 2. 安裝 ROS2 Humble（若未安裝）
# 參考：../01-guides/quickstart_w6_w9.md Day 1-2

# 3. 編譯專案
rosdep install --from-paths src --ignore-src -r -y
uv pip install -r requirements.txt --force-reinstall
colcon build
source install/setup.bash

# 4. 啟動完整系統
export GEMINI_API_KEY="your_api_key"

# Terminal 1: Isaac Sim
cd ~/workspace/go2_omniverse
./run_sim.sh

# Terminal 2: ROS2 系統（完整模式）
cd ~/workspace/fju-go2-sdk
source install/setup.bash
ros2 launch go2_robot_sdk robot.launch.py \
  simulation:=true \
  vlm:=true \
  search:=true \
  slam:=true \
  nav2:=true

# Terminal 3: 發送尋物指令
ros2 topic pub /search_command std_msgs/String "data: '找杯子'" --once

# Terminal 4: 監控結果
ros2 topic echo /search_result
```

---

## 🎮 啟用高級功能（利用 48GB VRAM）

### 1. RTX 即時光線追蹤
```python
# 在 Isaac Sim 中啟用
# Edit → Preferences → Rendering
# Rendering Mode: Ray Tracing
# Samples Per Pixel: 4
```

### 2. 多機器人同時模擬（4-8 台）
```bash
# 修改 go2_omniverse 參數
./run_sim.sh --num_robots 4

# ROS2 多機模式
export ROBOT_IP="sim1,sim2,sim3,sim4"
ros2 launch go2_robot_sdk robot.launch.py simulation:=true
```

### 3. 高解析度相機（提升 VLM 準確率）
```python
# 修改 go2_omniverse 相機配置
camera_resolution = (1920, 1080)  # Full HD
# 48GB VRAM 完全足夠
```

### 4. VLM 本地推論（備用方案）
```bash
# 若 Gemini API 受阻，可用本地模型
uv pip install llava

# 下載 LLaVA 模型（約 13GB）
# 您的 48GB VRAM 可輕鬆運行
```

**📖 詳細文件：** [../01-guides/remote_gpu_setup.md](../01-guides/remote_gpu_setup.md) § 效能優化

---

## 📊 預期效能（基於 Quadro RTX 8000）

| 指標 | 預期值 | 備註 |
|------|--------|------|
| **Isaac Sim FPS** | 60-120 | 2 倍於入門級 GPU |
| **SLAM 處理速度** | 10-15 Hz | 遠超實時需求 |
| **VLM 推論延遲** | 0.5-0.8s | 若用本地模型 |
| **同時機器人數** | 6-8 台 | 可測試多機協作 |
| **VRAM 使用率** | 20-35GB | 遠低於上限 48GB |

---

## 🛠️ 推薦工作流程

### 日常開發
1. **本地端**：VSCode 編輯程式碼
2. **遠端端**：執行 Isaac Sim + ROS2 測試
3. **同步方式**：
   - Git（推薦）
   - VSCode Remote SSH（最佳）
   - rsync（快速同步）

### W6-W9 開發建議
- **W6-W7**：本地開發 VLM/座標轉換，遠端測試
- **W8**：完整部署 Isaac Sim
- **W9**：遠端進行 20 次端到端測試

---

## ⚡ 快速故障排除

### Q: SSH X11 Forwarding 很慢
```bash
# 改用 NoMachine（硬體加速）
# 或 VSCode Remote SSH（本地編輯+遠端執行）
```

### Q: Isaac Sim 顯示 "No display"
```bash
# 使用 xvfb
sudo apt install xvfb
xvfb-run -a ./run_sim.sh

# 或啟用 WebRTC Streaming
./run_sim.sh --streaming
```

### Q: GPU 使用率為 0%
```bash
# 確認 CUDA 正確
nvidia-smi dmon -s u

# 設定可見 GPU
export CUDA_VISIBLE_DEVICES=0
```

**📖 完整故障排除：** [../01-guides/remote_gpu_setup.md](../01-guides/remote_gpu_setup.md) § 常見問題

---

## 📚 完整文件索引

### 必讀文件（W6 開始前）
1. **[../README.md](../README.md)** - 文件總覽
2. **[../01-guides/quickstart_w6_w9.md](../01-guides/quickstart_w6_w9.md)** - 每日任務 Checklist
3. **[../01-guides/remote_gpu_setup.md](../01-guides/remote_gpu_setup.md)** - 遠端 GPU 完整配置

### 技術開發（W6-W9）
4. **[../02-design/gemini_vlm_backup.md](../02-design/gemini_vlm_backup.md)** - VLM 備案
5. **[../02-design/coordinate_transformation.md](../02-design/coordinate_transformation.md)** - 座標轉換
6. **[../02-design/search_fsm_design.md](../02-design/search_fsm_design.md)** - 尋物狀態機
7. **[../02-design/isaac_sim_integration.md](../02-design/isaac_sim_integration.md)** - Isaac Sim 整合
8. **[../03-testing/testing_plan.md](../03-testing/testing_plan.md)** - W9 測試計畫

---

## 🎯 W6 立即行動清單

### Day 1（環境配置）
- [ ] SSH 連入 GPU 伺服器
- [ ] 執行 `nvidia-smi` 確認 Quadro RTX 8000
- [ ] 安裝 ROS2 Humble
- [ ] 克隆專案 `git clone ...`

### Day 2（編譯測試）
- [ ] `rosdep install` 安裝依賴
- [ ] `colcon build` 編譯專案
- [ ] 驗證 ROS2 topics 正常

### Day 3-4（VLM 開發）
- [ ] 建立 `vision_vlm` 套件
- [ ] 整合 Gemini API
- [ ] 測試物體識別

### Day 5（整合測試）
- [ ] VLM 節點 + 現有系統整合
- [ ] 記錄測試結果

---

## 💡 成功的關鍵

### ✅ 您的優勢
1. **硬體頂級**：48GB VRAM 遠超需求
2. **無瓶頸**：可同時測試多種方案
3. **高穩定性**：Quadro 系列專為長時間運行設計

### 🚀 加速開發建議
1. **並行測試**：同時運行 2-4 個機器人驗證多機協作
2. **本地 VLM**：若 API 受阻，立即切換 LLaVA（您的 VRAM 足夠）
3. **高解析度**：用 1080p 相機提升 VLM 準確率

### ⚠️ 風險已降低
- **座標轉換**：Plan A（LiDAR 投影）+ Plan B（地面假設）雙保險
- **Isaac Sim**：go2_omniverse 完美匹配，安裝流程明確
- **VLM API**：可隨時切換本地推論（48GB 優勢）

---

## 📞 需要協助？

- **技術問題**：查閱 `docs/` 目錄對應文件
- **故障排除**：每份文件都有「常見問題」章節
- **團隊協作**：GitHub Issues + 每週會議

---

**有了 Quadro RTX 8000，您的專題成功率大幅提升！開始開發吧！🎉**

---

**文件版本：** v1.1（GPU 優化版）
**最後更新：** 2025/11/16
**適用 GPU：** NVIDIA Quadro RTX 8000 48GB
