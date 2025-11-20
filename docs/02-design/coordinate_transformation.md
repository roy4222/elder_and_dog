# 座標轉換系統設計文件

**套件名稱：** `coordinate_transformer`
**主要節點：** `lidar_projection_node` / `ground_assumption_node`
**開發週次：** W7-W8
**難度：** ⭐⭐⭐⭐ 高

**重要提醒：**
- 本文件中使用 `camera_link` 代表相機座標系 frame，實際實作時請對應真實 URDF 中的 frame 名稱（可能是 `front_camera_link` 或其他）
- 使用前請先執行 `ros2 run tf2_tools view_frames` 確認實際 frame 名稱

---

## 📋 目標

實現從 **2D 圖像座標** 到 **3D 世界座標** 的完整轉換鏈路：

```
VLM 輸出 [u, v] 像素座標
         ↓
相機內參 + 深度資訊
         ↓
3D 本體座標 [x, y, z] (base_link frame)
         ↓
TF2 轉換
         ↓
3D 世界座標 [X, Y, Z] (map frame)
         ↓
Nav2 導航目標
```

---

## 🎯 核心挑戰

### 問題：Go2 無深度相機！
**現有感測器**：
- ✅ RGB 相機（720p/1080p）
- ✅ LiDAR（Unitree L1，點雲數據）
- ❌ **無深度相機**（RealSense/Kinect 等）

**解決方案**：
1. **Plan A（推薦）**：LiDAR 點雲投影法
2. **Plan B（備用）**：地面假設法
3. **Plan C（Demo 備案）**：預標註座標

---

## 🏗️ 系統架構

### 方法 A：LiDAR 點雲投影法

#### 原理
將 LiDAR 點雲投影到相機圖像平面，建立像素 → 3D 點的對應關係。

#### 數學基礎

**步驟 1：座標系轉換（LiDAR → Camera）**
```python
# 使用 TF2 取得轉換矩陣
T_camera_base = tf_buffer.lookup_transform('camera_link', 'base_link', time)

# 將點雲從 base_link 轉到 camera_link
for point in pointcloud:
    p_camera = T_camera_base * p_base
```

**步驟 2：3D → 2D 投影（相機內參）**

相機內參矩陣 K（已於 calibration YAML 中提供）：
$$
K = \begin{bmatrix}
f_x & 0 & c_x \\
0 & f_y & c_y \\
0 & 0 & 1
\end{bmatrix}
$$

投影公式：
$$
\begin{bmatrix} u \\ v \\ 1 \end{bmatrix} = \frac{1}{Z} K \begin{bmatrix} X \\ Y \\ Z \end{bmatrix}
$$

其中：
- $(X, Y, Z)$：相機座標系下的 3D 點
- $(u, v)$：圖像像素座標
- $f_x, f_y$：焦距
- $c_x, c_y$：光學中心

**步驟 3：建立查找表**
```python
# 為每個像素建立對應的 3D 點
depth_map = {}
for point_3d in camera_points:
    u, v = project_to_image(point_3d, K)
    if 0 <= u < width and 0 <= v < height:
        depth_map[(u, v)] = point_3d
```

**步驟 4：查詢 VLM 座標**
```python
# VLM 輸出的 Bbox 中心
u_vlm, v_vlm = detection.bbox.center.x, detection.bbox.center.y

# 查找對應的 3D 點（取鄰近區域平均）
neighbors = [(u_vlm + du, v_vlm + dv) for du in [-5, 0, 5] for dv in [-5, 0, 5]]
points_3d = [depth_map.get((u, v)) for u, v in neighbors if (u, v) in depth_map]
point_3d_avg = np.mean(points_3d, axis=0)  # 平均降噪
```

#### 資料流向圖

```mermaid
graph TD
    A[point_cloud2<br/>LiDAR 點雲] --> B[TF2 轉換<br/>base_link → camera_link]
    C[camera_info<br/>內參矩陣 K] --> D[3D → 2D 投影]
    B --> D
    D --> E[建立深度圖<br/>dict: pixel → 3D point]
    F[/detected_objects<br/>VLM 輸出] --> G[提取 Bbox 中心<br/>u, v]
    G --> H[查找深度圖]
    E --> H
    H --> I[3D 本體座標<br/>PoseStamped base_link]
    I --> J[TF2 轉換<br/>base_link → map]
    J --> K[/object_pose_world<br/>PoseStamped map]
```

---

### 方法 B：地面假設法

#### 原理
假設目標物體位於地面平面（$Z_{map} = 0$），使用射線-平面交點計算 3D 座標。

#### 數學推導

**假設**：
- 地面平面：$Z_{map} = 0$（在 map frame 中）
- 已知：相機位姿、內參、VLM 像素座標

**步驟 1：計算相機射線**

從像素 $(u, v)$ 反投影為相機射線：
$$
\vec{r}_{camera} = K^{-1} \begin{bmatrix} u \\ v \\ 1 \end{bmatrix}
$$

正規化後：
$$
\vec{d}_{camera} = \frac{\vec{r}_{camera}}{||\vec{r}_{camera}||}
$$

**步驟 2：轉換到世界座標系**

使用 TF2 取得相機位姿 $T_{map \leftarrow camera}$：
```python
T = tf_buffer.lookup_transform('map', 'camera_link', time)
camera_position = [T.translation.x, T.translation.y, T.translation.z]
camera_rotation = [T.rotation.x, T.rotation.y, T.rotation.z, T.rotation.w]

# 旋轉射線方向
d_world = quaternion_rotation(d_camera, camera_rotation)
```

**步驟 3：射線-平面交點**

射線方程：$\vec{P}(t) = \vec{C} + t \vec{d}$（$\vec{C}$ 為相機位置）

平面方程：$Z = 0$

求解 $t$：
$$
t = \frac{-C_z}{d_z}
$$

交點座標：
$$
\begin{bmatrix} X_{world} \\ Y_{world} \\ 0 \end{bmatrix} = \vec{C} + t \vec{d}
$$

#### 限制與適用場景
- ✅ 適用：地面物體（眼鏡、鑰匙等）
- ❌ 不適用：懸掛物體（架上的杯子）
- ⚠️ 誤差：地面不平整時誤差增大

---

## 🛠️ 實作細節

### 套件結構

```
src/coordinate_transformer/
├── coordinate_transformer/
│   ├── __init__.py
│   ├── lidar_projection_node.py      # Plan A 實作
│   ├── ground_assumption_node.py     # Plan B 實作
│   ├── projection_utils.py           # 投影工具函數
│   ├── tf_utils.py                   # TF2 輔助工具
│   └── calibration_loader.py         # 載入相機內參
├── config/
│   └── transformer_params.yaml
├── test/
│   ├── test_projection.py
│   └── test_ground_assumption.py
├── launch/
│   └── transformer.launch.py
├── package.xml
└── setup.py
```

---

### 核心程式碼

#### A. `projection_utils.py`（投影工具）

```python
"""
相機投影工具函數
"""
import numpy as np
from typing import Tuple, List, Optional


class ProjectionUtils:
    @staticmethod
    def load_camera_intrinsics(camera_info_msg) -> np.ndarray:
        """
        從 CameraInfo 訊息提取內參矩陣

        Returns:
            3x3 numpy array
        """
        K = np.array(camera_info_msg.k).reshape(3, 3)
        return K

    @staticmethod
    def project_3d_to_2d(
        points_3d: np.ndarray,
        K: np.ndarray
    ) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """
        將 3D 點投影到 2D 圖像平面

        Args:
            points_3d: Nx3 array (X, Y, Z in camera frame)
            K: 3x3 內參矩陣

        Returns:
            u: N array (x 像素座標)
            v: N array (y 像素座標)
            valid_mask: N boolean array (有效點的遮罩，Z > 0)
        """
        # 只保留相機前方的點（Z > 0）
        valid_mask = points_3d[:, 2] > 0
        points_3d_valid = points_3d[valid_mask]

        # 投影（齊次座標）
        uv_homogeneous = K @ points_3d_valid.T  # 3xN
        u = uv_homogeneous[0, :] / uv_homogeneous[2, :]
        v = uv_homogeneous[1, :] / uv_homogeneous[2, :]

        return u.astype(int), v.astype(int), valid_mask

    @staticmethod
    def unproject_2d_to_ray(
        u: float,
        v: float,
        K: np.ndarray
    ) -> np.ndarray:
        """
        從 2D 像素反投影為 3D 射線（單位向量）

        Args:
            u, v: 像素座標
            K: 3x3 內參矩陣

        Returns:
            3D 單位向量 (camera frame)
        """
        K_inv = np.linalg.inv(K)
        pixel_homogeneous = np.array([u, v, 1.0])
        ray = K_inv @ pixel_homogeneous
        ray_normalized = ray / np.linalg.norm(ray)
        return ray_normalized

    @staticmethod
    def ray_plane_intersection(
        ray_origin: np.ndarray,
        ray_direction: np.ndarray,
        plane_z: float = 0.0
    ) -> Optional[np.ndarray]:
        """
        計算射線與平面 (Z = plane_z) 的交點

        Args:
            ray_origin: 射線起點 (3D)
            ray_direction: 射線方向（單位向量）
            plane_z: 平面 Z 座標

        Returns:
            交點 (X, Y, Z) 或 None（無交點）
        """
        # 避免除以零
        if abs(ray_direction[2]) < 1e-6:
            return None

        # 計算參數 t
        t = (plane_z - ray_origin[2]) / ray_direction[2]

        # 射線向後（t < 0）
        if t < 0:
            return None

        # 計算交點
        intersection = ray_origin + t * ray_direction
        return intersection
```

---

#### B. `lidar_projection_node.py`（Plan A 主節點）

```python
"""
LiDAR 點雲投影節點
建立像素 → 3D 點的對應關係
"""
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2, CameraInfo, Image
from vision_msgs.msg import Detection2DArray
from geometry_msgs.msg import PoseStamped, TransformStamped
from tf2_ros import Buffer, TransformListener
import numpy as np
from cv_bridge import CvBridge
import message_filters

from .projection_utils import ProjectionUtils


class LiDARProjectionNode(Node):
    def __init__(self):
        super().__init__('lidar_projection_node')

        # 參數
        self.declare_parameter('point_cloud_topic', 'point_cloud2')
        self.declare_parameter('camera_info_topic', 'camera/camera_info')
        self.declare_parameter('detection_topic', '/detected_objects')
        self.declare_parameter('image_width', 1280)
        self.declare_parameter('image_height', 720)
        self.declare_parameter('neighbor_radius', 5)  # 查找鄰近像素範圍

        self.pc_topic = self.get_parameter('point_cloud_topic').value
        self.cam_info_topic = self.get_parameter('camera_info_topic').value
        self.det_topic = self.get_parameter('detection_topic').value
        self.img_width = self.get_parameter('image_width').value
        self.img_height = self.get_parameter('image_height').value
        self.neighbor_radius = self.get_parameter('neighbor_radius').value

        # TF2
        self.tf_buffer = Buffer()
        self.tf_listener = TransformListener(self.tf_buffer, self)

        # 工具
        self.projection_utils = ProjectionUtils()
        self.bridge = CvBridge()

        # 狀態
        self.camera_intrinsics = None
        self.depth_map = {}  # {(u, v): [x, y, z]}

        # 訂閱器（同步 PointCloud + CameraInfo）
        self.pc_sub = message_filters.Subscriber(self, PointCloud2, self.pc_topic)
        self.cam_info_sub = message_filters.Subscriber(self, CameraInfo, self.cam_info_topic)

        ts = message_filters.ApproximateTimeSynchronizer(
            [self.pc_sub, self.cam_info_sub],
            queue_size=10,
            slop=0.1  # 100ms 容差
        )
        ts.registerCallback(self.pointcloud_callback)

        # 訂閱 VLM 偵測結果
        self.det_sub = self.create_subscription(
            Detection2DArray,
            self.det_topic,
            self.detection_callback,
            10
        )

        # 發佈器
        self.pose_pub = self.create_publisher(
            PoseStamped,
            '/object_pose_world',
            10
        )

        self.get_logger().info('LiDAR 投影節點已啟動')

    def pointcloud_callback(self, pc_msg: PointCloud2, cam_info_msg: CameraInfo):
        """處理點雲與相機內參"""
        try:
            # 載入內參（首次）
            if self.camera_intrinsics is None:
                self.camera_intrinsics = self.projection_utils.load_camera_intrinsics(cam_info_msg)
                self.get_logger().info(f'相機內參已載入:\n{self.camera_intrinsics}')

            # 轉換點雲到 numpy array
            points_base = self.pointcloud2_to_array(pc_msg)  # Nx3

            # 轉換到相機座標系
            try:
                transform = self.tf_buffer.lookup_transform(
                    'camera_link',
                    'base_link',
                    pc_msg.header.stamp,
                    timeout=rclpy.duration.Duration(seconds=0.1)
                )
            except Exception as e:
                self.get_logger().warn(f'TF 查找失敗: {e}')
                return

            points_camera = self.transform_points(points_base, transform)

            # 投影到圖像平面
            u, v, valid_mask = self.projection_utils.project_3d_to_2d(
                points_camera,
                self.camera_intrinsics
            )

            # 過濾圖像範圍外的點
            valid_in_image = (u >= 0) & (u < self.img_width) & (v >= 0) & (v < self.img_height)
            u_valid = u[valid_in_image]
            v_valid = v[valid_in_image]
            points_camera_valid = points_camera[valid_mask][valid_in_image]

            # 建立深度圖
            self.depth_map.clear()
            for i in range(len(u_valid)):
                pixel = (u_valid[i], v_valid[i])
                self.depth_map[pixel] = points_camera_valid[i]

            self.get_logger().debug(f'深度圖已更新：{len(self.depth_map)} 個像素')

        except Exception as e:
            self.get_logger().error(f'點雲處理錯誤: {e}')

    def detection_callback(self, det_msg: Detection2DArray):
        """處理 VLM 偵測結果"""
        if not self.depth_map:
            self.get_logger().warn('深度圖尚未建立，等待點雲數據')
            return

        for detection in det_msg.detections:
            try:
                # 提取 Bbox 中心
                u = int(detection.bbox.center.position.x)
                v = int(detection.bbox.center.position.y)

                # 查找鄰近像素的 3D 點
                neighbors = self.get_neighbor_points(u, v)
                if not neighbors:
                    self.get_logger().warn(f'像素 ({u}, {v}) 附近無有效深度資訊')
                    continue

                # 平均降噪
                point_3d_camera = np.mean(neighbors, axis=0)

                # 轉換到 base_link
                point_3d_base = self.transform_point_inverse(
                    point_3d_camera,
                    det_msg.header.stamp
                )

                # 轉換到 map
                point_3d_world = self.transform_to_map(
                    point_3d_base,
                    det_msg.header.stamp
                )

                # 發佈結果
                pose_msg = PoseStamped()
                pose_msg.header.stamp = self.get_clock().now().to_msg()
                pose_msg.header.frame_id = 'map'
                pose_msg.pose.position.x = point_3d_world[0]
                pose_msg.pose.position.y = point_3d_world[1]
                pose_msg.pose.position.z = point_3d_world[2]
                pose_msg.pose.orientation.w = 1.0  # 無旋轉

                self.pose_pub.publish(pose_msg)

                # 日誌
                obj_name = detection.results[0].hypothesis.class_id if detection.results else "未知"
                self.get_logger().info(
                    f'物體 "{obj_name}" 世界座標: '
                    f'({point_3d_world[0]:.2f}, {point_3d_world[1]:.2f}, {point_3d_world[2]:.2f})'
                )

            except Exception as e:
                self.get_logger().error(f'座標轉換錯誤: {e}')

    def get_neighbor_points(self, u: int, v: int) -> List[np.ndarray]:
        """取得鄰近像素的 3D 點"""
        neighbors = []
        for du in range(-self.neighbor_radius, self.neighbor_radius + 1):
            for dv in range(-self.neighbor_radius, self.neighbor_radius + 1):
                pixel = (u + du, v + dv)
                if pixel in self.depth_map:
                    neighbors.append(self.depth_map[pixel])
        return neighbors

    def transform_points(self, points: np.ndarray, transform: TransformStamped) -> np.ndarray:
        """轉換點雲（使用 TF）"""
        # 提取旋轉與平移
        t = transform.transform.translation
        r = transform.transform.rotation

        # 使用 scipy 或手動實作四元數旋轉
        from scipy.spatial.transform import Rotation
        rotation = Rotation.from_quat([r.x, r.y, r.z, r.w])

        points_rotated = rotation.apply(points)
        points_transformed = points_rotated + np.array([t.x, t.y, t.z])
        return points_transformed

    def transform_to_map(self, point_base: np.ndarray, timestamp) -> np.ndarray:
        """將 base_link 座標轉換到 map"""
        try:
            transform = self.tf_buffer.lookup_transform(
                'map',
                'base_link',
                timestamp,
                timeout=rclpy.duration.Duration(seconds=0.1)
            )
            point_transformed = self.transform_points(point_base.reshape(1, 3), transform)
            return point_transformed[0]
        except Exception as e:
            self.get_logger().error(f'TF 轉換失敗: {e}')
            return point_base

    def pointcloud2_to_array(self, pc_msg: PointCloud2) -> np.ndarray:
        """轉換 PointCloud2 為 numpy array"""
        import sensor_msgs_py.point_cloud2 as pc2
        points = []
        for point in pc2.read_points(pc_msg, field_names=("x", "y", "z"), skip_nans=True):
            points.append([point[0], point[1], point[2]])
        return np.array(points)


def main(args=None):
    rclpy.init(args=args)
    node = LiDARProjectionNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
```

---

#### C. `ground_assumption_node.py`（Plan B 備用）

```python
"""
地面假設節點（備用方案）
假設物體位於地面平面 (Z=0 in map frame)
"""
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import CameraInfo
from vision_msgs.msg import Detection2DArray
from geometry_msgs.msg import PoseStamped
from tf2_ros import Buffer, TransformListener
import numpy as np

from .projection_utils import ProjectionUtils


class GroundAssumptionNode(Node):
    def __init__(self):
        super().__init__('ground_assumption_node')

        # 參數
        self.declare_parameter('camera_info_topic', 'camera/camera_info')
        self.declare_parameter('detection_topic', '/detected_objects')
        self.declare_parameter('ground_z', 0.0)  # 地面高度（map frame）

        self.cam_info_topic = self.get_parameter('camera_info_topic').value
        self.det_topic = self.get_parameter('detection_topic').value
        self.ground_z = self.get_parameter('ground_z').value

        # TF2
        self.tf_buffer = Buffer()
        self.tf_listener = TransformListener(self.tf_buffer, self)

        # 工具
        self.projection_utils = ProjectionUtils()
        self.camera_intrinsics = None

        # 訂閱器
        self.cam_info_sub = self.create_subscription(
            CameraInfo,
            self.cam_info_topic,
            self.camera_info_callback,
            10
        )

        self.det_sub = self.create_subscription(
            Detection2DArray,
            self.det_topic,
            self.detection_callback,
            10
        )

        # 發佈器
        self.pose_pub = self.create_publisher(
            PoseStamped,
            '/object_pose_world',
            10
        )

        self.get_logger().info('地面假設節點已啟動')

    def camera_info_callback(self, msg: CameraInfo):
        if self.camera_intrinsics is None:
            self.camera_intrinsics = self.projection_utils.load_camera_intrinsics(msg)
            self.get_logger().info('相機內參已載入')

    def detection_callback(self, det_msg: Detection2DArray):
        if self.camera_intrinsics is None:
            self.get_logger().warn('等待相機內參')
            return

        for detection in det_msg.detections:
            try:
                # 提取像素座標
                u = detection.bbox.center.position.x
                v = detection.bbox.center.position.y

                # 反投影為射線（相機座標系）
                ray_camera = self.projection_utils.unproject_2d_to_ray(
                    u, v, self.camera_intrinsics
                )

                # 取得相機位姿（map frame）
                transform = self.tf_buffer.lookup_transform(
                    'map',
                    'camera_link',
                    det_msg.header.stamp,
                    timeout=rclpy.duration.Duration(seconds=0.1)
                )

                camera_position = np.array([
                    transform.transform.translation.x,
                    transform.transform.translation.y,
                    transform.transform.translation.z
                ])

                # 旋轉射線到 map frame
                from scipy.spatial.transform import Rotation
                r = transform.transform.rotation
                rotation = Rotation.from_quat([r.x, r.y, r.z, r.w])
                ray_world = rotation.apply(ray_camera)

                # 計算射線-平面交點
                intersection = self.projection_utils.ray_plane_intersection(
                    camera_position,
                    ray_world,
                    self.ground_z
                )

                if intersection is None:
                    self.get_logger().warn('射線未與地面相交')
                    continue

                # 發佈結果
                pose_msg = PoseStamped()
                pose_msg.header.stamp = self.get_clock().now().to_msg()
                pose_msg.header.frame_id = 'map'
                pose_msg.pose.position.x = intersection[0]
                pose_msg.pose.position.y = intersection[1]
                pose_msg.pose.position.z = intersection[2]
                pose_msg.pose.orientation.w = 1.0

                self.pose_pub.publish(pose_msg)

                obj_name = detection.results[0].hypothesis.class_id if detection.results else "未知"
                self.get_logger().info(
                    f'物體 "{obj_name}" 地面投影座標: '
                    f'({intersection[0]:.2f}, {intersection[1]:.2f})'
                )

            except Exception as e:
                self.get_logger().error(f'地面投影錯誤: {e}')


def main(args=None):
    rclpy.init(args=args)
    node = GroundAssumptionNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
```

---

## 🧪 測試與校正

### 1. 校正流程

#### 準備工作
1. 在地面放置已知位置的標記物（如 ArUco Marker）
2. 記錄真實座標（使用捲尺測量）

#### 測試步驟
```bash
# Terminal 1: 啟動系統
ros2 launch go2_robot_sdk robot.launch.py vlm:=true

# Terminal 2: 啟動座標轉換節點
ros2 run coordinate_transformer lidar_projection_node

# Terminal 3: 記錄轉換結果
ros2 topic echo /object_pose_world

# Terminal 4: 在 RViz 中可視化
rviz2 -d config/coordinate_debug.rviz
```

#### 誤差計算
```python
# 真實座標（手動測量）
ground_truth = np.array([2.5, 1.0, 0.0])

# 系統輸出
estimated = np.array([2.48, 1.05, 0.02])

# 水平誤差
error_xy = np.linalg.norm(ground_truth[:2] - estimated[:2])
print(f"水平誤差: {error_xy * 100:.1f} cm")
```

### 2. 效能基準

| 指標 | Plan A 目標 | Plan B 目標 |
|------|------------|------------|
| **水平誤差** | < 15 cm | < 25 cm |
| **處理延遲** | < 0.2 s | < 0.1 s |
| **成功率** | > 90% | > 80% |

---

## 📊 錯誤處理

### 常見問題與解決

**Q1: 深度圖稀疏（LiDAR 點不夠）**
```python
# 解決：增大鄰近搜索範圍
self.neighbor_radius = 10  # 從 5 增至 10
```

**Q2: TF 查找超時**
```python
# 解決：增加容差時間
timeout=rclpy.duration.Duration(seconds=0.5)
```

**Q3: 地面假設誤差大**
```python
# 解決：校正地面高度
self.ground_z = -0.05  # 根據實際測量調整
```

---

## 📚 相關資源

- [TF2 教學](https://docs.ros.org/en/humble/Tutorials/Intermediate/Tf2/Tf2-Main.html)
- [相機標定原理](https://docs.opencv.org/4.x/dc/dbb/tutorial_py_calibration.html)
- [sensor_msgs/PointCloud2](http://docs.ros.org/en/api/sensor_msgs/html/msg/PointCloud2.html)

---

**文件版本：** v1.0
**最後更新：** 2025/11/16
