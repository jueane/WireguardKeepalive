创建 requirements.txt 文件：
pip freeze > requirements.txt


配置虚拟环境：
（安装python3-venv）
python -m venv venv  # 创建虚拟环境
source venv/bin/activate  # 激活虚拟环境（Windows 上使用 venv\Scripts\activate）
pip install -r requirements.txt  # 安装依赖
deactivate

