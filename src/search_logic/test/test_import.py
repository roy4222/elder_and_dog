#!/usr/bin/env python3
"""
pytest 測試套件
驗證 search_logic 套件的正確性
"""

def test_rclpy_imports():
    """測試 ROS2 核心 imports"""
    import rclpy
    from rclpy.node import Node
    from rclpy.action import ActionClient
    # 如果 import 失敗，pytest 會自動標記為失敗


def test_message_imports():
    """測試訊息類型 imports"""
    from geometry_msgs.msg import PoseStamped
    from nav2_msgs.action import NavigateToPose
    from std_msgs.msg import String


def test_search_logic_imports():
    """測試套件本身的 imports"""
    from search_logic.nav2_client import Nav2Client
    from search_logic.simple_patrol_node import SimplePatrolNode, PatrolState


def test_nav2_client_class():
    """測試 Nav2Client 類別定義"""
    from search_logic.nav2_client import Nav2Client

    # 檢查類別是否有必要的方法
    assert hasattr(Nav2Client, 'wait_for_server')
    assert hasattr(Nav2Client, 'send_goal')
    assert hasattr(Nav2Client, 'cancel_goal')


def test_patrol_state_enum():
    """測試 PatrolState 枚舉"""
    from search_logic.simple_patrol_node import PatrolState

    # 檢查狀態是否正確定義
    assert hasattr(PatrolState, 'IDLE')
    assert hasattr(PatrolState, 'PATROL')
    assert PatrolState.IDLE.value == 0
    assert PatrolState.PATROL.value == 1


def test_simple_patrol_node_class():
    """測試 SimplePatrolNode 類別定義"""
    from search_logic.simple_patrol_node import SimplePatrolNode

    # 檢查節點是否有必要的方法
    assert hasattr(SimplePatrolNode, 'command_callback')
    assert hasattr(SimplePatrolNode, 'state_machine_update')
    assert hasattr(SimplePatrolNode, 'handle_patrol')
    assert hasattr(SimplePatrolNode, 'nav_result_callback')


if __name__ == '__main__':
    import pytest
    import sys

    # 執行測試並顯示詳細輸出
    sys.exit(pytest.main([__file__, '-v']))
