# OpenList Magisk 模块

[![Release](https://img.shields.io/github/v/release/Alien-Et/OpenList-Magisk)](https://github.com/Alien-Et/OpenList-Magisk/releases)
[![License](https://img.shields.io/github/license/Alien-Et/OpenList-Magisk)](https://github.com/Alien-Et/OpenList-Magisk/blob/main/LICENSE)

OpenList Magisk 模块将 [OpenList](https://github.com/OpenListTeam/OpenList) 文件服务器集成到 Android 系统中，通过 Magisk 以系统化方式运行，支持 ARM 和 ARM64 架构。

## 功能亮点

- **替换openlist源**：实现123网盘无限制下载
- **灵活安装选项**：支持三种安装位置
  - data/adb/openlist
  - 模块目录/bin
  - system/bin
- **数据目录可选**：支持两种数据存储位置
  - /data/adb/openlist/
  - /storage/emulated/0/Android/openlist/
- **密码定制**：提供初始密码设置选项
- **动态服务管理**：通过 Magisk 的"动作"按钮一键控制服务
- **智能网络适配**：自动识别 WiFi 和移动网络 IP
- **日志支持**：详细的运行日志记录

## 系统要求

- Android 设备（支持 ARM 或 ARM64 架构）
- Magisk v20.4 或更高版本
- Root 权限

## 安装步骤

1. **下载模块**
   - 从 [GitHub Releases](https://github.com/Alien-Et/OpenList-Magisk/releases) 下载最新版本

2. **安装配置**
   - 打开 Magisk 管理器
   - 选择"从本地安装"
   - 进入安装配置界面：
     - 选择二进制文件安装位置
     - 选择数据目录存储位置
     - 选择是否修改默认密码为 admin

3. **完成安装**
   - 等待安装完成
   - 重启设备

## 使用说明

### 服务管理
- 系统启动后自动运行
- 通过 Magisk "动作"按钮控制服务
- 服务状态显示在 module.prop：
  - 运行中：显示访问地址和数据目录
  - 已停止：显示启动提示

### 访问方式
- Web 界面访问：`http://<设备IP>:5244`
- 初始密码：查看数据目录下的 `初始密码.txt`

### 数据存储
- 默认数据目录：`/data/adb/openlist/`
- 日志文件位置：与数据目录相同
- 密码文件：`初始密码.txt`

## 故障排除

### 常见问题
1. **无法访问服务**
   - 检查网络连接
   - 检查服务状态：`pgrep -f openlist`
   - 查看日志文件
   - 手动重启服务：`su -c /data/adb/modules/openlist/service.sh`

2. **IP 地址获取失败**
   - 确认 WiFi 或移动网络已连接
   - 检查网络接口状态
   - 查看模块日志

3. **服务无法启动**
   - 检查二进制文件权限
   - 确认数据目录可写
   - 查看详细日志

### 手动操作
- 停止服务：`su -c pkill -f openlist`
- 启动服务：`su -c /data/adb/modules/openlist/service.sh`
- 查看日志：`cat /data/adb/modules/openlist/service.log`

## 更新说明
- 支持通过 Magisk 更新检查
- 更新不会清除现有数据
- 可在安装时重新选择配置选项

## 数据迁移说明
1. 在安装时选择新的数据目录
2. 手动将现有数据迁移到新目录
3. 更新 config.json 中的相关路径

## 贡献
- 欢迎提交 Issue 和 Pull Request
- 问题反馈：[GitHub Issues](https://github.com/Alien-Et/OpenList-Magisk/issues)

## 许可证
本项目基于 [MIT 许可证](LICENSE) 发布。