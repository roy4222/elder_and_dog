"""
Nav2 Action Client 封裝
簡化導航呼叫介面
"""
import rclpy
from rclpy.action import ActionClient
from rclpy.node import Node
from nav2_msgs.action import NavigateToPose
from geometry_msgs.msg import PoseStamped
from typing import Callable, Optional


class Nav2Client:
    def __init__(self, node: Node):
        self.node = node
        self.client = ActionClient(node, NavigateToPose, 'navigate_to_pose')
        self.goal_handle = None
        self.feedback_callback: Optional[Callable] = None
        self.result_callback: Optional[Callable] = None

    def wait_for_server(self, timeout_sec=5.0):
        """等待 Nav2 服務啟動"""
        return self.client.wait_for_server(timeout_sec=timeout_sec)

    def send_goal(
        self,
        pose: PoseStamped,
        feedback_callback: Optional[Callable] = None,
        result_callback: Optional[Callable] = None
    ):
        """
        發送導航目標

        Args:
            pose: 目標位姿（PoseStamped）
            feedback_callback: 回饋回調函數（接收 feedback 訊息）
            result_callback: 結果回調函數（接收成功/失敗狀態）
        """
        self.feedback_callback = feedback_callback
        self.result_callback = result_callback

        goal_msg = NavigateToPose.Goal()
        goal_msg.pose = pose

        self.node.get_logger().info(
            f'發送導航目標: ({pose.pose.position.x:.2f}, {pose.pose.position.y:.2f})'
        )

        send_goal_future = self.client.send_goal_async(
            goal_msg,
            feedback_callback=self._feedback_callback
        )
        send_goal_future.add_done_callback(self._goal_response_callback)

    def cancel_goal(self):
        """取消當前導航"""
        if self.goal_handle:
            self.node.get_logger().info('取消導航目標')
            cancel_future = self.goal_handle.cancel_goal_async()
            cancel_future.add_done_callback(lambda future: self.node.get_logger().info('導航已取消'))

    def _goal_response_callback(self, future):
        """目標接受回調"""
        self.goal_handle = future.result()
        if not self.goal_handle.accepted:
            self.node.get_logger().error('導航目標被拒絕')
            return

        self.node.get_logger().info('導航目標已接受')
        get_result_future = self.goal_handle.get_result_async()
        get_result_future.add_done_callback(self._get_result_callback)

    def _feedback_callback(self, feedback_msg):
        """導航回饋回調"""
        if self.feedback_callback:
            self.feedback_callback(feedback_msg.feedback)

    def _get_result_callback(self, future):
        """導航結果回調"""
        result = future.result().result
        status = future.result().status

        if self.result_callback:
            success = (status == 4)  # SUCCEEDED = 4
            self.result_callback(success, result)
