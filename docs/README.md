# Go2 智慧尋物系統 - 開發文件總覽

**專案名稱：** 基於 Go2 機器狗的智慧陪伴與尋物系統
**開發階段：** W6-W9（核心功能開發）
**文件版本：** v1.1
**最後更新：** 2025/11/18

---

## 📚 文件導航

### 🎯 規劃與整合
| 文件 | 用途 | 適用對象 |
|------|------|---------|
| [integration_plan.md](./integration_plan.md) | **4 週技術整合路線圖**（W6-W9 詳細規劃） | 全體成員（必讀） |
| [quickstart_w6_w9.md](./quickstart_w6_w9.md) | **快速啟動指南**（每日任務 Checklist） | 開發者 |
| [dependency_management.md](./dependency_management.md) | **🆕 Python 依賴鎖定與版本管理指南** | 開發者（必讀！） |

### 🤖 核心技術開發
| 文件 | 技術領域 | 難度 | 預計時長 |
|------|---------|------|----------|
| [gemini_vlm_development.md](./gemini_vlm_development.md) | Gemini VLM 整合 | ⭐⭐⭐ | W6-W7 (2週) |
| [coordinate_transformation.md](./coordinate_transformation.md) | 座標轉換系統 | ⭐⭐⭐⭐ | W7-W8 (2週) |
| [search_fsm_design.md](./search_fsm_design.md) | 尋物狀態機 | ⭐⭐⭐ | W9 (1週) |

### 🎮 環境與工具
| 文件 | 內容 | 關鍵性 |
|------|------|--------|
| [environment_setup_ubuntu.md](./environment_setup_ubuntu.md) | Ubuntu + ROS2 + 專案基礎環境安裝流程 | 🔴 高 |
| [isaac_sim_integration.md](./isaac_sim_integration.md) | Isaac Sim + go2_omniverse 整合 | 🔴 高 |
| [remote_gpu_setup.md](./remote_gpu_setup.md) | **🆕 遠端 GPU 伺服器配置**（Quadro RTX 8000 48GB） | 🔴 高 |
| [package_structure.md](./package_structure.md) | 套件結構與依賴管理 | 🟡 中 |
| [testing_and_verification.md](./testing_and_verification.md) | **🆕 測試脚本與驗證指南**（TEST.sh 使用） | 🟡 中 |
| [webrtc_troubleshooting.md](./webrtc_troubleshooting.md) | **🆕 WebRTC 連接除錯指南**（aiortc 版本問題） | 🟡 中 |

### 🧪 測試與驗收
| 文件 | 目的 | 使用時機 |
|------|------|---------|
| [testing_plan.md](./testing_plan.md) | W9 端到端測試計畫 | W9 週末驗收 |

---

## 🚀 快速開始（新成員）

### 第 1 步：了解專案現況
```bash
# 閱讀順序：
1. ../Goal.md                    # 專案目標與時程
2. ../claude_plan.md             # 現況報告（55% 完成度）
3. ./integration_plan.md         # W6-W9 整合規劃
```

### 第 2 步：確保依賴版本合理且一致（🚨 重要！）
在開始任何開發前，**強烈建議** 先鎖定 Python 依賴版本，避免不同機器 / 不同時間安裝出現微妙差異：
```bash
# 強制安裝 requirements.txt 中目前指定的版本
uv pip install -r requirements.txt --force-reinstall

# 驗證 aiortc 版本（目前專案預期為 1.9.0）
python3 -c "import aiortc; print(f'aiortc: {aiortc.__version__}')"
```
⚠️ **提醒**：曾觀察到某些情況下，依賴解析會把 `aiortc` 拉到 1.14.0 以上並搭配 STUN 配置，導致 SCTP 握手問題；為降低風險，目前先建議固定在 1.9.0，詳細脈絡請見 [dependency_management.md](./dependency_management.md)。

### 第 3 步：驗證 WebRTC 連接
確保 Go2 機器人能正常連接：
```bash
# 啟動驅動（觀察是否能穩定連線與收到狀態資料）
bash start_go2_simple.sh

# 測試 stand 命令（檢查機器人是否站起來）
ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq "{topic: 'rt/api/sport/request', api_id: 1004}"
```
實務上，比較可靠的判斷方式是：
- 連線過程中 ICE / connection state 會進到 `completed` / `connected`；  
- data channel 狀態為 `open`；  
- 日誌中持續出現 `rt/lf/lowstate`、`rt/utlidar/robot_pose` 等訊息。  

若連接失敗（尤其是 `/con_notify` HTTP timeout 或 data channel 一直是 `connecting`），請參考 [webrtc_troubleshooting.md](./webrtc_troubleshooting.md)。

### 第 4 步：選擇開發任務
根據您的專長，選擇以下任務之一：

**任務 A：VLM 視覺識別**（Python, API 整合）
- 閱讀：[gemini_vlm_development.md](./gemini_vlm_development.md)
- 負責：Gemini API 整合、Detection2DArray 轉換

**任務 B：座標轉換**（數學、ROS2 TF2）
- 閱讀：[coordinate_transformation.md](./coordinate_transformation.md)
- 負責：LiDAR 投影、地面假設方案

**任務 C：尋物邏輯**（狀態機、Nav2）
- 閱讀：[search_fsm_design.md](./search_fsm_design.md)
- 負責：FSM 實作、Nav2 Action Client

**任務 D：模擬環境**（Isaac Sim, Orbit）
- 閱讀：[isaac_sim_integration.md](./isaac_sim_integration.md)
- 負責：環境部署、ROS2 橋接

### 第 5 步：開始開發
```bash
# 遵循每日進度指南
./quickstart_w6_w9.md

# 參考套件結構
./package_structure.md

# W9 測試驗收
./testing_plan.md
```

---

### 🖥️ 每次在 Ubuntu 啟動開發環境（常用指令）

每次開新 Terminal 建議先執行以下指令，載入 ROS2、uv 以及本專案 workspace：

```bash
source /opt/ros/humble/setup.bash
source "$HOME/.local/bin/env"

cd ~/ros2_ws
source .venv/bin/activate
source install/setup.bash
```

若要快速驗證導航（Nav2）是否正常，可執行：

```bash
export ROBOT_IP="192.168.12.1"
ros2 launch go2_robot_sdk robot.launch.py slam:=true nav2:=true
```

---

## 📊 文件對照表（Goal.md vs 開發文件）

| Goal.md 目標 | 對應開發文件 | 實作週次 |
|-------------|------------|---------|
| **W6：Gemini VLM API 整合** | [gemini_vlm_development.md](./gemini_vlm_development.md) | W6 |
| **W7：座標系統轉換開發 I** | [coordinate_transformation.md](./coordinate_transformation.md) § Plan A | W7 |
| **W8：座標系統轉換開發 II** | [coordinate_transformation.md](./coordinate_transformation.md) § TF2 | W8 |
| **W4/W8：Isaac Sim 入門與整合** | [isaac_sim_integration.md](./isaac_sim_integration.md) | W4, W8 |
| **W9：尋物邏輯與流程控制** | [search_fsm_design.md](./search_fsm_design.md) | W9 |
| **W9：系統測試** | [testing_plan.md](./testing_plan.md) | W9 |

---

## 🎯 關鍵技術決策

### 1. 模擬器選擇
**決策**：使用 `go2_omniverse`（Isaac Sim 2023.1.1 + Orbit 0.3.0）
**原因**：
- ✅ 完美符合 Goal.md 需求（Isaac Sim）
- ✅ ROS2 Humble 原生支援
- ✅ Nav2 + slam_toolbox 已驗證
- ✅ 開源且活躍維護

**替代方案**：Gazebo (Plan C，若 Isaac Sim 受阻)

---

### 2. 座標轉換方案
**Plan A（推薦）**：LiDAR 點雲投影法
- 優點：精度高（< 15cm）
- 缺點：計算複雜度高

**Plan B（備用）**：地面假設法
- 優點：計算簡單、延遲低
- 缺點：僅適用於地面物體

**Plan C（Demo 備案）**：預標註座標
- 用途：若轉換失敗，Demo 時手動提供座標

---

### 3. VLM API 選擇
**決策**：Google Gemini 2.0 Flash Exp
**原因**：
- ✅ 零樣本物體識別能力強
- ✅ 支援 Bounding Box 輸出
- ✅ 延遲適中（1-2 秒）
- ✅ 免費額度可用於開發

**替代方案**：COCO Detector (Plan C，本地推論)

---

## 📈 進度追蹤

### 完成度儀表板

| 模組 | W6 | W7 | W8 | W9 | 狀態 |
|------|----|----|----|----|------|
| **環境建置** | ✅ | | | | 100% |
| **VLM 節點** | 🟡 | ✅ | | | 進行中 |
| **座標轉換** | | 🟡 | ✅ | | 待開始 |
| **Isaac Sim** | | | 🟡 | | 待開始 |
| **尋物 FSM** | | | | 🟡 | 待開始 |
| **整合測試** | | | | ✅ | 待開始 |

圖例：
- ✅ 已完成
- 🟡 進行中
- ⬜ 待開始

---

## 🛠️ 開發工具與資源

### 必備工具
```bash
# ROS2 工具
ros2 topic list/echo/hz
ros2 node list/info
ros2 run tf2_tools view_frames
rviz2

# 開發工具
colcon build/test
pytest
rqt_graph
```

### 外部資源
- [ROS2 Humble 文件](https://docs.ros.org/en/humble/)
- [Nav2 官方教學](https://navigation.ros.org/)
- [Gemini API 文件](https://ai.google.dev/docs)
- [Isaac Sim 文件](https://docs.omniverse.nvidia.com/isaacsim/latest/)
- [go2_omniverse GitHub](https://github.com/abizovnuralem/go2_omniverse)

---

## ⚠️ 風險管理

### 高風險項目（Plan B/C 準備）

| 風險 | 影響 | Plan A | Plan B | Plan C |
|------|------|--------|--------|--------|
| **座標轉換誤差大** | 🔴 高 | LiDAR 投影 | 地面假設 | 手動標註 |
| **Isaac Sim 安裝失敗** | 🔴 高 | 本地安裝 | Docker | 純實機測試 |
| **Gemini API 不穩定** | 🟡 中 | 快取 + 降頻 | 預錄結果 | COCO 替代 |
| **Nav2 導航卡住** | 🟡 中 | 參數調整 | 超時重試 | 手動遙控 |

---

## 📞 支援與協作

### 問題回報
- **GitHub Issues**：標籤 `bug` / `help-wanted` / `question`
- **每週會議**：週五下午 3:00（RViz Demo + 問題討論）

### 程式碼審查
- **Pull Request 流程**：
  1. Fork → Feature Branch
  2. 完成功能 + 測試
  3. PR 至 `develop` 分支
  4. 至少 1 人 Review
  5. Merge

### 文件更新
- 若發現文件錯誤或需補充，請直接修改並提交 PR
- 重大變更需在週會中討論

---

## 🎓 學習路徑建議

### 新手（0-1 週）
1. ROS2 基礎教學（官方 Tutorials）
2. 閱讀 `../CLAUDE.md`（專案架構）
3. 執行 `quickstart_w6_w9.md` Day 1-2

### 進階（1-2 週）
1. TF2 座標轉換教學
2. Nav2 基礎概念
3. 實作一個簡單 ROS2 節點

### 專家（2+ 週）
1. Isaac Sim Orbit 教學
2. Action Client/Server 機制
3. 完整系統整合

---

## 📝 版本歷史

| 版本 | 日期 | 變更內容 | 作者 |
|------|------|---------|------|
| v1.2 | 2025/11/18 | 新增 dependency_management.md 與 webrtc_troubleshooting.md；更新快速開始流程 | Claude Code |
| v1.1 | 2025/11/18 | 新增 testing_and_verification.md（TEST.sh P0 完成） | Claude Code |
| v1.0 | 2025/11/16 | 初始版本（8 份文件） | Claude + FJU Team |

---

## 🎯 最終目標提醒

**W9 結束時應達成**：
- ✅ 端到端尋物成功率 > 70%
- ✅ VLM 識別準確率 > 85%
- ✅ 座標轉換誤差 < 15cm
- ✅ Nav2 導航成功率 > 90%
- ✅ 完整測試報告與 Demo 影片

---

**開發愉快！有任何問題請隨時翻閱對應文件！🚀**

---

**維護者：** FJU Go2 專題組
**聯絡方式：** GitHub Issues
**最後更新：** 2025/11/18
