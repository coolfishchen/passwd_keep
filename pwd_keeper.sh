#!/bin/bash

PASSWORD_FILE="$HOME/.passwords.enc"
VERIFY_MARKER="PWD_KEEPER_VERIFY"

encrypt_data() {
    openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$MASTER_PASSWORD"
}

decrypt_data() {
    openssl enc -aes-256-cbc -salt -pbkdf2 -d -pass pass:"$MASTER_PASSWORD" 2>/dev/null
}

verify_password() {
    local first_line=$(decrypt_data < "$PASSWORD_FILE" 2>/dev/null | head -1)
    if [ "$first_line" = "$VERIFY_MARKER" ]; then
        return 0
    fi
    return 1
}

get_master_password() {
    if [ -z "$MASTER_PASSWORD" ]; then
        read -s -p "输入主密码: " MASTER_PASSWORD
        echo
    fi
    
    if [ -f "$PASSWORD_FILE" ]; then
        if ! verify_password; then
            echo "主密码错误"
            exit 1
        fi
    fi
}

add_password() {
    local key value
    read -p "描述 (key): " key
    read -s -p "密码 (value): " value
    echo
    
    if [ -z "$key" ] || [ -z "$value" ]; then
        echo "错误: 描述和密码不能为空"
        return 1
    fi
    
    local existing=""
    if [ -f "$PASSWORD_FILE" ]; then
        existing=$(decrypt_data < "$PASSWORD_FILE" | tail -n +2)
    fi
    
    if [ -n "$existing" ]; then
        echo -e "$VERIFY_MARKER\n$existing\n$key=$value" | encrypt_data > "$PASSWORD_FILE"
    else
        echo -e "$VERIFY_MARKER\n$key=$value" | encrypt_data > "$PASSWORD_FILE"
    fi
    echo "密码已添加"
}

list_passwords() {
    local show_passwords="$1"
    if [ -f "$PASSWORD_FILE" ]; then
        if [ "$show_passwords" = "-a" ] || [ "$show_passwords" = "--all" ]; then
            decrypt_data < "$PASSWORD_FILE" | tail -n +2 | grep -v '^$' | while IFS='=' read -r key value; do
                [ -n "$key" ] && echo "$key: $value"
            done
        else
            decrypt_data < "$PASSWORD_FILE" | tail -n +2 | grep -v '^$' | while IFS='=' read -r key value; do
                [ -n "$key" ] && echo "$key"
            done
        fi
    fi
}

show_password() {
    local key="$1"
    if [ -f "$PASSWORD_FILE" ]; then
        decrypt_data < "$PASSWORD_FILE" | tail -n +2 | grep "^${key}=" | while read -r line; do
            echo "${line#*=}"
        done | head -1
    fi
}

edit_password() {
    local key="$1"
    local new_value
    
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo "密码文件不存在"
        return 1
    fi
    
    read -s -p "输入新密码: " new_value
    echo
    
    local decrypted=$(decrypt_data < "$PASSWORD_FILE")
    if [ -z "$decrypted" ]; then
        echo "解密失败"
        return 1
    fi
    
    local updated="$VERIFY_MARKER"$'\n'
    local found=0
    local first_line=1
    while IFS= read -r line; do
        if [ "$first_line" -eq 1 ]; then
            first_line=0
            continue
        fi
        if [[ "$line" == "$key="* ]]; then
            updated+="$key=$new_value"$'\n'
            found=1
        else
            updated+="$line"$'\n'
        fi
    done <<< "$decrypted"
    
    if [ "$found" -eq 1 ]; then
        echo -n "$updated" | encrypt_data > "$PASSWORD_FILE"
        echo "密码已更新"
    else
        echo "未找到该条目"
    fi
}

delete_password() {
    local key="$1"
    
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo "密码文件不存在"
        return 1
    fi
    
    local decrypted=$(decrypt_data < "$PASSWORD_FILE")
    if [ -z "$decrypted" ]; then
        echo "解密失败"
        return 1
    fi
    
    local count=$(echo "$decrypted" | tail -n +2 | grep -c "^${key}=" || echo 0)
    if [ "$count" -eq 0 ]; then
        echo "未找到该条目"
        return 1
    fi
    
    local remaining=$(echo "$decrypted" | tail -n +2 | grep -v "^${key}=")
    if [ -n "$remaining" ]; then
        echo -e "$VERIFY_MARKER\n$remaining" | encrypt_data > "$PASSWORD_FILE"
    else
        rm -f "$PASSWORD_FILE"
    fi
    echo "密码已删除"
}

interactive_mode() {
    local action key
    action=$(echo -e "查看密码\n添加密码\n修改密码\n删除密码\n退出" | fzf --height=40% --prompt="操作: ")
    
    case "$action" in
        "查看密码")
            key=$(list_passwords | fzf --height=40% --prompt="选择: ")
            [ -n "$key" ] && echo "$key: $(show_password "$key")"
            ;;
        "添加密码")
            add_password
            ;;
        "修改密码")
            key=$(list_passwords | fzf --height=40% --prompt="选择: ")
            [ -n "$key" ] && edit_password "$key"
            ;;
        "删除密码")
            key=$(list_passwords | fzf --height=40% --prompt="选择: ")
            [ -n "$key" ] && delete_password "$key"
            ;;
        "退出")
            exit 0
            ;;
    esac
}

if [ $# -eq 0 ]; then
    get_master_password
    interactive_mode
else
    case "$1" in
        add)
            get_master_password
            add_password
            ;;
        list)
            get_master_password
            list_passwords "$2"
            ;;
        show)
            get_master_password
            if [ -n "$2" ]; then
                echo "$2: $(show_password "$2")"
            else
                key=$(list_passwords | fzf --height=40% --prompt="选择: ")
                [ -n "$key" ] && echo "$key: $(show_password "$key")"
            fi
            ;;
        edit)
            get_master_password
            [ -n "$2" ] && edit_password "$2"
            ;;
        delete)
            get_master_password
            [ -n "$2" ] && delete_password "$2"
            ;;
        -h|--help)
            echo "用法: $0 [command] [options]"
            echo ""
            echo "命令:"
            echo "  add              添加密码"
            echo "  list [-a]        列出密码描述（-a 显示密码）"
            echo "  show [key]       查看指定密码（无 key 时交互选择）"
            echo "  edit [key]       修改指定密码（无 key 时交互选择）"
            echo "  delete [key]     删除指定密码（无 key 时交互选择）"
            echo "  -h, --help       显示帮助信息"
            ;;
        *)
            echo "用法: $0 [add|list [-a]|show [key]|edit [key]|delete [key]]"
            ;;
    esac
fi