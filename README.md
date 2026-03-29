# 密码管理器

一个简单、安全的命令行密码管理工具，使用 AES-256-CBC 加密算法保护您的密码。

## 功能特性

- **安全加密**：使用 OpenSSL AES-256-CBC 加密算法
- **主密码保护**：通过主密码保护所有存储的密码
- **交互式界面**：支持 fzf 交互式选择操作
- **命令行操作**：支持完整的命令行参数操作
- **本地存储**：密码文件存储在本地 `~/.passwords.enc`

## 依赖

- Bash
- OpenSSL
- fzf（可选，用于交互式界面）

## 安装

```bash
# 克隆仓库
git clone https://github.com/coolfishchen/passwd_keep.git

# 添加执行权限
chmod +x pwd_keeper.sh

# 移动到 PATH（可选）
mv pwd_keeper.sh /usr/local/bin/pwd_keeper
```

## 使用方法

### 交互式模式

直接运行脚本进入交互式界面：

```bash
./pwd_keeper.sh
```

交互式菜单：
- 查看密码
- 添加密码
- 修改密码
- 删除密码

### 命令行模式

```bash
# 添加密码
./pwd_keeper.sh add

# 列出所有密码描述
./pwd_keeper.sh list

# 列出所有密码描述和密码内容
./pwd_keeper.sh list -a

# 查看指定密码
./pwd_keeper.sh show [key]

# 交互式选择查看密码
./pwd_keeper.sh show

# 修改指定密码
./pwd_keeper.sh edit [key]

# 删除指定密码
./pwd_keeper.sh delete [key]

# 显示帮助
./pwd_keeper.sh --help
```

## 安全说明

1. 所有密码使用 AES-256-CBC 加密存储
2. 需要记住主密码，无法找回
3. 主密码在首次使用时设置
4. 密码文件存储在 `~/.passwords.enc`

## 示例

```bash
# 首次使用，设置主密码并添加第一个密码
$ ./pwd_keeper.sh add
输入主密码: 
描述 (key): GitHub
密码 (value): 
密码已添加

# 查看所有密码描述
$ ./pwd_keeper.sh list
输入主密码: 
GitHub
Email

# 查看指定密码
$ ./pwd_keeper.sh show GitHub
输入主密码: 
GitHub: my_github_password

# 修改密码
$ ./pwd_keeper.sh edit GitHub
输入主密码: 
输入新密码: 
密码已更新

# 删除密码
$ ./pwd_keeper.sh delete GitHub
输入主密码: 
密码已删除
```

## 文件结构

```
passwd_keep/
├── pwd_keeper.sh    # 主程序脚本
└── README.md        # 说明文档
```

## 注意事项

- 请妥善保管主密码，丢失后无法恢复
- 建议定期备份密码文件 `~/.passwords.enc`
- 不要在公共场合使用 `list -a` 命令

## 许可证

MIT License