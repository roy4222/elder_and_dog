# Python 依賴管理與版本鎖定指南

**重要性**: 🔴 高
**最後更新**: 2025/11/18
**作者**: Claude Code

---

## 📋 概述

本指南說明如何正確管理項目的 Python 依賴，降低版本衝突導致的隱蔽 bug 風險。

**重要說明**：  
- 2025/11/18 的一次除錯過程中，有觀察到「`aiortc 1.14.0 + STUN 配置`」會讓 SCTP 握手變得極不穩定，降回 `aiortc==1.9.0` 並移除 STUN 後，WebRTC 確實恢復正常。  
- 這是「已觀察到的高風險組合」，**不是唯一被 100% 證實的根本原因**，之後仍持續在 WSL2 / 原生 Linux / 不同固件版本上做交叉驗證。  
- 因此，本文件偏向「建議與風險提示」，而不是宣稱「所有 WebRTC 問題都一定是 aiortc 版本造成」。

---

## 🔍 版本問題的症狀

### WebRTC 連接故障案例（已觀察到的案例）

| 症狀 | 原因 | 解決方案 |
|------|------|--------|
| SCTP InitChunk timeout × 9（30+ 秒） | 某次環境下的 aiortc 1.14.0 + STUN 配置衝突 | 降級到 1.9.0，移除 STUN（該次案例有效） |
| Data channel 永遠停留在 "connecting" | 可能是 SCTP 握手問題（版本 / 網路 / WSL2 等） | 先確認版本與 STUN，再依 webrtc_troubleshooting.md 排查 |
| 感測器能接收但控制指令無效 | Data channel 未真正建立或 WebRTC 端口不可達 | 參考 webrtc_troubleshooting.md 中的診斷步驟 |

---

## 🚀 快速修復（如果遇到 WebRTC 問題）

```bash
# 步驟 1: 強制安裝目前專案預期的版本
uv pip install aiortc==1.9.0 --force-reinstall

# 步驟 2: 驗證版本
python3 -c "import aiortc; print(f'aiortc version: {aiortc.__version__}')"
# 輸出應該是: aiortc version: 1.9.0

# 步驟 3: 重新編譯驅動
colcon build --packages-select go2_robot_sdk

# 步驟 4: 測試連接
bash start_go2_simple.sh
# 日誌應顯示: "Robot validation successful" 和 "SCTP 握手成功！Data channel 在 0.5 秒後開啟"
```

---

## 📦 當前項目的 Python 依賴清單

### 核心依賴（aiortc WebRTC）

```
aiortc==1.9.0           # ⚠️ 必須是 1.9.0，不是 1.14.0！
aioice>=0.9.0,<1.0.0    # aiortc 的依賴，自動安裝
aiohttp                 # HTTP 客戶端
```

### ROS2 與機器人控制

```
rclpy                   # ROS2 Python 客戶端（來自系統 ROS2 安裝）
geometry-msgs           # ROS2 消息（來自 go2_interfaces）
nav2-msgs               # ROS2 導航消息
```

### 數據處理與科學計算（依實際需求選用）

```
numpy==1.26.4           # 數值計算（目前 requirements.txt 中指定的版本）
scipy                   # （可選）視 lidar/感測器演算法需要再安裝，相容版本請參考官方文件
opencv-python           # 影像處理
open3d                  # 3D 點雲處理
torch                   # PyTorch（可選，用於物體偵測）
torchvision             # PyTorch 視覺模組
```

### 密碼學與加密

```
pycryptodome            # Go2 WebRTC 密鑰加密
cryptography>=42.0.0    # aiortc 的依賴
```

### 工具與中間件

```
paho-mqtt               # MQTT 通訊（可選）
python-dotenv           # 環境變數管理
wasmtime                # WebAssembly 運行時（某些庫的依賴）
pydub                   # 語音處理
```

---

## ⚠️ 已知版本衝突與解決方案

### 1. **aiortc 自動升級問題（曾觀察到的案例）**

**問題（案例）**:
- 某次環境中，`requirements.txt` 指定 `aiortc==1.9.0`
- 但安裝時又被其他依賴拉到 1.14.0，並搭配 STUN 配置
- 在該組合下，確實觀察到 SCTP 握手長時間 timeout

**解決方案**:
```bash
# 方案 A: 強制安裝目前專案指定版本（推薦）
uv pip install aiortc==1.9.0 --force-reinstall

# 方案 B: 依 requirements.txt 重新安裝
uv pip install -r requirements.txt --force-reinstall

# 驗證
python3 -c "import aiortc; assert aiortc.__version__ == '1.9.0'"
```

### 2. **scipy 版本與 numpy 相容性**

**說明**：
- 專案目前只在 `requirements.txt` 中明確鎖定 `numpy==1.26.4`，未強制指定 `scipy` 版本。  
- 過去有在其他專案遇過「某些 scipy 版本與特定 numpy 組合」的相容性問題，因此建議一律**參考官方相容性矩陣**來選擇搭配。  
- 若你在本專案中額外安裝 `scipy` 並遇到錯誤，建議先檢查 numpy/scipy 版本是否為官方建議的組合，再視需要回報具體 case。

### 3. **PyTorch 與系統依賴**

**問題**:
- PyTorch 涉及 CUDA、cuDNN 等複雜依賴
- 不同系統的安裝方式不同

**解決方案**:
```bash
# 根據系統選擇正確的安裝命令
# CPU-only (最簡單)
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

# CUDA 12.1
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# 驗證
python3 -c "import torch; print(f'PyTorch: {torch.__version__}')"
```

---

## 🛠️ 推薦的依賴管理流程

### 新環境初始化（第一次開發時）

```bash
# 步驟 1: 安裝 ROS2（系統包）
sudo apt-get install ros-humble-desktop -y

# 步驟 2: 克隆專案
git clone <repo-url>
cd elder_and_dog

# 步驟 3: 創建 venv（推薦）
python3 -m venv .venv
source .venv/bin/activate

# 步驟 4: 強制安裝 requirements.txt
uv pip install -r requirements.txt --force-reinstall

# 步驟 5: 驗證關鍵依賴
python3 -c "
import aiortc
import numpy
import torch
print(f'aiortc: {aiortc.__version__}')
print(f'numpy: {numpy.__version__}')
print(f'torch: {torch.__version__}')
"

# 預期輸出:
# aiortc: 1.9.0
# numpy: 1.26.4
# torch: 2.x.x
```

### 日常開發（每次開始工作時）

```bash
# 驗證環境
source .venv/bin/activate
python3 -c "import aiortc; assert aiortc.__version__ == '1.9.0'"

# 如果版本錯誤，執行修復
uv pip install -r requirements.txt --force-reinstall

# 編譯項目
colcon build --symlink-install
```

### 遇到新的奇怪錯誤時

```bash
# 步驟 1: 檢查版本
pip freeze | grep -E "aiortc|numpy|scipy|torch"

# 步驟 2: 重新安裝所有依賴
uv pip install -r requirements.txt --force-reinstall --no-cache-dir

# 步驟 3: 清理 ROS2 構建
rm -rf build/ install/ log/
colcon build --cmake-force-configure

# 步驟 4: 重新啟動 ROS2 daemon
ros2 daemon stop
ros2 daemon start
```

---

## 📋 requirements.txt 最佳實踐

### 當前推薦格式

```
# requirements.txt - Go2 智慧尋物系統

# === WebRTC 連接 ===
aiortc==1.9.0              # ⚠️ 必須精確版本，不要用 ~= 或 >=
aiohttp                    # 自動選擇相容版本

# === 數據處理 ===
numpy==1.26.4
scipy==1.8.0              # 與 numpy 相容
opencv-python
open3d

# === 深度學習 ===
torch                     # 安裝時需選擇 CPU/CUDA 版本
torchvision

# === 加密與安全 ===
pycryptodome
cryptography>=42.0.0

# === 工具 ===
paho-mqtt
python-dotenv
wasmtime
pydub
```

### ✅ 好的做法

- ✅ 關鍵依賴（如 aiortc）使用 `==` 精確版本
- ✅ 次要依賴使用 `>=` 允許向上相容
- ✅ 添加註解說明為什麼選擇該版本
- ✅ 定期檢查是否有安全更新

### ❌ 不好的做法

- ❌ 所有依賴都用 `>=` 或 `~=`（容易導致版本地獄）
- ❌ 沒有註解說明版本選擇
- ❌ 使用太新的版本（測試不充分）

---

## 🔧 故障排除

### 症狀 1: ImportError

```
ModuleNotFoundError: No module named 'aiortc'
```

**原因**: 依賴未安裝
**解決**:
```bash
pip install -r requirements.txt --force-reinstall
```

### 症狀 2: 版本不匹配警告

```
DeprecationWarning: numpy.ufunc(...) is deprecated
```

**原因**: numpy/scipy 版本不相容
**解決**:
```bash
uv pip install numpy==1.26.4 scipy --force-reinstall
```

### 症狀 3: WebRTC SCTP 握手失敗

```
[aiortc.rtcsctptransport] x T1(InitChunk) expired 9
[go2_connection] ❌ SCTP 握手超時（>30.0秒）
```

**原因**: aiortc 版本錯誤（可能是 1.14.0）
**解決**:
```bash
pip install aiortc==1.9.0 --force-reinstall
colcon build --packages-select go2_robot_sdk
bash start_go2_simple.sh  # 驗證
```

---

## 📊 依賴版本對照表

| 套件 | 推薦版本 | 最小版本 | 最大版本 | 備註 |
|------|---------|---------|---------|------|
| aiortc | 1.9.0 | 1.9.0 | 1.9.0 | ⚠️ 目前專案鎖定版本（如需升級請先實測） |
| aioice | 0.10.1 | 0.9.0 | <1.0.0 | aiortc 依賴 |
| numpy | 1.26.4 | 1.24.0 | 1.26.4 | 目前 requirements.txt 指定版本 |
| scipy | - | - | - | 視實際需求與官方相容性建議選用 |
| torch | latest | 2.0.0 | - | CUDA 版本需選擇 |
| opencv-python | latest | 4.5.0 | - | 影像處理 |

---

## 🎯 檢查清單

部署前必須檢查：

- [ ] `aiortc==1.9.0` （驗證: `python3 -c "import aiortc; assert aiortc.__version__ == '1.9.0'"）
- [ ] WebRTC 連接測試通過（驗證: `bash start_go2_simple.sh` 顯示 "Robot validation successful"）
- [ ] 機器人控制命令生效（驗證: stand/sit 命令能使機器人動作）
- [ ] 感測器數據流正常（驗證: 日誌持續顯示 sportmodestate）

---

## 📚 參考資源

- [requirements.txt 最佳實踐](https://pip.pypa.io/en/stable/user_guide/#requirements-files)
- [aiortc GitHub](https://github.com/aiortc/aiortc) - 查看 Release Notes
- [Python Packaging Guide](https://packaging.python.org/specifications/version-specifiers/)

---

**最後提醒**: 版本管理看似簡單，卻是系統穩定性的基礎。花時間正確配置一次，勝過之後花時間調試 10 倍！
