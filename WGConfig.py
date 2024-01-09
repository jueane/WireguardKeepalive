class WgConfig:
    # 允许ping失败的次数
    allow_max_error_count = 3

    def __init__(self, file_path, wg_name, ip):
        self.file_path = file_path
        self.wg_name = wg_name
        self.ip = ip
        self.down_count = 0
        # 上次是在线的
        self.is_last_up = False
