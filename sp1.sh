#!/bin/bash

# Cập nhật và cài đặt speedtest-cli
echo "Đang cập nhật hệ thống và cài đặt speedtest-cli..."
sudo apt update -y && sudo apt install speedtest-cli -y

# Lấy danh sách máy chủ gần nhất
echo "Lấy danh sách máy chủ speedtest gần nhất..."
SPEEDTEST_SERVERS=$(speedtest-cli --list | head -n 10) # Lấy 10 máy chủ đầu tiên

if [[ -z "$SPEEDTEST_SERVERS" ]]; then
    echo "Không tìm thấy máy chủ nào!"
    exit 1
fi

# Lặp qua từng máy chủ và chạy speedtest
echo "Đang chạy speedtest trên từng máy chủ..."
echo "$SPEEDTEST_SERVERS" | while read -r line; do
    SERVER_ID=$(echo "$line" | awk -F')' '{print $1}' | awk '{print $1}')
    
    if [[ -n "$SERVER_ID" ]]; then
        echo "Đang kiểm tra với máy chủ ID: $SERVER_ID"
        speedtest-cli --server "$SERVER_ID"
        echo "-----------------------------"
    fi
done

echo "Hoàn thành kiểm tra tốc độ với tất cả máy chủ gần nhất."
