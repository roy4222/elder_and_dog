from setuptools import find_packages, setup
import os
from glob import glob

package_name = 'search_logic'

setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        # 安裝配置檔案
        (os.path.join('share', package_name, 'config'), glob('config/*.yaml')),
        # 安裝 launch 檔案（未來使用）
        (os.path.join('share', package_name, 'launch'), glob('launch/*.py')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='FJU Go2 Team',
    maintainer_email='your-email@example.com',
    description='簡單巡邏與導航測試套件（不依賴 VLM）',
    license='MIT',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'simple_patrol_node = search_logic.simple_patrol_node:main',
        ],
    },
)
