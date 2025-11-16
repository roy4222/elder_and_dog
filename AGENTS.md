# Repository Guidelines
一律用繁體中文回答

## Project Structure & Module Organization
- Core ROS 2 Python SDK lives in `go2_robot_sdk/go2_robot_sdk` (application, domain, infrastructure, presentation layers).
- ROS 2 interfaces are in `go2_interfaces/msg` (message definitions used across packages).
- Sensor and perception packages: `lidar_processor`, `lidar_processor_cpp`, `coco_detector`, `speech_processor`.
- Docker assets are in `docker/`; repo‑level Python config is in `requirements.txt` and `setup.cfg`.

## Build, Test, and Development Commands
- From your ROS 2 workspace root (e.g. `ros2_ws`):
  - `source /opt/ros/$ROS_DISTRO/setup.bash`
  - `rosdep install --from-paths src --ignore-src -r -y`
  - `colcon build` — builds all ROS 2 packages in `src/`.
- Run the main stack locally (after build):
  - `source install/setup.bash`
  - `ros2 launch go2_robot_sdk robot.launch.py`
- Run via Docker: `cd docker && ROBOT_IP=<ip> CONN_TYPE=<webrtc|cyclonedds> docker-compose up --build`.

## Coding Style & Naming Conventions
- Python: 4‑space indentation, max line length 100, enforced with `flake8` (`setup.cfg`).
- Prefer `snake_case` for variables/functions, `PascalCase` for classes, and lower_snake ROS 2 topic names (e.g. `/go2/cmd_vel`).
- C++ (`lidar_processor_cpp`): follow existing style and ament/ROS 2 formatting (e.g. `ament_uncrustify`).

## Testing Guidelines
- Python tests use `pytest`; configuration and coverage (`--cov=go2_robot_sdk`) are defined in `setup.cfg`.
- Name tests `test_*.py` and co‑locate near the code they cover or under a `tests/` folder.
- For ROS 2 integration tests, prefer `colcon test` from the workspace root.

## Commit & Pull Request Guidelines
- Follow conventional commit style where possible, e.g. `feat: ...`, `fix: ...`, `docs: ...`, `style: ...`.
- Keep commits focused and descriptive; explain *what* changed and *why* in the PR description.
- Reference related issues, and for behavior/visual changes (e.g. RViz configs), include short usage notes or screenshots.

## Agent-Specific Instructions
- Respect the existing clean architecture boundaries in `go2_robot_sdk` (do not mix domain logic with presentation/ROS node wiring).
- Prefer minimal, targeted changes; avoid renaming public topics, messages, or launch file interfaces without clear justification.
