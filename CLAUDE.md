# CLAUDE.md
一律用繁體中文回答
pip install 一律改成用 uv pip install
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

如果我請你code review
你就會是Linus Torvalds，Linux 核心的創造者和首席架構師。你已經維護Linux 核心超過30年，審核過數百萬行程式碼，建立了世界上最成功的開源專案。現在我們正在開創一個新項目，你將以你獨特的視角來分析程式碼品質的潛在風險，確保專案從一開始就建立在堅實的技術基礎上。

## Project Overview

This is the **Unitree Go2 ROS2 SDK** - a comprehensive integration of the Unitree Go2 quadruped robot with ROS2. The project provides:
- Real-time joint synchronization and sensor streaming (IMU, foot force sensors)
- LIDAR point cloud processing for mapping and navigation
- Support for WebRTC (Wi-Fi) and CycloneDDS (Ethernet) connections
- Integration with SLAM (slam_toolbox) and navigation (Nav2)
- Object detection using COCO (PyTorch/MobileNet)
- Multi-robot support with a single launch system
- Text-to-speech capabilities

## Architecture Overview

The codebase follows **Clean Architecture principles** with the following major components:

### Core Packages

1. **go2_robot_sdk** (Python - main driver)
   - `application/`: ROS2 node implementations and command handlers
   - `domain/`: Core business logic and robot state models
   - `infrastructure/`: Communication layer (WebRTC, CycloneDDS, MQTT)
   - `presentation/`: Message definitions and data formats
   - Entry point: `go2_robot_sdk/main.py` → `go2_driver_node` ROS2 node

2. **go2_interfaces** (C++ - custom messages)
   - Custom ROS2 message definitions for Unitree Go2-specific data

3. **lidar_processor** (Python)
   - `lidar_to_pointcloud`: Aggregates raw LiDAR data into PointCloud2 messages
   - `pointcloud_aggregator`: Filters and downsamples point clouds
   - Parameters control map saving, voxel size, and range filters

4. **lidar_processor_cpp** (C++ - performance variant)
   - Drop-in C++ replacement for lidar_processor using PCL (Point Cloud Library)
   - More efficient for high-frequency processing
   - Identical topics and parameters to Python version

5. **coco_detector** (Python - object detection)
   - Runs PyTorch MobileNet on camera images
   - Publishes Detection2DArray messages to `/detected_objects`
   - Configurable detection threshold and device (CPU/CUDA)

6. **speech_processor** (Python - text-to-speech)
   - TTS node supporting ElevenLabs API
   - Runs autonomously during robot operation

### Launch Configuration

The main launch file is **`robot.launch.py`** with a two-class design:
- **Go2LaunchConfig**: Parses environment variables and determines configuration (single/multi-robot, connection type, URDF selection)
- **Go2NodeFactory**: Creates all ROS2 nodes and launch includes dynamically based on config

**Key environment variables:**
```bash
export ROBOT_IP="<ip>"                    # Single robot
export ROBOT_IP="<ip1>,<ip2>,<ipN>"      # Multi-robot
export CONN_TYPE="webrtc"                 # or "cyclonedds" (default: webrtc)
export MAP_NAME="3d_map"                  # For point cloud saving
export MAP_SAVE="true"                    # Enable map saving
export ELEVENLABS_API_KEY="..."           # For TTS
```

**Launch arguments:**
```bash
ros2 launch go2_robot_sdk robot.launch.py rviz2:=true slam:=true nav2:=true foxglove:=true
```

## Building and Development

### Build Commands

```bash
# Build all packages
colcon build

# Build specific package
colcon build --packages-select go2_robot_sdk

# Build C++ LiDAR processor
colcon build --packages-select lidar_processor_cpp

# Clean build
colcon build --packages-select <package> --cmake-force-configure

# Install ROS 2 dependencies
source /opt/ros/$ROS_DISTRO/setup.bash
rosdep install --from-paths src --ignore-src -r -y

# Install Python dependencies
pip install -r src/requirements.txt
```

### Running the System

```bash
# Setup environment
source install/setup.bash

# Launch main robot system
export ROBOT_IP="192.168.1.100"
export CONN_TYPE="webrtc"
ros2 launch go2_robot_sdk robot.launch.py

# Launch only specific components (disable others)
ros2 launch go2_robot_sdk robot.launch.py slam:=false nav2:=false

# Run object detection
ros2 run coco_detector coco_detector_node

# Run with custom parameters
ros2 run coco_detector coco_detector_node --ros-args -p device:=cuda -p detection_threshold:=0.7

# View detected objects
ros2 topic echo /detected_objects

# View annotated camera feed
ros2 run image_tools showimage --ros-args -r /image:=/annotated_image
```

## Key Technical Decisions

1. **Clean Architecture**: Separation of concerns between application, domain, and infrastructure layers allows easy maintenance and testing
2. **Multi-robot via Single Launch**: Single launch file dynamically configures for 1 or N robots using namespace remapping
3. **Dual Protocol Support**: WebRTC (Wi-Fi) and CycloneDDS (Ethernet) share identical interfaces through infrastructure abstraction
4. **C++ LiDAR Processing**: Optional high-performance variant for bandwidth-sensitive deployments
5. **SLAM/Nav2 Integration**: Uses standard slam_toolbox and nav2_bringup packages with custom configurations

## Data Flow

1. **Robot Driver** (`go2_driver_node`) → publishes `/joint_states`, `/imu`, `/point_cloud2`, camera/image
2. **LiDAR Processor** subscribes `/point_cloud2` → publishes `/pointcloud/aggregated`
3. **Point Cloud Aggregator** subscribes `/pointcloud/aggregated` → publishes `/pointcloud/filtered`, `/pointcloud/downsampled`
4. **SLAM** subscribes `/scan`, `/odom`, publishes `/map`
5. **Nav2** subscribes `/map`, `/scan`, `/amcl_pose` → publishes `/cmd_vel`
6. **Object Detector** subscribes `/camera/image` → publishes `/detected_objects`, `/annotated_image`

## Important Notes

- **Firmware Dependency**: Project developed with firmware v1.1.7. Joint state updates arrive at 1 Hz (known limitation affecting URDF sync latency)
- **LiDAR Performance**: New refactor improved LiDAR from ~2 Hz to ~7 Hz using Clean Architecture
- **WSL2 Joystick**: Special configuration needed for joystick passthrough (see README.md for details)
- **Docker Support**: Available in `docker/` directory with compose configuration
- **Map Saving**: Periodically saves `.ply` format point clouds every 10 seconds when `MAP_SAVE=true`

## Configuration Files

Located in `go2_robot_sdk/config/`:
- `joystick.yaml`: Joy node button/axis mappings
- `twist_mux.yaml`: Velocity command multiplexing and teleop settings
- `mapper_params_online_async.yaml`: SLAM Toolbox parameters
- `nav2_params.yaml`: Navigation2 planner and controller parameters
- `*.rviz`: RViz2 visualization configurations (single/multi-robot/cyclonedx variants)

## Testing and Debugging

```bash
# Monitor specific topics
ros2 topic list              # List all topics
ros2 topic echo /joint_states
ros2 topic hz /point_cloud2  # Measure publishing rate

# Check node status
ros2 node list
ros2 node info /go2_driver_node

# View transform tree
ros2 run tf2_tools view_frames

# RViz configuration persistence
# Settings are saved in ~/.config/ros.org/rviz2/ after manual adjustments
```

## Repository Structure

```
src/
├── go2_robot_sdk/           # Main Python driver (Clean Architecture)
│   ├── go2_robot_sdk/       # Python package
│   │   ├── application/     # ROS2 nodes and command handlers
│   │   ├── domain/          # Core business logic
│   │   ├── infrastructure/  # WebRTC, CycloneDDS, MQTT
│   │   └── presentation/    # Message definitions
│   ├── launch/              # robot.launch.py (main entry point)
│   ├── config/              # YAML configurations
│   └── urdf/                # Robot model definitions
├── go2_interfaces/          # Custom ROS2 messages (C++)
├── lidar_processor/         # Python LiDAR processing
├── lidar_processor_cpp/     # High-performance C++ variant
├── coco_detector/           # Object detection node
├── speech_processor/        # Text-to-speech node
└── docker/                  # Docker Compose setup
```

## Relevant Resources

- Main README: Extensive setup and usage documentation
- Referenced packages:
  - `slam_toolbox`: Grid-based SLAM for mapping
  - `nav2_bringup`: Navigation2 framework
  - `foxglove_bridge`: Web-based visualization
  - `twist_mux`: Velocity command multiplexing
  - `pointcloud_to_laserscan`: Convert 3D point clouds to 2D laser scans
