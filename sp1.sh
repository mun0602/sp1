#!/bin/bash

# Script kiểm tra tốc độ mạng cho Ubuntu
# Tạo bởi Claude

echo "===== KIỂM TRA TỐC ĐỘ MẠNG ====="
echo "Đang bắt đầu kiểm tra..."

# Kiểm tra các công cụ cần thiết
check_tools() {
    local missing_tools=()
    
    if ! command -v speedtest-cli &> /dev/null; then
        missing_tools+=("speedtest-cli")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Các công cụ sau chưa được cài đặt: ${missing_tools[*]}"
        echo "Đang cài đặt các công cụ cần thiết..."
        
        sudo apt update
        for tool in "${missing_tools[@]}"; do
            sudo apt install -y "$tool"
        done
        
        echo "Đã cài đặt các công cụ cần thiết."
    fi
}

# Kiểm tra kết nối cơ bản
check_basic_connection() {
    echo ""
    echo "===== KIỂM TRA KẾT NỐI CƠ BẢN ====="
    
    # Kiểm tra ping tới Google DNS
    echo "Đang kiểm tra ping tới 8.8.8.8..."
    ping -c 4 8.8.8.8
    
    # Kiểm tra độ trễ (latency) trung bình
    avg_latency=$(ping -c 10 8.8.8.8 | tail -1 | awk -F '/' '{print $5}')
    echo "Độ trễ trung bình: ${avg_latency} ms"
    
    # Kiểm tra DNS
    echo ""
    echo "Đang kiểm tra phân giải DNS..."
    dig google.com +short
}

# Kiểm tra tốc độ sử dụng speedtest-cli
run_speedtest() {
    echo ""
    echo "===== KIỂM TRA TỐC ĐỘ MẠNG CHI TIẾT ====="
    echo "Đang chạy speedtest-cli (có thể mất vài phút)..."
    speedtest-cli --simple
    
    echo ""
    echo "Kiểm tra tốc độ chi tiết hơn..."
    speedtest-cli
}

# Kiểm tra tốc độ tải file từ các server khác nhau
test_download_speed() {
    echo ""
    echo "===== KIỂM TRA TỐC ĐỘ TẢI FILE ====="
    
    # Danh sách URL để kiểm tra
    urls=(
        "http://speedtest.ftp.otenet.gr/files/test10Mb.db"
        "http://speedtest.tele2.net/10MB.zip"
        "http://ipv4.download.thinkbroadband.com/5MB.zip"
    )
    
    for url in "${urls[@]}"; do
        echo "Đang kiểm tra tốc độ tải từ: $url"
        curl -L -o /dev/null -w "Tốc độ tải: %{speed_download} bytes/giây\nThời gian: %{time_total} giây\n\n" "$url"
    done
}

# Hiển thị thông tin mạng
show_network_info() {
    echo ""
    echo "===== THÔNG TIN MẠNG ====="
    
    echo "Thông tin giao diện mạng:"
    ip -brief addr show
    
    echo ""
    echo "Thông tin bảng định tuyến:"
    ip route
    
    echo ""
    echo "Địa chỉ IP công cộng:"
    curl -s ifconfig.me
    echo ""
}

# Chạy tất cả các kiểm tra
run_all_tests() {
    check_tools
    show_network_info
    check_basic_connection
    test_download_speed
    run_speedtest
    
    echo ""
    echo "===== KẾT QUẢ KIỂM TRA HOÀN TẤT ====="
    echo "Thời gian kiểm tra: $(date)"
}

# Hàm hiển thị menu
show_menu() {
    clear
    echo "===== MENU KIỂM TRA TỐC ĐỘ MẠNG ====="
    echo "1. Chạy tất cả các kiểm tra"
    echo "2. Kiểm tra thông tin mạng"
    echo "3. Kiểm tra kết nối cơ bản"
    echo "4. Kiểm tra tốc độ tải file"
    echo "5. Chạy speedtest-cli"
    echo "0. Thoát"
    echo ""
    echo -n "Vui lòng chọn một tùy chọn (0-5): "
}

# Xử lý lựa chọn menu
handle_menu() {
    local choice
    read choice
    
    case $choice in
        1) run_all_tests ;;
        2) check_tools && show_network_info ;;
        3) check_tools && check_basic_connection ;;
        4) check_tools && test_download_speed ;;
        5) check_tools && run_speedtest ;;
        0) echo "Tạm biệt!" && exit 0 ;;
        *) echo "Lựa chọn không hợp lệ. Vui lòng thử lại." ;;
    esac
    
    echo ""
    echo "Nhấn Enter để tiếp tục..."
    read
}

# Chạy chương trình
while true; do
    show_menu
    handle_menu
done
