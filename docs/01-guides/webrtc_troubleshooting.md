# WebRTC 連接除錯指南

**重要性**: 🔴 高
**最後更新**: 2025/11/18
**作者**: Claude Code
**關鍵症狀**: SCTP InitChunk timeout、Data channel 停留在 "connecting"

---

## 📋 概述

本指南針對 Go2 機器狗 WebRTC 連接問題提供系統化的除錯流程，包含**目前已觀察到的常見風險組合**，但不宣稱所有問題都有單一根本原因。

**重要說明 (2025/11/18)**：
- 在某次實驗中，確實觀察到「`aiortc 1.14.0 + STUN 配置`」會導致 SCTP 握手長時間 timeout，降級為 `aiortc 1.9.0` 並移除 STUN 後，當次問題獲得解決。  
- 不過，後續也觀察到其他失敗型態（例如：`/con_notify` HTTP timeout、WSL2 下偶發網路問題、機器端模式 / App 佔線等），**因此目前立場是「aiortc 版本不匹配是高風險因素之一」，而不是唯一的 root cause**。
- 若你遇到的是 HTTP 連線 timeout、ICE 無法完成等情況，請參考本文後半段針對網路 / 機器狀態的檢查步驟。

---

## 🔴 快速診斷清單

如果你遇到 WebRTC 問題，按以下順序執行：

### 步驟 1：檢查 aiortc 版本（建議先做）
```bash
python3 -c "import aiortc; print(f'aiortc version: {aiortc.__version__}')"
```

**預期結果**：`aiortc version: 1.9.0`

**如果版本是 1.14.0 或更新**：建議先回到目前專案穩定使用的 1.9.0 測一次
```bash
uv pip install aiortc==1.9.0 --force-reinstall
```

### 步驟 2：驗證連接是否恢復
```bash
# 停止任何正在運行的驅動
pkill -f go2_driver_node

# 重新啟動驅動（觀察是否能穩定建立連線與收到狀態資料）
bash start_go2_simple.sh
```

**實務建議**：  
- 目前驅動程式的 log 文案會隨版本演進，**不一定**會出現「Robot validation successful」或「SCTP 握手成功！」這類字眼。  
- 比較可靠的判斷方式是：  
  - ICE / connection state 有進到 `completed` / `connected`；  
  - data channel 狀態為 `open`；  
  - 日誌中持續出現 `rt/lf/lowstate`、`rt/utlidar/robot_pose` 等訊息（代表資料有穩定流動）。

### 步驟 3：測試機器人控制
```bash
# 測試 stand 命令
ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq "{topic: 'rt/api/sport/request', api_id: 1004}"

# 檢查機器人是否站起來（body_height 應從 0.313 增加到 0.326）
# 觀察日誌中的 sportmodestate 或使用 RViz 查看機器人姿態
```

**若以上步驟解決問題，恭喜！** 👏  
請閱讀 [dependency_management.md](./dependency_management.md) 的「最佳實踐」部分，避免未來因套件升級再次踩到類似問題。  

**若問題仍存在**（尤其是 HTTP timeout / 無法連到 `/con_notify`），請往下看「HTTP /con_notify 相關問題」與「WSL2 特定問題排查」。

---

## 🔍 症狀與根本原因對應表

### 症狀 1：Data Channel 永遠停留在 "connecting"

**日誌表現**：
```
WARNING:go2_robot_sdk.infrastructure.webrtc.go2_connection:Data channel is not open. State is connecting
WARNING:go2_robot_sdk.infrastructure.webrtc.go2_connection:❌ SCTP 握手超時（>30.0秒）
```

**常見原因**：
| 原因 | 優先度 | 解決方案 |
|------|-------|--------|
| aiortc 版本 1.14.0+ | 🔴 P0 | 降級到 1.9.0 |
| STUN 配置衝突 | 🔴 P0 | 移除 RTCConfiguration |
| pip 自動升級依賴 | 🔴 P0 | 使用 `--force-reinstall` |
| 網路 NAT 問題 | 🟡 P1 | 檢查 WiFi 連接 |
| Go2 固件版本過舊 | 🟡 P2 | 更新固件 |

---

### 症狀 2：SCTP InitChunk Timeout

**日誌表現**：
```
[aiortc.rtcsctptransport] > InitChunk(flags=0)
[aiortc.rtcsctptransport] x T1(InitChunk) expired 1
[aiortc.rtcsctptransport] x T1(InitChunk) expired 2
[aiortc.rtcsctptransport] x T1(InitChunk) expired 3
[aiortc.rtcsctptransport] x T1(InitChunk) expired 4
[aiortc.rtcsctptransport] x T1(InitChunk) expired 5
[aiortc.rtcsctptransport] x T1(InitChunk) expired 6
[aiortc.rtcsctptransport] x T1(InitChunk) expired 7
[aiortc.rtcsctptransport] x T1(InitChunk) expired 8
[aiortc.rtcsctptransport] x T1(InitChunk) expired 9
```

**含義**：aiortc 嘗試 9 次發送 SCTP 初始化包，但機器人端未回應

**可能原因之一（案例）**：曾觀察到在「aiortc 1.14.0 + STUN 配置」的組合下，SCTP 層有相容性問題，導致握手一直重試。  
實務上還需要同時檢查：WSL2 網路、機器當下模式、是否有 App 佔線等因素。

**解決方案**：
1. 檢查版本並降級：`uv pip install aiortc==1.9.0 --force-reinstall`
2. 確認未添加不必要的 STUN 配置

---

### 症狀 3：機器人無法接收控制指令

**現象**：
- Data channel 報告已開啟 (state = open)
- WebRTC 連接成功
- 但 `/webrtc_req` 發出的指令（stand、sit、forward 等）無效
- 機器人沒有任何反應

**診斷步驟**：
```bash
# 確認 data channel 真的已開啟
ros2 topic echo /go2_driver_status | grep -i "webrtc\|data_channel"

# 檢查 aiortc 版本
python3 -c "import aiortc; print(f'aiortc: {aiortc.__version__}')"

# 查看 go2_driver_node 是否有相關錯誤日誌
ros2 node info /go2_driver_node
```

**最可能原因**：SCTP 握手表面成功但實際未完全建立
**解決方案**：同症狀 1，降級 aiortc 並移除 STUN

---

## 📊 WebRTC 握手完整流程（四階段）

要理解 WebRTC 如何連接到 Go2 機器人，需要了解四個階段的握手過程：

```
┌─────────────────────────────────────────────────────────────────┐
│                    WebRTC 握手四階段                              │
└─────────────────────────────────────────────────────────────────┘

階段 1: SDP 交換
├─ 目的：交換媒體能力和網路地址
├─ 參與者：aiortc (ROS2) ← HTTP 加密通道 → Go2 機器人
├─ 驗證方式：檢查日誌是否有 "offer/answer" 訊息
└─ 失敗表現：HTTP 連接失敗或超時

階段 2: ICE 連接（Interactive Connectivity Establishment）
├─ 目的：找到可通訊的 UDP 路徑
├─ 參與者：aiortc ← UDP candidates → Go2 機器人
├─ 驗證方式：檢查 "iceConnectionState: completed"
└─ 失敗表現：ICE state 停留在 "checking" 或 "disconnected"

階段 3: DTLS 握手（Datagram Transport Layer Security）
├─ 目的：建立加密通道
├─ 參與者：aiortc ← DTLS handshake → Go2 機器人
├─ 驗證方式：檢查 "connectionState: connected" 和 SRTP 協商
└─ 失敗表現：DTLS handshake timeout 或 "alert (protocol_version)"

階段 4: SCTP 握手（Stream Control Transmission Protocol）
├─ 目的：建立可靠的雙向數據通道
├─ 參與者：aiortc ← SCTP InitChunk → Go2 機器人
├─ 驗證方式：檢查 "data channel state: open"
└─ 失敗表現：InitChunk timeout × 9（當前問題所在！）
```

### 健康連接的日誌跡象

```
✅ Phase 1 - SDP 交換成功
  INFO:go2_robot_sdk.infrastructure.webrtc.go2_connection:HTTP 加密通道建立

✅ Phase 2 - ICE 連接成功
  [aioice.ice] ICE completed
  [aiortc.rtcpeerconnection] iceConnectionState: new -> checking -> completed

✅ Phase 3 - DTLS 握手成功
  [aiortc.rtcdtlstransport] DTLS handshake negotiated SRTP_AES128_CM_SHA1_80
  [aiortc.rtcdtlstransport] State.CONNECTING -> State.CONNECTED

✅ Phase 4 - SCTP 握手成功
  [aiortc.rtcsctptransport] > InitChunk(flags=0)
  [aiortc.rtcsctptransport] < InitChunk_ACK
  [aiortc.rtcsctptransport] SCTP handshake complete
  INFO:go2_robot_sdk.infrastructure.webrtc.go2_connection:✅ Data channel 開啟
```

---

## 🛠️ 故障排除詳細步驟

### 情況 A：遇到 SCTP InitChunk Timeout

**步驟 1：驗證版本**
```bash
python3 << 'EOF'
import aiortc
import aioice
import numpy
print(f"aiortc: {aiortc.__version__}")
print(f"aioice: {aioice.__version__}")
print(f"numpy: {numpy.__version__}")
EOF
```

**預期版本對照**：
| 套件 | 正確版本 | 故障版本 |
|-----|---------|--------|
| aiortc | 1.9.0 | 1.14.0+ |
| aioice | 0.9.x 或 0.10.x | 無特定限制 |

**步驟 2：如果版本不符，執行修復**
```bash
# 強制重新安裝指定版本
uv pip install aiortc==1.9.0 --force-reinstall --no-cache-dir

# 驗證修復成功
python3 -c "import aiortc; assert aiortc.__version__ == '1.9.0', f'版本仍為 {aiortc.__version__}'"
```

**步驟 3：清理舊的編譯產物**
```bash
cd ~/ros2_ws
rm -rf build/ install/ log/
colcon build --packages-select go2_robot_sdk
```

**步驟 4：重新啟動驅動並驗證**
```bash
# 殺死舊進程
pkill -f go2_driver_node
sleep 2

# 啟動驅動
bash start_go2_simple.sh

# 觀察日誌（應在 0.5 秒內完成 SCTP 握手）
```

---

### 情況 B：更新 requirements.txt 後出現新的 WebRTC 問題

**常見原因之一**：pip/uv 在解析依賴時，從其他套件的依賴鏈把 aiortc 升級到了新版，而 requirements.txt 沒有鎖死。

**症狀**：
```
uv pip install -r requirements.txt
# → aiortc 被升級到 1.14.0（可能來自 torch/torchvision 依賴鏈）
```

**解決方案**：
```bash
# 方案 1：重新安裝並明確指定版本
uv pip install -r requirements.txt --force-reinstall
uv pip install aiortc==1.9.0 --force-reinstall

# 方案 2：更新 requirements.txt，添加明確的版本註解
# 編輯 requirements.txt，確保有：
#   aiortc==1.9.0  # ⚠️ 必須精確到 1.9.0，不可用 >= 或 ~=

# 方案 3：使用 pip-compile 生成 lock 檔（進階）
uv pip install pip-compile-multi
pip-compile-multi --generate-hashes
```

詳見 [dependency_management.md](./dependency_management.md) 的「pip 依賴自動升級問題」章節。

---

### 情況 C：HTTP /con_notify 相關問題（目前最新觀察）

在某些情況下，可以看到 ICE / SDP/ DTLS 看起來都正常，但在**步驟 2 取得機器人公鑰**時就卡住，例如：

```text
go2_robot_sdk.infrastructure.webrtc.http_client - DEBUG - Making POST request to http://192.168.12.1:9991/con_notify
...
ERROR - Connection error when requesting http://192.168.12.1:9991/con_notify: ...
ConnectTimeoutError(..., 'Connection to 192.168.12.1 timed out. (connect timeout=10.0)')
```

這種情況多半與**機器端 / 網路狀態**有關，而非 aiortc 版本本身：

**建議檢查步驟（請在與驅動相同機器上執行）**：

```bash
# 1. 確認基本連通性
ping -c 4 192.168.12.1

# 2. 直接測試 HTTP 服務是否有回應（5 秒 timeout）
curl -v http://192.168.12.1:9991/con_notify --max-time 5
```

- 若 `ping` OK 但 `curl` 一直 timeout：  
  - 可能是 Go2 沒有開啟 WebRTC 控制模式、手機 App 佔線、或機器端 HTTP 服務沒有啟動。  
  - 建議：  
    - 確認手機 App 已關閉 / 退出控制模式；  
    - 確認 Go2 處於允許 PC WebRTC 控制的模式；  
    - 重新開關機器人或從官方 App 重新進入對應模式後再試一次。  
- 若 `ping` 也失敗：  
  - 優先檢查網段設定、網路線 / WiFi 連線，以及 WSL2 虛擬網卡設定。  

當 `/con_notify` 都無法透過 `curl` 成功，Python 驅動自然也會在同一步驟 timeout，這時應先定位為**網路 / 機器狀態**問題，而不是第一時間再去調 aiortc 或 STUN。

---

### 情況 D：WSL2 特定問題排查

如果在 WSL2 上仍有 SCTP 握手失敗，可能涉及 WSL2 的 SCTP 核心支援限制：

**檢查 WSL2 SCTP 支援**：
```bash
# 檢查內核是否啟用 SCTP
cat /proc/modules | grep sctp

# 檢查 Go2 機器人和 WSL2 是否在同一網段
ip route show
# 應該看到 192.168.x.x 路由指向某個 interface
```

**若 SCTP 核心模組未載入**：
```bash
# 在 WSL2 Ubuntu 中嘗試載入
sudo modprobe sctp

# 如果失敗，可能需要在 Windows PowerShell 更新 WSL2 內核
wsl --update
```

**替代方案**：在原生 Linux（非 WSL2）環境上測試，以排除 WSL2 特定問題。  
建議：若在 WSL2 下偶發連線問題（例如有時成功、有時 `/con_notify` timeout），可以在一台乾淨的 Ubuntu 機器上重複相同步驟，比較 log，協助判斷問題層級。

---

## 📈 版本對照與相容性表

| 環境/症狀 | aiortc | STUN 配置 | 結果 | 備註 |
|---------|--------|---------|------|------|
| **工作環境** | 1.9.0 | 無 | ✅ SCTP 0.5秒成功 | 推薦配置 |
| **故障環境** | 1.14.0 | 有（RTCConfiguration） | ❌ SCTP timeout 30秒 | 本次發現的問題 |
| **測試環境** | 1.14.0 | 無 | ? 未確認 | 等待測試 |
| **升級環境** | 1.15.0+ | 任意 | ? 未知 | 謹慎升級 |

---

## 🔧 進階除錯技巧

### 啟用完整 WebRTC 日誌

若以上簡單步驟未能解決問題，啟用詳細日誌以蒐集更多診斷資訊：

```bash
# 編輯 go2_driver_node.py，將 logging level 改為 DEBUG
# 檔案：go2_robot_sdk/go2_robot_sdk/presentation/go2_driver_node.py

# 修改：
logging.basicConfig(level=logging.DEBUG)

# 然後重建
colcon build --packages-select go2_robot_sdk

# 執行驅動並導出完整日誌
bash start_go2_simple.sh 2>&1 | tee webrtc_debug.log

# 上傳 webrtc_debug.log 供檢查
```

### 使用 CycloneDDS 驗證控制通路

若懷疑問題不在 WebRTC 而在其他通訊層：

```bash
# 關閉 WebRTC，改用 CycloneDDS 測試
export CONN_TYPE="cyclonedds"
bash start_go2_simple.sh

# 如果 CycloneDDS 能正常控制機器人（stand/sit 命令有反應）
# 但 WebRTC 失敗，問題明確是 WebRTC 層的
```

### 監控 SCTP 握手時序

在 go2_connection.py 中已內置 `_monitor_sctp_handshake()` 方法，會在 30 秒後輸出診斷訊息：

```
⏱️ SCTP 握手監控（監控時間：30.0秒）
Data channel state: closed
Connection state: connected
ICE connection state: completed
Ice gathering state: complete
```

若 `data_channel_state: closed` 且 `connection_state: connected`，表示握手確實卡在 SCTP 層。

---

## 🎯 預防未來 WebRTC 問題

### 1. 定期驗證版本

每次啟動開發環境前執行（選擇性，但推薦）：
```bash
python3 -c "import aiortc; assert aiortc.__version__ == '1.9.0', f'aiortc 版本異常：{aiortc.__version__}'"
```

可加入 shell alias 方便使用：
```bash
echo "alias check-versions='python3 -c \"import aiortc; print(f\\'aiortc: {aiortc.__version__}\\')\"'" >> ~/.bashrc
source ~/.bashrc
check-versions
```

### 2. 鎖定 requirements.txt

確保 requirements.txt 中 aiortc 使用精確版本（不使用 `>=` 或 `~=`）：
```
# ✅ 正確
aiortc==1.9.0

# ❌ 避免
aiortc>=1.9.0
aiortc~=1.9
```

### 3. 使用 --force-reinstall 安裝

每次重新安裝依賴時加上 `--force-reinstall` 旗標：
```bash
uv pip install -r requirements.txt --force-reinstall --no-cache-dir
```

### 4. 定期更新 dev_notes

若遇到新的 WebRTC 問題，應立即更新本文件和 [dependency_management.md](./dependency_management.md)，防止他人重複踩坑。

---

## 📚 相關文件

- **[dependency_management.md](./dependency_management.md)**：Python 依賴版本管理詳細指南
- **[README.md](./README.md) 快速開始**：新成員入門檢查清單
- **go2_robot_sdk/infrastructure/webrtc/go2_connection.py**：WebRTC 連接實作原始碼
- **docs/dev_notes/2025-11-18-dev.md**：完整的診斷過程與技術分析

---

## 🆘 仍未解決？

若上述所有步驟都無法解決問題，請進行以下操作：

1. **收集診斷資訊**
   ```bash
   # 導出完整日誌
   bash start_go2_simple.sh 2>&1 | tee webrtc_debug.log

   # 導出版本訊息
   python3 << 'EOF'
   import aiortc, aioice, numpy
   print(f"aiortc: {aiortc.__version__}")
   print(f"aioice: {aioice.__version__}")
   print(f"numpy: {numpy.__version__}")
   import platform
   print(f"Python: {platform.python_version()}")
   print(f"System: {platform.system()}")
   EOF
   ```

2. **上傳 Issue**
   - 標題：`WebRTC SCTP 握手失敗 - 完整日誌與版本訊息`
   - 附件：`webrtc_debug.log` + 上述版本訊息
   - 描述：清楚說明現象、已執行的步驟、預期行為

3. **聯絡技術支援**
   - Unitree RoboVerse 社群：https://github.com/unitreerobotics/RoboVerse
   - Go2 官方 GitHub Issues

---

## 📝 更新歷史

| 日期 | 版本 | 變更 | 作者 |
|------|------|------|------|
| 2025/11/18 | v1.0 | 初始版本（根據 SCTP 診斷報告） | Claude Code |

---

**最後提醒**：大多數 WebRTC 問題可透過版本鎖定和正確的環境設定解決。若遇到新症狀，請優先檢查 aiortc 版本！

**開發愉快！🚀**
