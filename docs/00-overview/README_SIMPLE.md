╔════════════════════════════════════════════════════════════════════════════╗
║         Go2 ROS2 SDK 快速測試 - 簡化版本                                 ║
╚════════════════════════════════════════════════════════════════════════════╝

⚡ 最簡單的使用方式

【第一步】開啟機器人 (終端 1):
  export ROBOT_IP="192.168.12.1"
  /home/roy422/ros2_ws/launch_go2_final.sh joystick:=false teleop:=false nav2:=false slam:=false

【第二步】初始化環境 (終端 2):
  cd /home/roy422/ros2_ws
  source install/setup.bash

【第三步】執行測試 (同終端 2):

  # 檢查系統
  bash TEST.sh health

  # 測試基本動作
  bash TEST.sh sit
  bash TEST.sh stand
  bash TEST.sh balance (一定要做)

  # 測試移動 (每個命令持續 3 秒)
  bash TEST.sh forward   (向前)
  bash TEST.sh left      (左轉)
  bash TEST.sh stop      (停止)

就這麼簡單！

═════════════════════════════════════════════════════════════════════════════

📋 可用命令速查

坐下:            bash TEST.sh sit
站起:            bash TEST.sh stand
向前:            bash TEST.sh forward
向後:            bash TEST.sh backward
轉向:            bash TEST.sh left  (或 right)
停止:            bash TEST.sh stop
查看關節:        bash TEST.sh joint
查看 IMU:        bash TEST.sh imu
檢查系統:        bash TEST.sh health
查看所有命令:    bash TEST.sh help

═════════════════════════════════════════════════════════════════════════════

❓ 常見問題

Q: 機器人沒反應？
A: 確保你：
   1. 在終端 2 執行過 source install/setup.bash
   2. 機器人已站起來 (執行 bash TEST.sh stand)
   3. 啟動時禁用了 joystick/teleop
   然後執行: bash TEST.sh state

Q: 不知道用什麼命令？
A: 看這個:
   bash TEST.sh help

Q: 想要互動式菜單？
A: 運行這個:
   bash TEST.sh menu

═════════════════════════════════════════════════════════════════════════════

📚 文檔太多？只需要這個：

docs/00-overview/README_SIMPLE.md (就是這個！)

═════════════════════════════════════════════════════════════════════════════

就這麼簡單。開始測試吧！
