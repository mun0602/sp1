#!/bin/bash

# Script kiểm tra tốc độ mạng cho Ubuntu với giao diện đẹp mắt
# Tạo bởi Claude

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# Các biểu tượng
CHECK_MARK="${GREEN}✓${RESET}"
CROSS_MARK="${RED}✗${RESET}"
ARROW="${YELLOW}➜${RESET}"
ROCKET="${CYAN}🚀${RESET}"
GLOBE="${BLUE}🌐${RESET}"
CLOCK="${YELLOW}⏱${RESET}"
INFO="${BLUE}ℹ${RESET}"

# Hàm in tiêu đề
print_header() {
    clear
    echo -e "${BLUE}╔═════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║                                                             ║${RESET}"
    echo -e "${BLUE}║${YELLOW}                  KIỂM TRA TỐC ĐỘ MẠNG UBUNTU                ${BLUE}║${RESET}"
    echo -e "${BLUE}║                                                             ║${RESET}"
    echo -e "${BLUE}╚═════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# Hàm in tiêu đề phần
print_section() {
    local title="$1"
    echo ""
    echo -e "${MAGENTA}┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${WHITE} ${BOLD}$title${RESET}${MAGENTA}                                                   │${RESET}"
    echo -e "${MAGENTA}└─────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

# Hàm hiển thị thanh tiến trình
progress_bar() {
    local duration=$1
    local steps=20
    local step_duration=$(echo "scale=2; $duration/$steps" | bc)
    
    echo -ne "${YELLOW}[${RESET}"
    for ((i=0; i<steps; i++)); do
        echo -ne "${CYAN}░${RESET}"
    done
    echo -ne "${YELLOW}]${RESET} ${MAGENTA}0%${RESET}"
    
    for ((i=0; i<steps; i++)); do
        sleep $step_duration
        echo -ne "\r${YELLOW}[${RESET}"
        for ((j=0; j<=i; j++)); do
            echo -ne "${GREEN}█${RESET}"
        done
        for ((j=i+1; j<steps; j++)); do
            echo -ne "${CYAN}░${RESET}"
        done
        local percentage=$((100*(i+1)/steps))
        echo -ne "${YELLOW}]${RESET} ${MAGENTA}$percentage%${RESET}"
    done
    echo ""
}

# Hàm kiểm tra các công cụ cần thiết
check_tools() {
    print_section "KIỂM TRA CÔNG CỤ CẦN THIẾT"
    
    local missing_tools=()
    
    echo -ne "${ARROW} Đang kiểm tra speedtest-cli... "
    if ! command -v speedtest-cli &> /dev/null; then
        echo -e "${CROSS_MARK} Chưa cài đặt"
        missing_tools+=("speedtest-cli")
    else
        echo -e "${CHECK_MARK} Đã cài đặt"
    fi
    
    echo -ne "${ARROW} Đang kiểm tra curl... "
    if ! command -v curl &> /dev/null; then
        echo -e "${CROSS_MARK} Chưa cài đặt"
        missing_tools+=("curl")
    else
        echo -e "${CHECK_MARK} Đã cài đặt"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo ""
        echo -e "${INFO} Các công cụ sau chưa được cài đặt: ${YELLOW}${missing_tools[*]}${RESET}"
        echo -e "${INFO} Đang cài đặt các công cụ cần thiết..."
        
        sudo apt update
        for tool in "${missing_tools[@]}"; do
            echo -ne "${ARROW} Đang cài đặt ${YELLOW}$tool${RESET}... "
            sudo apt install -y "$tool" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CHECK_MARK} Đã cài đặt thành công"
            else
                echo -e "${CROSS_MARK} Cài đặt thất bại"
                exit 1
            fi
        done
        
        echo -e "${INFO} Đã cài đặt tất cả các công cụ cần thiết."
    fi
}

# Kiểm tra kết nối cơ bản
check_basic_connection() {
    print_section "KIỂM TRA KẾT NỐI CƠ BẢN"
    
    # Kiểm tra ping tới Google DNS
    echo -e "${ARROW} ${BOLD}Đang kiểm tra ping tới 8.8.8.8...${RESET}"
    echo ""
    
    ping_output=$(ping -c 4 8.8.8.8 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "$ping_output" | grep -E "icmp_seq|rtt" | 
            sed -e "s/64 bytes from/  ${CHECK_MARK} Phản hồi từ/" \
                -e "s/time=/thời gian=/" \
                -e "s/icmp_seq=/gói #/" \
                -e "s/ttl=/ttl=/"
        
        # Kiểm tra độ trễ (latency) trung bình
        avg_latency=$(echo "$ping_output" | tail -1 | awk -F '/' '{print $5}')
        echo ""
        echo -e "${INFO} ${BOLD}Độ trễ trung bình:${RESET} ${YELLOW}${avg_latency} ms${RESET}"
        
        # Đánh giá độ trễ
        latency_float=$(echo "$avg_latency" | awk '{print int($1)}')
        if [ $latency_float -lt 50 ]; then
            echo -e "${INFO} Đánh giá: ${GREEN}Rất tốt${RESET} ${ROCKET}"
        elif [ $latency_float -lt 100 ]; then
            echo -e "${INFO} Đánh giá: ${CYAN}Tốt${RESET} ${CHECK_MARK}"
        elif [ $latency_float -lt 150 ]; then
            echo -e "${INFO} Đánh giá: ${YELLOW}Trung bình${RESET}"
        else
            echo -e "${INFO} Đánh giá: ${RED}Kém${RESET}"
        fi
    else
        echo -e "${CROSS_MARK} ${RED}Không thể ping đến 8.8.8.8${RESET}"
    fi
    
    # Kiểm tra DNS
    echo ""
    echo -e "${ARROW} ${BOLD}Đang kiểm tra phân giải DNS...${RESET}"
    dns_result=$(dig google.com +short 2>&1)
    if [ $? -eq 0 ] && [ ! -z "$dns_result" ]; then
        echo -e "${CHECK_MARK} Phân giải DNS thành công:"
        echo -e "  ${YELLOW}google.com${RESET} → ${CYAN}$dns_result${RESET}"
    else
        echo -e "${CROSS_MARK} ${RED}Không thể phân giải DNS${RESET}"
    fi
}

# Kiểm tra tốc độ sử dụng speedtest-cli
run_speedtest() {
    print_section "KIỂM TRA TỐC ĐỘ MẠNG CHI TIẾT"
    
    echo -e "${INFO} ${BOLD}Đang chạy speedtest-cli (có thể mất vài phút)...${RESET}"
    echo -e "${CLOCK} Đang kết nối tới máy chủ kiểm tra..."
    
    # Hiển thị thanh tiến trình
    progress_bar 3
    
    # Chạy speedtest với output đơn giản
    speedtest_output=$(speedtest-cli --simple 2>&1)
    if [ $? -eq 0 ]; then
        ping=$(echo "$speedtest_output" | grep "Ping:" | awk '{print $2}')
        download=$(echo "$speedtest_output" | grep "Download:" | awk '{print $2}')
        upload=$(echo "$speedtest_output" | grep "Upload:" | awk '{print $2}')
        
        echo ""
        echo -e "${GLOBE} ${BOLD}Kết quả kiểm tra tốc độ:${RESET}"
        echo -e "  ${YELLOW}┌───────────────────────────────────────┐${RESET}"
        echo -e "  ${YELLOW}│${RESET} ${BOLD}Ping:${RESET}      ${CYAN}$ping ms${RESET}                     ${YELLOW}│${RESET}"
        echo -e "  ${YELLOW}│${RESET} ${BOLD}Tải xuống:${RESET} ${GREEN}$download Mbit/s${RESET}                ${YELLOW}│${RESET}"
        echo -e "  ${YELLOW}│${RESET} ${BOLD}Tải lên:${RESET}   ${MAGENTA}$upload Mbit/s${RESET}                  ${YELLOW}│${RESET}"
        echo -e "  ${YELLOW}└───────────────────────────────────────┘${RESET}"
        
        # Đánh giá tốc độ
        download_float=$(echo "$download" | awk '{print int($1)}')
        echo ""
        echo -e "${INFO} ${BOLD}Đánh giá tốc độ tải xuống:${RESET}"
        if [ $download_float -gt 100 ]; then
            echo -e "  ${GREEN}Rất tốt${RESET} ${ROCKET} - Phù hợp cho streaming 4K, tải file lớn và gaming"
        elif [ $download_float -gt 50 ]; then
            echo -e "  ${CYAN}Tốt${RESET} ${CHECK_MARK} - Phù hợp cho streaming HD, hội nghị video và tải file"
        elif [ $download_float -gt 25 ]; then
            echo -e "  ${YELLOW}Trung bình${RESET} - Đủ cho streaming video HD và duyệt web cơ bản"
        elif [ $download_float -gt 10 ]; then
            echo -e "  ${RED}Thấp${RESET} - Phù hợp cho duyệt web cơ bản và email"
        else
            echo -e "  ${RED}Rất thấp${RESET} ${CROSS_MARK} - Có thể gặp khó khăn khi duyệt web"
        fi
    else
        echo -e "${CROSS_MARK} ${RED}Không thể chạy speedtest-cli${RESET}"
    fi
    
    echo ""
    echo -e "${INFO} ${BOLD}Đang chạy kiểm tra chi tiết hơn...${RESET}"
    speedtest-cli
}

# Kiểm tra tốc độ tải file từ các server khác nhau
test_download_speed() {
    print_section "KIỂM TRA TỐC ĐỘ TẢI FILE"
    
    # Danh sách URL để kiểm tra
    urls=(
        "http://speedtest.ftp.otenet.gr/files/test10Mb.db"
        "http://speedtest.tele2.net/10MB.zip"
        "http://ipv4.download.thinkbroadband.com/5MB.zip"
    )
    
    for url in "${urls[@]}"; do
        echo -e "${ARROW} ${BOLD}Đang kiểm tra tốc độ tải từ:${RESET} ${YELLOW}$url${RESET}"
        echo -e "${CLOCK} Đang tải..."
        
        # Hiển thị thanh tiến trình
        progress_bar 2
        
        result=$(curl -L -o /dev/null -w "%{speed_download} %{time_total}" "$url" 2>/dev/null)
        if [ $? -eq 0 ]; then
            speed=$(echo $result | awk '{print $1}')
            time=$(echo $result | awk '{print $2}')
            
            # Chuyển đổi tốc độ từ byte/s sang MB/s
            speed_mb=$(echo "scale=2; $speed/1024/1024" | bc)
            
            echo -e "${CHECK_MARK} ${BOLD}Kết quả:${RESET}"
            echo -e "  ${YELLOW}┌─────────────────────────────────────┐${RESET}"
            echo -e "  ${YELLOW}│${RESET} ${BOLD}Tốc độ tải:${RESET} ${GREEN}$speed_mb MB/s${RESET}             ${YELLOW}│${RESET}"
            echo -e "  ${YELLOW}│${RESET} ${BOLD}Thời gian:${RESET}  ${CYAN}$time giây${RESET}                 ${YELLOW}│${RESET}"
            echo -e "  ${YELLOW}└─────────────────────────────────────┘${RESET}"
        else
            echo -e "${CROSS_MARK} ${RED}Không thể tải từ server này${RESET}"
        fi
        echo ""
    done
}

# Hiển thị thông tin mạng
show_network_info() {
    print_section "THÔNG TIN MẠNG"
    
    echo -e "${ARROW} ${BOLD}Thông tin giao diện mạng:${RESET}"
    echo ""
    
    ip -brief addr show | while read line; do
        interface=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $2}')
        ip_addr=$(echo $line | awk '{print $3}')
        
        if [ "$status" == "UP" ]; then
            status_colored="${GREEN}UP${RESET}"
        else
            status_colored="${RED}DOWN${RESET}"
        fi
        
        echo -e "  ${CYAN}$interface${RESET}: $status_colored - ${YELLOW}$ip_addr${RESET}"
    done
    
    echo ""
    echo -e "${ARROW} ${BOLD}Thông tin bảng định tuyến:${RESET}"
    echo ""
    
    ip route | while read line; do
        echo -e "  ${MAGENTA}➜${RESET} $line"
    done
    
    echo ""
    echo -e "${ARROW} ${BOLD}Địa chỉ IP công cộng:${RESET}"
    public_ip=$(curl -s ifconfig.me)
    if [ ! -z "$public_ip" ]; then
        echo -e "  ${YELLOW}┌─────────────────────────────────────┐${RESET}"
        echo -e "  ${YELLOW}│${RESET} ${CYAN}$public_ip${RESET}                      ${YELLOW}│${RESET}"
        echo -e "  ${YELLOW}└─────────────────────────────────────┘${RESET}"
    else
        echo -e "${CROSS_MARK} ${RED}Không thể lấy địa chỉ IP công cộng${RESET}"
    fi
}

# Chạy tất cả các kiểm tra
run_all_tests() {
    print_header
    check_tools
    show_network_info
    check_basic_connection
    test_download_speed
    run_speedtest
    
    print_section "KẾT QUẢ KIỂM TRA HOÀN TẤT"
    echo -e "${INFO} ${BOLD}Thời gian kiểm tra:${RESET} ${YELLOW}$(date)${RESET}"
    echo ""
    echo -e "${GREEN}╔═════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║                                                             ║${RESET}"
    echo -e "${GREEN}║${WHITE}            CẢM ƠN BẠN ĐÃ SỬ DỤNG CÔNG CỤ KIỂM TRA            ${GREEN}║${RESET}"
    echo -e "${GREEN}║                                                             ║${RESET}"
    echo -e "${GREEN}╚═════════════════════════════════════════════════════════════╝${RESET}"
}

# Hàm hiển thị menu
show_menu() {
    print_header
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BLUE}│${RESET} ${BOLD}MENU KIỂM TRA TỐC ĐỘ MẠNG${RESET}                                    ${BLUE}│${RESET}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BLUE}│${RESET} ${CYAN}1.${RESET} Chạy tất cả các kiểm tra                                ${BLUE}│${RESET}"
    echo -e "${BLUE}│${RESET} ${CYAN}2.${RESET} Kiểm tra thông tin mạng                                 ${BLUE}│${RESET}"
    echo -e "${BLUE}│${RESET} ${CYAN}3.${RESET} Kiểm tra kết nối cơ bản                                 ${BLUE}│${RESET}"
    echo -e "${BLUE}│${RESET} ${CYAN}4.${RESET} Kiểm tra tốc độ tải file                                ${BLUE}│${RESET}"
    echo -e "${BLUE}│${RESET} ${CYAN}5.${RESET} Chạy speedtest-cli                                       ${BLUE}│${RESET}"
    echo -e "${BLUE}│${RESET} ${CYAN}0.${RESET} Thoát                                                   ${BLUE}│${RESET}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -ne "${ARROW} ${BOLD}Vui lòng chọn một tùy chọn (0-5):${RESET} "
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
        0) 
           clear
           echo -e "${GREEN}╔═════════════════════════════════════════════════════════════╗${RESET}"
           echo -e "${GREEN}║                                                             ║${RESET}"
           echo -e "${GREEN}║${WHITE}                          TẠM BIỆT!                           ${GREEN}║${RESET}"
           echo -e "${GREEN}║                                                             ║${RESET}"
           echo -e "${GREEN}╚═════════════════════════════════════════════════════════════╝${RESET}"
           exit 0 
           ;;
        *) 
           echo -e "${RED}Lựa chọn không hợp lệ. Vui lòng thử lại.${RESET}" 
           ;;
    esac
    
    echo ""
    echo -ne "${ARROW} ${BOLD}Nhấn Enter để tiếp tục...${RESET} "
    read
}

# Chạy chương trình
while true; do
    show_menu
    handle_menu
done
