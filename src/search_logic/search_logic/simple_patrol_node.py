"""
簡單巡邏節點
純測試 Nav2 導航功能，不依賴 VLM 或座標轉換
"""
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import PoseStamped
from std_msgs.msg import String
from enum import Enum

from search_logic.nav2_client import Nav2Client


class PatrolState(Enum):
    """巡邏狀態"""
    IDLE = 0       # 閒置等待
    PATROL = 1     # 巡邏中


class SimplePatrolNode(Node):
    def __init__(self):
        super().__init__('simple_patrol_node')

        # 宣告參數
        self.declare_parameter('patrol_points', [[2.0, 1.0], [4.0, 2.5], [1.5, 4.0]])
        self.declare_parameter('loop_patrol', True)  # 是否循環巡邏
        self.declare_parameter('auto_start', False)  # 是否自動開始

        # 讀取參數
        self.patrol_points = self.get_parameter('patrol_points').value
        self.loop_patrol = self.get_parameter('loop_patrol').value
        self.auto_start = self.get_parameter('auto_start').value

        # 狀態變數
        self.state = PatrolState.IDLE
        self.patrol_index = 0
        self.is_navigating = False

        # Nav2 客戶端
        self.nav2_client = Nav2Client(self)

        # 等待 Nav2 服務啟動
        self.get_logger().info('等待 Nav2 服務啟動...')
        if not self.nav2_client.wait_for_server(timeout_sec=10.0):
            self.get_logger().error('Nav2 服務未啟動！請確認已啟動 nav2_bringup')
            self.get_logger().error('提示：ros2 launch go2_robot_sdk robot.launch.py nav2:=true')
            self.get_logger().fatal('節點無法繼續運行，即將退出')
            raise RuntimeError('Nav2 服務未啟動，無法初始化巡邏節點')

        self.get_logger().info('Nav2 服務已就緒')

        # 訂閱器（可選：接收啟動指令）
        self.command_sub = self.create_subscription(
            String,
            '/patrol_command',
            self.command_callback,
            10
        )

        # 發佈器（巡邏狀態）
        self.status_pub = self.create_publisher(String, '/patrol_status', 10)

        # 定時器（狀態機更新，每秒檢查一次）
        self.timer = self.create_timer(1.0, self.state_machine_update)

        # 啟動訊息
        self.get_logger().info('簡單巡邏節點已啟動')
        self.get_logger().info(f'巡邏點數量: {len(self.patrol_points)}')
        self.get_logger().info(f'循環巡邏: {self.loop_patrol}')

        if self.auto_start:
            self.get_logger().info('自動開始巡邏')
            self.state = PatrolState.PATROL
        else:
            self.get_logger().info('等待指令啟動（發送到 /patrol_command 或設定 auto_start:=true）')

    def command_callback(self, msg: String):
        """接收巡邏指令"""
        command = msg.data.lower()

        if command == 'start' and self.state == PatrolState.IDLE:
            self.get_logger().info('收到啟動指令，開始巡邏')
            self.state = PatrolState.PATROL
            self.patrol_index = 0

        elif command == 'stop':
            self.get_logger().info('收到停止指令')
            self.nav2_client.cancel_goal()
            self.state = PatrolState.IDLE
            self.is_navigating = False

        elif command == 'reset':
            self.get_logger().info('重置巡邏進度')
            self.patrol_index = 0
            self.state = PatrolState.IDLE
            self.is_navigating = False

    def state_machine_update(self):
        """狀態機主循環"""
        if self.state == PatrolState.IDLE:
            # 閒置狀態，等待指令
            pass

        elif self.state == PatrolState.PATROL:
            self.handle_patrol()

    def handle_patrol(self):
        """處理巡邏狀態"""
        # 如果正在導航中，等待完成
        if self.is_navigating:
            return

        # 檢查是否所有巡邏點都訪問過
        if self.patrol_index >= len(self.patrol_points):
            if self.loop_patrol:
                self.get_logger().info('完成一輪巡邏，重新開始')
                self.patrol_index = 0
            else:
                self.get_logger().info('所有巡邏點已訪問完畢，停止巡邏')
                self.state = PatrolState.IDLE
                self.publish_status('巡邏完成')
                return

        # 發送下一個巡邏點目標
        patrol_point = self.patrol_points[self.patrol_index]

        # 建立目標 PoseStamped
        goal_pose = PoseStamped()
        goal_pose.header.frame_id = 'map'
        goal_pose.header.stamp = self.get_clock().now().to_msg()
        goal_pose.pose.position.x = float(patrol_point[0])
        goal_pose.pose.position.y = float(patrol_point[1])
        goal_pose.pose.position.z = 0.0

        # 設定朝向（預設朝向 +X 軸）
        goal_pose.pose.orientation.w = 1.0
        goal_pose.pose.orientation.x = 0.0
        goal_pose.pose.orientation.y = 0.0
        goal_pose.pose.orientation.z = 0.0

        # 發送導航目標
        self.get_logger().info(
            f'前往巡邏點 {self.patrol_index + 1}/{len(self.patrol_points)}: '
            f'({patrol_point[0]:.2f}, {patrol_point[1]:.2f})'
        )

        self.nav2_client.send_goal(
            goal_pose,
            feedback_callback=self.nav_feedback_callback,
            result_callback=self.nav_result_callback
        )

        self.is_navigating = True
        self.publish_status(f'前往巡邏點 {self.patrol_index + 1}/{len(self.patrol_points)}')

    def nav_feedback_callback(self, feedback):
        """導航回饋回調（可用於顯示剩餘距離等資訊）"""
        # 可選：記錄導航進度
        pass

    def nav_result_callback(self, success, result):
        """導航結果回調"""
        self.is_navigating = False

        if success:
            self.get_logger().info(
                f'成功到達巡邏點 {self.patrol_index + 1}/{len(self.patrol_points)}'
            )
            self.publish_status(f'到達巡邏點 {self.patrol_index + 1}')

            # 前往下一個巡邏點
            self.patrol_index += 1

        else:
            self.get_logger().warn(
                f'導航失敗，無法到達巡邏點 {self.patrol_index + 1}，跳過並前往下一個點'
            )
            self.publish_status(f'巡邏點 {self.patrol_index + 1} 導航失敗')

            # 仍然前往下一個點（可根據需求調整策略）
            self.patrol_index += 1

    def publish_status(self, status: str):
        """發佈巡邏狀態"""
        msg = String()
        msg.data = status
        self.status_pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)

    node = SimplePatrolNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        node.get_logger().info('收到中斷訊號，停止巡邏')
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
