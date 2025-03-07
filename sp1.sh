#!/bin/bash

# Script kiểm tra tốc độ mạng cho Ubuntu - Phiên bản nhẹ
# Tạo bởi Claude

# Màu sắc (giới hạn số lượng màu để giảm tài nguyên)
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Biểu tượng đơn giản
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
ARROW="${YELLOW}→${RESET}"

# Hàm in tiêu đề chính
print_header() {
    clear
    echo -e "${BLUE}=======================================================${RESET}"
    echo -e "${BLUE}           KIỂM TRA TỐC ĐỘ MẠNG UBUNTU${RESET}"
    echo -e "${BLUE}=======================================================${RESET}"
    echo ""
}

# Hàm in tiêu đề phần
print_section() {
    local title="$1"
    echo ""
    echo -e "${YELLOW}-------------------------------------------------------${RESET}"
    echo -e "${BOLD}$title${RESET}"
    echo -e "${YELLOW}-------------------------------------------------------${RESET}"
    echo ""
}

# Kiểm tra công cụ cần thiết (giảm thiểu output không cần thiết)
check_tools() {
    print_section "KIỂM TRA CÔNG CỤ"
    
    local missing_tools=()
    
    echo -ne "${ARROW} Kiểm tra speedtest-cli... "
    if ! command -v speedtest-cli &> /dev/null; then
        echo -e "${CROSS} Chưa cài đặt"
        missing_tools+=("speedtest-cli")
    else
        echo -e "${CHECK} Đã cài đặt"
    fi
    
    echo -ne "${ARROW} Kiểm tra curl... "
    if ! command -v curl &> /dev/null; then
        echo -e "${CROSS} Chưa cài đặt"
        missing_tools+=("curl")
    else
        echo -e "${CHECK} Đã cài đặt"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo ""
        echo -e "${ARROW} Cài đặt các công cụ còn thiếu: ${YELLOW}${missing_tools[*]}${RESET}"
        
        sudo apt update -qq
        for tool in "${missing_tools[@]}"; do
            echo -ne "${ARROW} Đang cài ${YELLOW}$tool${RESET}... "
            sudo apt install -y "$tool" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CHECK} Xong"
            else
                echo -e "${CROSS} Lỗi"
                exit 1
            fi
        done
    fi
}

# Kiểm tra kết nối cơ bản (rút gọn)
check_basic_connection() {
    print_section "KIỂM TRA KẾT NỐI CƠ BẢN"
    
    # Kiểm tra ping tới Google DNS
    echo -e "${ARROW} ${BOLD}Ping tới 8.8.8.8:${RESET}"
    
    ping_output=$(ping -c 4 8.8.8.8 2>&1)
    if [ $? -eq 0 ]; then
        # Chỉ hiển thị dòng tổng kết
        avg_ping=$(echo "$ping_output" | tail -1)
        echo -e "  $avg_ping" | sed -e "s/rtt/Độ trễ/" -e "s/min/tối thiểu/" -e "s/avg/trung bình/" -e "s/max/tối đa/" -e "s/mdev/độ lệch/"
        
        # Lấy độ trễ trung bình
        avg_latency=$(echo "$ping_output" | tail -1 | awk -F '/' '{print $5}')
        latency_float=$(echo "$avg_latency" | awk '{print int($1)}')
        
        # Đánh giá đơn giản
        echo -ne "${ARROW} Đánh giá: "
        if [ $latency_float -lt 50 ]; then
            echo -e "${GREEN}Rất tốt${RESET}"
        elif [ $latency_float -lt 100 ]; then
            echo -e "${GREEN}Tốt${RESET}"
        elif [ $latency_float -lt 150 ]; then
            echo -e "${YELLOW}Trung bình${RESET}"
        else
            echo -e "${RED}Kém${RESET}"
        fi
    else
        echo -e "${CROSS} ${RED}Không thể ping đến 8.8.8.8${RESET}"
    fi
    
    # Kiểm tra DNS (rút gọn)
    echo ""
    echo -e "${ARROW} ${BOLD}Phân giải DNS:${RESET}"
    dns_result=$(dig google.com +short 2>&1 | head -1)
    if [ $? -eq 0 ] && [ ! -z "$dns_result" ]; then
        echo -e "  google.com → $dns_result"
    else
        echo -e "${CROSS} ${RED}Không thể phân giải DNS${RESET}"
    fi
}

# Kiểm tra tốc độ mạng (tối ưu hóa)
run_speedtest() {
    print_section "KIỂM TRA TỐC ĐỘ MẠNG"
    
    echo -e "${ARROW} ${BOLD}Đang chạy speedtest (có thể mất vài phút)...${RESET}"
    echo ""
    
    # Chỉ chạy phiên bản đơn giản
    speedtest_output=$(speedtest-cli --simple 2>&1)
    if [ $? -eq 0 ]; then
        ping=$(echo "$speedtest_output" | grep "Ping:" | awk '{print $2}')
        download=$(echo "$speedtest_output" | grep "Download:" | awk '{print $2}')
        upload=$(echo "$speedtest_output" | grep "Upload:" | awk '{print $2}')
        
        echo -e "${BOLD}Kết quả:${RESET}"
        echo -e "  Ping:      ${YELLOW}$ping ms${RESET}"
        echo -e "  Tải xuống: ${GREEN}$download Mbit/s${RESET}"
        echo -e "  Tải lên:   ${GREEN}$upload Mbit/s${RESET}"
        
        # Đánh giá đơn giản
        download_float=$(echo "$download" | awk '{print int($1)}')
        echo ""
        echo -ne "${ARROW} Đánh giá tốc độ: "
        if [ $download_float -gt 100 ]; then
            echo -e "${GREEN}Rất tốt${RESET}"
        elif [ $download_float -gt 50 ]; then
            echo -e "${GREEN}Tốt${RESET}"
        elif [ $download_float -gt 25 ]; then
            echo -e "${YELLOW}Trung bình${RESET}"
        elif [ $download_float -gt 10 ]; then
            echo -e "${YELLOW}Thấp${RESET}"
        else
            echo -e "${RED}Rất thấp${RESET}"
        fi
    else
        echo -e "${CROSS} ${RED}Không thể chạy speedtest-cli${RESET}"
    fi
}

# Kiểm tra tốc độ tải file (chỉ chạy 1 server)
test_download_speed() {
    print_section "KIỂM TRA TỐC ĐỘ TẢI FILE"
    
    # Chỉ chọn 1 URL để giảm tài nguyên
    url="http://speedtest.tele2.net/10MB.zip"
    
    echo -e "${ARROW} ${BOLD}Tải file kiểm tra từ:${RESET} $url"
    echo -e "${ARROW} Đang tải..."
    
    result=$(curl -L -o /dev/null -w "%{speed_download} %{time_total}" "$url" 2>/dev/null)
    if [ $? -eq 0 ]; then
        speed=$(echo $result | awk '{print $1}')
        time=$(echo $result | awk '{print $2}')
        
        # Chuyển đổi tốc độ từ byte/s sang MB/s
        speed_mb=$(echo "scale=2; $speed/1024/1024" | bc)
        
        echo -e "${CHECK} ${BOLD}Kết quả:${RESET}"
        echo -e "  Tốc độ tải: ${GREEN}$speed_mb MB/s${RESET}"
        echo -e "  Thời gian:  ${YELLOW}$time giây${RESET}"
    else
        echo -e "${CROSS} ${RED}Không thể tải từ server này${RESET}"
    fi
}

# Hiển thị thông tin mạng (đơn giản hóa)
show_network_info() {
    print_section "THÔNG TIN MẠNG"
    
    echo -e "${ARROW} ${BOLD}Giao diện mạng:${RESET}"
    
    # Chỉ hiển thị các giao diện UP
    ip -brief addr show | grep -v DOWN | while read line; do
        interface=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $2}')
        ip_addr=$(echo $line | awk '{print $3}')
        
        echo -e "  ${GREEN}$interface${RESET}: $ip_addr"
    done
    
    echo ""
    echo -e "${ARROW} ${BOLD}Gateway mặc định:${RESET}"
    ip route | grep default | head -1
    
    echo ""
    echo -e "${ARROW} ${BOLD}Địa chỉ IP công cộng:${RESET}"
    public_ip=$(curl -s ifconfig.me)
    if [ ! -z "$public_ip" ]; then
        echo -e "  ${YELLOW}$public_ip${RESET}"
    else
        echo -e "${CROSS} ${RED}Không thể lấy địa chỉ IP công cộng${RESET}"
    fi
}

# Chạy kiểm tra tổng quan (phiên bản nhẹ)
run_quick_test() {
    print_header
    check_tools
    
    print_section "KIỂM TRA NHANH"
    
    # Ping test
    echo -e "${ARROW} ${BOLD}Độ trễ trung bình:${RESET}"
    ping -c 3 8.8.8.8 | tail -1
    
    # Tốc độ mạng tóm tắt
    echo -e "${ARROW} ${BOLD}Tốc độ mạng tóm tắt:${RESET}"
    speedtest-cli --simple
    
    # Thông tin IP
    echo -e "${ARROW} ${BOLD}Địa chỉ IP công cộng:${RESET} $(curl -s ifconfig.me)"
    
    print_section "KIỂM TRA NHANH HOÀN TẤT"
    echo -e "${ARROW} ${BOLD}Thời gian:${RESET} $(date)"
}

# Chạy tất cả các kiểm tra (rút gọn)
run_all_tests() {
    print_header
    check_tools
    show_network_info
    check_basic_connection
    test_download_speed
    run_speedtest
    
    print_section "KẾT QUẢ KIỂM TRA HOÀN TẤT"
    echo -e "${ARROW} ${BOLD}Thời gian:${RESET} $(date)"
}

# Hàm hiển thị menu (đơn giản hóa)
show_menu() {
    print_header
    echo -e "${BLUE}-------------------------------------------------------${RESET}"
    echo -e "${BOLD}MENU KIỂM TRA TỐC ĐỘ MẠNG${RESET}"
    echo -e "${BLUE}-------------------------------------------------------${RESET}"
    echo -e " ${YELLOW}1.${RESET} Kiểm tra nhanh (ít tài nguyên nhất)"
    echo -e " ${YELLOW}2.${RESET} Chạy tất cả các kiểm tra"
    echo -e " ${YELLOW}3.${RESET} Kiểm tra thông tin mạng"
    echo -e " ${YELLOW}4.${RESET} Kiểm tra kết nối cơ bản"
    echo -e " ${YELLOW}5.${RESET} Kiểm tra tốc độ tải file"
    echo -e " ${YELLOW}6.${RESET} Chạy speedtest-cli"
    echo -e " ${YELLOW}0.${RESET} Thoát"
    echo -e "${BLUE}-------------------------------------------------------${RESET}"
    echo ""
    echo -ne "${ARROW} ${BOLD}Chọn tùy chọn (0-6):${RESET} "
}

# Xử lý lựa chọn menu
handle_menu() {
    local choice
    read choice
    
    case $choice in
        1) run_quick_test ;;
        2) run_all_tests ;;
        3) check_tools && show_network_info ;;
        4) check_tools && check_basic_connection ;;
        5) check_tools && test_download_speed ;;
        6) check_tools && run_speedtest ;;
        0) 
           clear
           echo -e "${GREEN}=======================================================${RESET}"
           echo -e "${GREEN}                      TẠM BIỆT!                        ${RESET}"
           echo -e "${GREEN}=======================================================${RESET}"
           exit 0 
           ;;
        *) 
           echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${RESET}" 
           ;;
    esac
    
    echo ""
    echo -ne "${ARROW} Nhấn Enter để tiếp tục... "
    read
}

# Chạy chương trình
while true; do
    show_menu
    handle_menu
done
