"""
巡邏節點 Launch 檔案（可選使用）
"""
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    # 取得套件路徑
    pkg_dir = get_package_share_directory('search_logic')
    params_file = os.path.join(pkg_dir, 'config', 'patrol_params.yaml')

    # Launch 參數
    auto_start_arg = DeclareLaunchArgument(
        'auto_start',
        default_value='false',
        description='是否自動開始巡邏'
    )

    loop_patrol_arg = DeclareLaunchArgument(
        'loop_patrol',
        default_value='true',
        description='是否循環巡邏'
    )

    # 巡邏節點
    patrol_node = Node(
        package='search_logic',
        executable='simple_patrol_node',
        name='simple_patrol_node',
        output='screen',
        parameters=[
            params_file,
            {
                'auto_start': LaunchConfiguration('auto_start'),
                'loop_patrol': LaunchConfiguration('loop_patrol'),
            }
        ],
        emulate_tty=True
    )

    return LaunchDescription([
        auto_start_arg,
        loop_patrol_arg,
        patrol_node
    ])
