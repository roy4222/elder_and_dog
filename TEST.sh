#!/usr/bin/env zsh

# ==========================================
# Go2 機器人測試腳本 - P0 核心功能
# ==========================================
# 用途：測試基本動作、感測器、系統狀態
# 版本：1.0（P0 - 基礎版）

set -e

# --- 全域變數 ---
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT="$SCRIPT_DIR"
WORKSPACE_ROOT=$(cd "$PROJECT_ROOT/../.." && pwd)
ROBOT_IP="${ROBOT_IP:-192.168.12.1}"

# --- 顏色定義 ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==========================================
# 環境檢查
# ==========================================

check_environment() {
  # 檢查 ROS2 是否 source
  if [ -z "$ROS_DISTRO" ]; then
    echo -e "${RED}✗ 錯誤：ROS2 環境未載入${NC}"
    echo ""
    echo "請執行："
    echo "  source /opt/ros/humble/setup.zsh"
    echo "  source $WORKSPACE_ROOT/install/setup.zsh"
    echo ""
    exit 1
  fi

  # 檢查 workspace 是否 source
  if [ -z "$AMENT_PREFIX_PATH" ] || ! echo "$AMENT_PREFIX_PATH" | grep -q "$WORKSPACE_ROOT/install"; then
    echo -e "${RED}✗ 錯誤：Workspace 未載入${NC}"
    echo ""
    echo "請執行："
    echo "  cd $WORKSPACE_ROOT"
    echo "  source install/setup.zsh"
    echo ""
    exit 1
  fi
}

check_driver() {
  # 檢查 go2_driver_node 是否運行
  if ! ros2 node list 2>/dev/null | grep -q go2_driver_node; then
    echo -e "${RED}✗ 錯誤：Go2 驅動節點未運行${NC}"
    echo ""
    echo "請先啟動驅動："
    echo "  cd $PROJECT_ROOT"
    echo "  zsh start_go2_simple.sh"
    echo ""
    exit 1
  fi
}

# ==========================================
# P0 - 基本動作控制
# ==========================================

cmd_sit() {
  echo -e "${CYAN}→ 執行：坐下${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1009}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_stand() {
  echo -e "${CYAN}→ 執行：站起${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1004}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_balance() {
  echo -e "${CYAN}→ 執行：平衡站立${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1002}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_standdown() {
  echo -e "${CYAN}→ 執行：站立改姿態（準備坐下）${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1005}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_risefit() {
  echo -e "${CYAN}→ 執行：從坐下站起${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1010}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_recovery() {
  echo -e "${CYAN}→ 執行：恢復站立（從摔倒恢復）${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1006}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_wallow() {
  echo -e "${CYAN}→ 執行：打滾（Wallow）${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1021}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_hello() {
  echo -e "${CYAN}→ 執行：打招呼${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1016}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_stretch() {
  echo -e "${CYAN}→ 執行：伸展${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1017}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_dance1() {
  echo -e "${CYAN}→ 執行：舞蹈 1${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1022}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_dance2() {
  echo -e "${CYAN}→ 執行：舞蹈 2${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1023}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_frontflip() {
  echo -e "${CYAN}→ 執行：前翻${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1030}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_frontjump() {
  echo -e "${CYAN}→ 執行：前跳${NC}"
  if ros2 topic pub --once /webrtc_req go2_interfaces/msg/WebRtcReq \
    "{topic: 'rt/api/sport/request', api_id: 1031}" 2>/dev/null; then
    echo -e "${GREEN}✓ 指令已發送${NC}"
  else
    echo -e "${RED}✗ 發送失敗${NC}"
    return 1
  fi
}

cmd_forward() {
  echo -e "${CYAN}→ 執行：前進 3 秒（速度 0.3 m/s）${NC}"
  (ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.3, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
    -r 10 2>/dev/null) &
  local pid=$!
  sleep 3
  kill $pid 2>/dev/null || true
  ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
    2>/dev/null
  echo -e "${GREEN}✓ 前進完成${NC}"
}

cmd_backward() {
  echo -e "${CYAN}→ 執行：後退 3 秒（速度 -0.3 m/s）${NC}"
  (ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: -0.3, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
    -r 10 2>/dev/null) &
  local pid=$!
  sleep 3
  kill $pid 2>/dev/null || true
  ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
    2>/dev/null
  echo -e "${GREEN}✓ 後退完成${NC}"
}

cmd_left() {
  echo -e "${CYAN}→ 執行：左轉 3 秒（角速度 0.5 rad/s）${NC}"
  (ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.5}}" \
    -r 10 2>/dev/null) &
  local pid=$!
  sleep 3
  kill $pid 2>/dev/null || true
  ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
    2>/dev/null
  echo -e "${GREEN}✓ 左轉完成${NC}"
}

cmd_right() {
  echo -e "${CYAN}→ 執行：右轉 3 秒（角速度 -0.5 rad/s）${NC}"
  (ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: -0.5}}" \
    -r 10 2>/dev/null) &
  local pid=$!
  sleep 3
  kill $pid 2>/dev/null || true
  ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
    2>/dev/null
  echo -e "${GREEN}✓ 右轉完成${NC}"
}

cmd_stop() {
  echo -e "${CYAN}→ 執行：停止${NC}"
  if ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
    "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
    2>/dev/null; then
    echo -e "${GREEN}✓ 停止${NC}"
  else
    echo -e "${RED}✗ 停止失敗${NC}"
    return 1
  fi
}

# ==========================================
# P0 - 感測器監測
# ==========================================

monitor_joint() {
  echo -e "${CYAN}→ 監測關節狀態（按 Ctrl+C 停止）${NC}"
  echo ""
  timeout 10s ros2 topic echo /joint_states 2>/dev/null | head -50 || true
  echo ""
  echo -e "${GREEN}✓ 監測完成${NC}"
}

monitor_imu() {
  echo -e "${CYAN}→ 監測 IMU 數據（按 Ctrl+C 停止）${NC}"
  echo ""
  timeout 10s ros2 topic echo /imu 2>/dev/null | head -50 || true
  echo ""
  echo -e "${GREEN}✓ 監測完成${NC}"
}

monitor_lidar() {
  echo -e "${CYAN}→ 監測 LiDAR 頻率與點數（持續 5 秒）${NC}"
  echo ""
  timeout 5s ros2 topic hz /point_cloud2 2>/dev/null || true
  echo ""
  echo -e "${GREEN}✓ 監測完成${NC}"
}

monitor_odom() {
  echo -e "${CYAN}→ 監測里程計（按 Ctrl+C 停止）${NC}"
  echo ""
  timeout 10s ros2 topic echo /odom 2>/dev/null | head -50 || true
  echo ""
  echo -e "${GREEN}✓ 監測完成${NC}"
}

monitor_state() {
  echo -e "${CYAN}→ 監測機器狀態（按 Ctrl+C 停止）${NC}"
  echo ""
  if ros2 topic list 2>/dev/null | grep -q "^/go2_states\$"; then
    timeout 10s ros2 topic echo /go2_states 2>/dev/null | head -50 || true
  else
    echo -e "${YELLOW}ℹ️  /go2_states topic 不存在（可能需啟用其他參數）${NC}"
  fi
  echo ""
  echo -e "${GREEN}✓ 監測完成${NC}"
}

# ==========================================
# P0 - 坐下命令驗證（測試序列）
# ==========================================

posture_test() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  坐下命令驗證序列${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo -e "${YELLOW}本測試將系統地驗證所有坐下/站起相關命令的實際行為${NC}"
  echo ""
  echo -e "${YELLOW}✓ 測試計劃：${NC}"
  echo "  1. 確認機器人當前狀態（應站立）"
  echo "  2. 執行 standdown (api_id: 1005) - 預期：站立改姿態準備坐下"
  echo "  3. 執行 sit (api_id: 1009) - 預期：坐下（下半身坐下或完全坐下？）"
  echo "  4. 執行 risefit (api_id: 1010) - 預期：從坐下站起"
  echo "  5. 執行 stand (api_id: 1004) - 預期：完全站起"
  echo ""
  echo -e "${CYAN}開始測試序列...${NC}"
  echo ""

  # 步驟 1: 確認當前狀態
  echo -e "${YELLOW}[步驟 1/5] 檢查當前狀態（等待 2 秒讓機器人穩定）${NC}"
  sleep 2
  echo -e "${GREEN}✓ 請觀察機器人狀態${NC}"
  echo ""

  # 步驟 2: standdown
  echo -e "${YELLOW}[步驟 2/5] 執行 standdown (api_id: 1005)${NC}"
  cmd_standdown
  echo -e "${CYAN}等待 3 秒讓機器人完成動作...${NC}"
  sleep 3
  echo -e "${GREEN}✓ 請觀察機器人是否改變姿態（但仍站立）${NC}"
  echo ""

  # 步驟 3: sit
  echo -e "${YELLOW}[步驟 3/5] 執行 sit (api_id: 1009)${NC}"
  cmd_sit
  echo -e "${CYAN}等待 3 秒讓機器人完成動作...${NC}"
  sleep 3
  echo -e "${GREEN}✓ 請觀察機器人是否：${NC}"
  echo "    - 只有下半身坐下？"
  echo "    - 完全坐下（屁股著地）？"
  echo ""

  # 步驟 4: risefit
  echo -e "${YELLOW}[步驟 4/5] 執行 risefit (api_id: 1010)${NC}"
  cmd_risefit
  echo -e "${CYAN}等待 3 秒讓機器人完成動作...${NC}"
  sleep 3
  echo -e "${GREEN}✓ 請觀察機器人是否從坐下狀態站起${NC}"
  echo ""

  # 步驟 5: stand
  echo -e "${YELLOW}[步驟 5/5] 執行 stand (api_id: 1004)${NC}"
  cmd_stand
  echo -e "${CYAN}等待 3 秒讓機器人完成動作...${NC}"
  sleep 3
  echo -e "${GREEN}✓ 機器人應回到完全站立狀態${NC}"
  echo ""

  # 測試完成
  echo -e "${BLUE}========================================${NC}"
  echo -e "${GREEN}✓ 測試序列完成${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo -e "${YELLOW}📝 記錄結果（請根據實際觀察更新）：${NC}"
  echo ""
  echo "API ID | 命令名稱  | 實際行為 | 說明"
  echo "-------|----------|--------|-----"
  echo "1005   | standdown | ??     | 需觀察"
  echo "1009   | sit       | ??     | 需觀察（下半身 vs 完全坐下）"
  echo "1010   | risefit   | ??     | 需觀察"
  echo "1004   | stand     | ??     | 需觀察"
  echo ""
  echo -e "${CYAN}請將觀察結果回報到 GitHub Issues 或開發文件中${NC}"
  echo ""
}

# ==========================================
# P0 - 系統診斷
# ==========================================

system_health() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  系統健康檢查${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  # 檢查關鍵節點
  echo -e "${YELLOW}📊 節點狀態：${NC}"
  local nodes=("go2_driver_node" "robot_state_publisher" "pointcloud_aggregator")
  local all_nodes=$(ros2 node list 2>/dev/null)
  for node in "${nodes[@]}"; do
    if echo "$all_nodes" | grep -q "$node"; then
      echo -e "  ${GREEN}✓${NC} $node: 運行中"
    else
      echo -e "  ${RED}✗${NC} $node: 未運行"
    fi
  done
  echo ""

  # 檢查關鍵 topics
  echo -e "${YELLOW}📡 Topic 狀態：${NC}"
  local topics=("/cmd_vel" "/joint_states" "/imu" "/point_cloud2")
  local all_topics=$(ros2 topic list 2>/dev/null)
  for topic in "${topics[@]}"; do
    if echo "$all_topics" | grep -q "^$topic\$"; then
      echo -e "  ${GREEN}✓${NC} $topic: 可用"
    else
      echo -e "  ${RED}✗${NC} $topic: 無此 topic"
    fi
  done
  echo ""

  # 檢查版本
  echo -e "${YELLOW}⚙️  版本信息：${NC}"
  local numpy_ver=$(python3.10 -c "import numpy; print(numpy.__version__)" 2>/dev/null || echo "N/A")
  local scipy_ver=$(python3.10 -c "import scipy; print(scipy.__version__)" 2>/dev/null || echo "N/A")
  echo -e "  NumPy: $numpy_ver"
  echo -e "  SciPy: $scipy_ver"
  echo ""

  # 已知警告
  echo -e "${YELLOW}⚠️  已知問題（通常可忽略）：${NC}"
  echo "  - NumPy/SciPy: 已升級為相容版本（numpy 1.24.4）"
  echo "  - ffmpeg: 若缺失，TTS 會警告（非關鍵）"
  echo "  - ELEVENLABS_API_KEY: 未設定時 tts_node 失敗（非關鍵）"
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${GREEN}✓ 檢查完成${NC}"
  echo ""
}

list_topics() {
  echo -e "${CYAN}所有可用的 Topics：${NC}"
  echo ""
  ros2 topic list 2>/dev/null | sort
  echo ""
  echo -e "共 $(ros2 topic list 2>/dev/null | wc -l) 個 topics"
}

list_nodes() {
  echo -e "${CYAN}所有運行的節點：${NC}"
  echo ""
  ros2 node list 2>/dev/null | sort
  echo ""
  echo -e "共 $(ros2 node list 2>/dev/null | wc -l) 個節點"
}

show_help() {
  cat << 'EOF'

Go2 機器人測試腳本 - P0 核心版

使用方式：
  zsh TEST.sh <命令>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
基本姿態控制：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  sit                  坐下（下半身坐下）
  stand                站起
  balance              平衡站立
  standdown            站立改姿態（準備坐下）
  risefit              從坐下站起
  recovery             恢復站立（從摔倒恢復）

娛樂動作：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  wallow               打滾
  hello                打招呼
  stretch              伸展
  dance1               舞蹈 1
  dance2               舞蹈 2
  flip                 前翻
  jump                 前跳

移動控制：
  forward              向前 3 秒（0.3 m/s）
  backward             向後 3 秒（-0.3 m/s）
  left                 左轉 3 秒（0.5 rad/s）
  right                右轉 3 秒（-0.5 rad/s）
  stop                 停止

感測器監測：
  joint                關節狀態
  imu                  IMU 數據
  lidar                LiDAR 頻率
  odom                 里程計
  state                機器狀態

系統診斷：
  posture-test         坐下命令驗證序列（自動化測試）
  health               系統健康檢查
  list-topics          列出所有 topics
  list-nodes           列出所有節點
  help                 顯示此幫助

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
例子：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  zsh TEST.sh sit
  zsh TEST.sh forward
  zsh TEST.sh health
  zsh TEST.sh imu

前置條件：
  1. 啟動驅動：cd /home/roy422/ros2_ws/src/elder_and_dog && zsh start_go2_simple.sh
  2. 載入環境：source /opt/ros/humble/setup.zsh && source install/setup.zsh
  3. 設定機器人IP：export ROBOT_IP="192.168.12.1"

EOF
}

# ==========================================
# 主程式入口
# ==========================================

main() {
  # 環境檢查
  check_environment
  check_driver

  # 無參數時顯示幫助
  if [ $# -eq 0 ]; then
    show_help
    return 0
  fi

  # 根據命令執行
  case "$1" in
    # 基本姿態控制
    sit)        cmd_sit ;;
    stand)      cmd_stand ;;
    balance)    cmd_balance ;;
    standdown)  cmd_standdown ;;
    risefit)    cmd_risefit ;;
    recovery)   cmd_recovery ;;

    # 娛樂動作
    wallow)     cmd_wallow ;;
    hello)      cmd_hello ;;
    stretch)    cmd_stretch ;;
    dance1)     cmd_dance1 ;;
    dance2)     cmd_dance2 ;;
    flip)       cmd_frontflip ;;
    jump)       cmd_frontjump ;;

    # 移動控制
    forward)  cmd_forward ;;
    backward) cmd_backward ;;
    left)     cmd_left ;;
    right)    cmd_right ;;
    stop)     cmd_stop ;;

    # 感測器監測
    joint)    monitor_joint ;;
    imu)      monitor_imu ;;
    lidar)    monitor_lidar ;;
    odom)     monitor_odom ;;
    state)    monitor_state ;;

    # 系統診斷
    posture-test) posture_test ;;
    health)       system_health ;;
    list-topics)  list_topics ;;
    list-nodes)   list_nodes ;;
    help)         show_help ;;

    # 未知命令
    *)
      echo -e "${RED}✗ 未知指令：$1${NC}"
      echo ""
      echo "使用 'zsh TEST.sh help' 查看所有可用命令"
      exit 1
      ;;
  esac
}

# 執行主程式
main "$@"
