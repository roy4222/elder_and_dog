# 新套件目錄結構與依賴

**文件目的：** 提供 W6-W9 新增套件的標準化結構與依賴管理指南
**適用套件：** `vision_vlm`, `coordinate_transformer`, `search_logic`
**版本：** v1.1（根據 2025/11/19 會議決議更新）

---

## 📦 套件總覽

### 1. vision_vlm（VLM 視覺識別 - COCO Plan A + Gemini Plan B）

#### 目錄結構

```
src/vision_vlm/
├── vision_vlm/
│   ├── __init__.py
│   # === Plan A: COCO 本地推論（主力） ===
│   ├── coco_detector_node.py       # COCO 主節點
│   ├── coco_classes.py             # COCO 80 類別映射（繁體中文）
│   ├── model_loader.py             # PyTorch 模型載入器
│   # === Plan B: Gemini API（備案） ===
│   ├── gemini_vlm_node.py          # Gemini 備案節點
│   ├── gemini_api_client.py        # Gemini API 客戶端
│   # === 共用模組 ===
│   ├── detection_converter.py      # Detection2DArray 轉換（通用）
│   ├── image_preprocessor.py       # 影像前處理（通用）
│   └── cache_manager.py            # 快取管理（選用）
├── config/
│   ├── coco_params.yaml            # COCO 參數配置
│   └── gemini_params.yaml          # Gemini 參數配置
├── test/
│   ├── __init__.py
│   ├── test_coco_detector.py       # COCO 測試
│   ├── test_gemini_api.py          # Gemini 測試
│   └── test_detection_converter.py # 轉換器測試
├── launch/
│   ├── coco_detector.launch.py     # COCO 啟動檔（主力）
│   └── gemini_vlm.launch.py        # Gemini 啟動檔（備案）
├── resource/
│   └── vision_vlm                  # ament 資源標記
├── package.xml
├── setup.py
├── setup.cfg
├── requirements-coco.txt           # PyTorch 依賴（COCO 專用）
└── README.md
```

#### package.xml（支援 COCO + Gemini 雙方案）

```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>vision_vlm</name>
  <version>1.1.0</version>
  <description>VLM integration for object detection (COCO Plan A + Gemini Plan B)</description>
  <maintainer email="team@fju.edu.tw">FJU Go2 Team</maintainer>
  <license>MIT</license>

  <buildtool_depend>ament_python</buildtool_depend>

  <!-- ROS2 依賴 -->
  <depend>rclpy</depend>
  <depend>sensor_msgs</depend>
  <depend>vision_msgs</depend>
  <depend>std_msgs</depend>
  <depend>cv_bridge</depend>

  <!-- Python 系統依賴 -->
  <exec_depend>python3-pil</exec_depend>
  <exec_depend>python3-numpy</exec_depend>
  <exec_depend>python3-opencv</exec_depend>

  <!-- PyTorch 相關（COCO 需要，透過 pip/uv 安裝，此處僅註記） -->
  <!-- torch==2.1.0+cu118 (via requirements-coco.txt) -->
  <!-- torchvision==0.16.0+cu118 (via requirements-coco.txt) -->

  <!-- Gemini API（備案，選用時透過 pip/uv 安裝） -->
  <!-- google-generativeai==0.3.2 (optional, via pip) -->

  <test_depend>ament_copyright</test_depend>
  <test_depend>ament_flake8</test_depend>
  <test_depend>ament_pep257</test_depend>
  <test_depend>python3-pytest</test_depend>

  <export>
    <build_type>ament_python</build_type>
  </export>
</package>
```

#### setup.py（支援雙節點 entry points）

```python
from setuptools import setup, find_packages
import os
from glob import glob

package_name = 'vision_vlm'

setup(
    name=package_name,
    version='1.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name, 'launch'), glob('launch/*.launch.py')),
        (os.path.join('share', package_name, 'config'), glob('config/*.yaml')),
    ],
    install_requires=[
        'setuptools',
        'pillow',
        'numpy',
        'opencv-python',
        # 注意：torch/torchvision 需透過 requirements-coco.txt 安裝
        # 注意：google-generativeai 僅備案時需要
    ],
    zip_safe=True,
    maintainer='FJU Go2 Team',
    maintainer_email='team@fju.edu.tw',
    description='VLM integration (COCO Plan A + Gemini Plan B)',
    license='MIT',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            # Plan A: COCO 主力節點
            'coco_detector_node = vision_vlm.coco_detector_node:main',
            # Plan B: Gemini 備案節點
            'gemini_vlm_node = vision_vlm.gemini_vlm_node:main',
        ],
    },
)
```

**重要提醒**：
- PyTorch 依賴必須透過 `uv pip install -r requirements-coco.txt` 單獨安裝
- 不要在 `install_requires` 中加入 `torch/torchvision`（會與 CUDA 版本衝突）
- Gemini API 僅在需要 Plan B 時才安裝：`uv pip install google-generativeai==0.3.2`

**setup.cfg**：
```ini
[develop]
script_dir=$base/lib/vision_vlm
[install]
install_scripts=$base/lib/vision_vlm
```

---

### 2. coordinate_transformer（座標轉換）

```
src/coordinate_transformer/
├── coordinate_transformer/
│   ├── __init__.py
│   ├── lidar_projection_node.py      # Plan A: LiDAR 投影
│   ├── ground_assumption_node.py     # Plan B: 地面假設
│   ├── projection_utils.py           # 投影工具函數
│   ├── tf_utils.py                   # TF2 輔助工具
│   └── calibration_loader.py         # 相機內參載入
├── config/
│   └── transformer_params.yaml
├── test/
│   ├── test_projection.py
│   └── test_ground_assumption.py
├── launch/
│   ├── lidar_projection.launch.py
│   └── ground_assumption.launch.py
├── resource/
│   └── coordinate_transformer
├── package.xml
├── setup.py
├── setup.cfg
└── README.md
```

**package.xml** 重點依賴：
```xml
<depend>rclpy</depend>
<depend>sensor_msgs</depend>
<depend>geometry_msgs</depend>
<depend>vision_msgs</depend>
<depend>tf2_ros</depend>
<depend>tf2_geometry_msgs</depend>
<depend>cv_bridge</depend>
<depend>message_filters</depend>  <!-- 用於同步 topic -->

<exec_depend>python3-scipy</exec_depend>  <!-- 四元數轉換 -->
<exec_depend>python3-numpy</exec_depend>
```

**setup.py entry_points**：
```python
entry_points={
    'console_scripts': [
        'lidar_projection_node = coordinate_transformer.lidar_projection_node:main',
        'ground_assumption_node = coordinate_transformer.ground_assumption_node:main',
    ],
},
```

---

### 3. search_logic（尋物狀態機）

```
src/search_logic/
├── search_logic/
│   ├── __init__.py
│   ├── search_fsm_node.py          # 狀態機主節點
│   ├── state_handlers.py           # 各狀態處理邏輯
│   ├── nav2_client.py              # Nav2 Action Client
│   ├── patrol_planner.py           # 巡邏路徑規劃
│   └── vlm_tracker.py              # VLM 結果追蹤
├── config/
│   └── search_params.yaml
├── test/
│   ├── test_state_machine.py
│   └── test_nav2_client.py
├── launch/
│   └── search.launch.py
├── resource/
│   └── search_logic
├── package.xml
├── setup.py
├── setup.cfg
└── README.md
```

**package.xml** 重點依賴：
```xml
<depend>rclpy</depend>
<depend>std_msgs</depend>
<depend>geometry_msgs</depend>
<depend>vision_msgs</depend>
<depend>nav2_msgs</depend>  <!-- NavigateToPose action -->
<depend>action_msgs</depend>
<depend>rclpy_action</depend>  <!-- 重要：Action 客戶端 -->
```

**setup.py entry_points**：
```python
entry_points={
    'console_scripts': [
        'search_fsm_node = search_logic.search_fsm_node:main',
    ],
},
```

---

## 🛠️ 建立套件指令集

### 一鍵建立所有套件

```bash
cd ~/workspace/fju-go2-sdk/src

# 1. vision_vlm
ros2 pkg create --build-type ament_python vision_vlm \
  --dependencies rclpy sensor_msgs vision_msgs cv_bridge std_msgs \
  --node-name gemini_vlm_node

# 2. coordinate_transformer
ros2 pkg create --build-type ament_python coordinate_transformer \
  --dependencies rclpy sensor_msgs geometry_msgs vision_msgs tf2_ros cv_bridge message_filters \
  --node-name lidar_projection_node

# 3. search_logic
ros2 pkg create --build-type ament_python search_logic \
  --dependencies rclpy std_msgs geometry_msgs vision_msgs nav2_msgs action_msgs \
  --node-name search_fsm_node

# 4. 建立目錄結構
for pkg in vision_vlm coordinate_transformer search_logic; do
  mkdir -p $pkg/config
  mkdir -p $pkg/launch
  mkdir -p $pkg/test
done
```

---

## 📝 Python 依賴管理

### requirements.txt（專案根目錄）

```
# requirements.txt（專案根目錄，新增以下內容）

# VLM 相關
google-generativeai>=0.3.0
pillow>=10.0.0

# 座標轉換相關
scipy>=1.10.0

# 其他已有依賴...
```

### 安裝依賴

```bash
# 系統依賴（ROS2）
rosdep install --from-paths src --ignore-src -r -y

# Python 依賴（專案根目錄）
pip install -r requirements.txt
```

---

## 🔧 編譯與測試

### 編譯單一套件

```bash
cd ~/workspace/fju-go2-sdk

# 編譯特定套件
colcon build --packages-select vision_vlm
colcon build --packages-select coordinate_transformer
colcon build --packages-select search_logic

# 編譯所有新套件
colcon build --packages-select vision_vlm coordinate_transformer search_logic

# 強制重新編譯
colcon build --packages-select vision_vlm --cmake-force-configure
```

### 執行測試

```bash
# 單元測試
colcon test --packages-select vision_vlm
colcon test-result --verbose

# 手動執行 pytest
cd src/vision_vlm
pytest test/
```

---

## 📊 依賴關係圖

```mermaid
graph TD
    A[go2_robot_sdk] -->|發佈| B[camera/image_raw]
    A -->|發佈| C[point_cloud2]
    A -->|發佈| D[camera_info]

    B --> E[vision_vlm]
    E -->|發佈| F[/detected_objects]

    F --> G[coordinate_transformer]
    C --> G
    D --> G
    G -->|發佈| H[/object_pose_world]

    H --> I[search_logic]
    I -->|呼叫| J[Nav2 Action]

    style A fill:#a8dadc
    style E fill:#f4a261
    style G fill:#e76f51
    style I fill:#2a9d8f
```

---

## 🚀 整合到主 Launch 文件

### 修改 `go2_robot_sdk/launch/robot.launch.py`

```python
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration
from launch.conditions import IfCondition  # ← 新增此行（修正缺少的 import）
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    # 新增參數
    vlm_arg = DeclareLaunchArgument('vlm', default_value='false')
    search_arg = DeclareLaunchArgument('search', default_value='false')

    # 取得套件路徑
    vlm_pkg = get_package_share_directory('vision_vlm')
    coord_pkg = get_package_share_directory('coordinate_transformer')
    search_pkg = get_package_share_directory('search_logic')

    # VLM 節點
    vlm_node = Node(
        package='vision_vlm',
        executable='gemini_vlm_node',
        parameters=[os.path.join(vlm_pkg, 'config', 'vlm_params.yaml')],
        condition=IfCondition(LaunchConfiguration('vlm'))
    )

    # 座標轉換節點（預設使用 LiDAR 投影）
    coord_node = Node(
        package='coordinate_transformer',
        executable='lidar_projection_node',
        parameters=[os.path.join(coord_pkg, 'config', 'transformer_params.yaml')],
        condition=IfCondition(LaunchConfiguration('vlm'))  # VLM 啟用時才需要
    )

    # 尋物狀態機
    search_node = Node(
        package='search_logic',
        executable='search_fsm_node',
        parameters=[os.path.join(search_pkg, 'config', 'search_params.yaml')],
        condition=IfCondition(LaunchConfiguration('search'))
    )

    return LaunchDescription([
        vlm_arg,
        search_arg,
        # ... 其他現有節點 ...
        vlm_node,
        coord_node,
        search_node,
    ])
```

### 啟動範例

```bash
# 完整系統（實機）
export ROBOT_IP="192.168.1.100"
export GEMINI_API_KEY="your_key"
ros2 launch go2_robot_sdk robot.launch.py \
  vlm:=true \
  search:=true \
  slam:=true \
  nav2:=true

# 模擬器測試
ros2 launch go2_robot_sdk robot.launch.py \
  simulation:=true \
  vlm:=true \
  search:=true \
  slam:=true \
  nav2:=true
```

---

## ⚙️ 參數配置範例

### `vision_vlm/config/vlm_params.yaml`

```yaml
gemini_vlm_node:
  ros__parameters:
    api_key: ""  # 從環境變數讀取
    model_name: "gemini-2.0-flash-exp"
    detection_threshold: 0.6
    publish_rate: 2.0
    max_image_size: 800
    image_topic: "camera/image_raw"
    target_object: ""
```

### `coordinate_transformer/config/transformer_params.yaml`

```yaml
lidar_projection_node:
  ros__parameters:
    method: "lidar_projection"  # or "ground_assumption"
    point_cloud_topic: "point_cloud2"
    camera_info_topic: "camera/camera_info"
    detection_topic: "/detected_objects"
    image_width: 1280
    image_height: 720
    neighbor_radius: 5
    min_depth: 0.3
    max_depth: 10.0
```

### `search_logic/config/search_params.yaml`

```yaml
search_fsm_node:
  ros__parameters:
    patrol_points: [[2.0, 1.0], [4.0, 2.5], [1.5, 4.0], [3.5, 0.5]]
    approach_distance: 1.0
    success_distance: 0.3
    max_retries: 3
    scan_angular_velocity: 0.3
```

---

## 📚 版本控制建議

### .gitignore 新增

```gitignore
# Python
__pycache__/
*.pyc
*.pyo
*.egg-info/

# ROS2
build/
install/
log/

# IDE
.vscode/
.idea/

# 配置檔案中的敏感資訊
**/vlm_params.yaml  # 若包含 API key
```

### Git 提交建議結構

```bash
git add src/vision_vlm
git commit -m "feat: Add Gemini VLM integration package"

git add src/coordinate_transformer
git commit -m "feat: Add coordinate transformation system (LiDAR projection + ground assumption)"

git add src/search_logic
git commit -m "feat: Add search FSM with Nav2 integration"
```

---

**文件版本：** v1.0
**最後更新：** 2025/11/16
**維護者：** FJU Go2 專題組
