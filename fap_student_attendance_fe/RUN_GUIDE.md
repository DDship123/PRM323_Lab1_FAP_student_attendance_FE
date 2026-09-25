# 🚀 Hướng Dẫn Chạy Dự Án: Website & Desktop (Windows) — Full Chức Năng

> **Dự án**: Attendly — FAP Student Attendance System (Frontend Flutter)  
> **Cập nhật lần cuối**: 2026-09-24  
> **Mục tiêu**: Cung cấp đầy đủ lệnh terminal và các bước thao tác để thực hiện **FULL chức năng** của dự án (Đăng nhập, Quản lý lớp, Import Excel, Tạo QR, Quét điểm danh realtime, Thống kê cá nhân) trên cả **Website** và **Desktop Windows**.

---

## 📌 Mục Lục
1. [Bảng tóm tắt lệnh Terminal chạy nhanh](#1-bảng-tóm-tắt-lệnh-terminal-chạy-nhanh)
2. [Yêu cầu môi trường & Cài đặt ban đầu](#2-yêu-cầu-môi-trường--cài-đặt-ban-đầu)
3. [KỊCH BẢN 1: Chạy Full Chức Năng Dạng WEBSITE](#3-kịch-bản-1-chạy-full-chức-năng-dạng-website)
4. [KỊCH BẢN 2: Chạy Full Chức Năng Dạng WINDOWS DESKTOP](#4-kịch-bản-2-chạy-full-chức-năng-dạng-windows-desktop)
5. [Quy trình kiểm thử Full Chức Năng từ A - Z (Checklist)](#5-quy-trình-kiểm-thử-full-chức-năng-từ-a---z-checklist)
6. [Tài khoản thử nghiệm mẫu (Credentials)](#6-tài-khoản-thử-nghiệm-mẫu-credentials)
7. [Xử lý sự cố thường gặp (Troubleshooting)](#7-xử-lý-sự-cố-thường-gặp-troubleshooting)

---

## 1. Bảng tóm tắt lệnh Terminal chạy nhanh

| Nền tảng | Terminal 1 (Backend) | Terminal 2 (Web Server / Mobile) | Terminal 3 (App Client) |
|---|---|---|---|
| **Chạy Website (Khuyên dùng)** | Chạy Backend Spring Boot (`port 8080`) | `npx serve -s build/web -p 5000` | Mở trình duyệt: `http://localhost:5000` |
| **Chạy Website (Debug Code)** | Chạy Backend Spring Boot (`port 8080`) | `flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0` | Mở Chrome: `http://localhost:5000` |
| **Chạy Desktop (Windows)** | Chạy Backend Spring Boot (`port 8080`) | `npx serve -s build/web -p 5000` *(để điện thoại quét QR)* | `flutter run -d windows` |

---

## 2. Yêu cầu môi trường & Cài đặt ban đầu

### 2.1. Yêu cầu môi trường (Prerequisites)
- **Flutter SDK**: `≥ 3.13.3` (Kiểm tra bằng: `flutter --version`)
- **Node.js & npm**: `≥ 18.x` (Dùng để chạy `npx serve`)
- **Visual Studio 2022**: Cần có workload *"Desktop development with C++"* (chỉ cần khi chạy Windows Desktop)
- **Trình duyệt Web**: Google Chrome hoặc Microsoft Edge
- **Backend Spring Boot**: Đang chạy tại `http://localhost:8080`
- **Mạng kết nối**: Máy tính và điện thoại kết nối **cùng một mạng Wi-Fi** (hoặc máy tính phát Mobile Hotspot cho điện thoại).

### 2.2. Cài đặt thư viện Flutter (chỉ cần chạy lần đầu)
Mở PowerShell tại thư mục dự án `fap_student_attendance_fe`:
```powershell
flutter pub get
```

Kiểm tra các thiết bị sẵn sàng:
```powershell
flutter devices
```
*(Kết quả sẽ có `Windows (desktop)`, `Chrome (web)`, `Edge (web)`)*

---

## 3. KỊCH BẢN 1: Chạy Full Chức Năng Dạng WEBSITE

Kịch bản này triển khai hệ thống hoàn toàn trên nền tảng Web. Giảng viên mở trình duyệt trên máy tính để quản lý lớp học và mở phiên điểm danh chiếu QR; sinh viên có thể dùng điện thoại hoặc tab trình duyệt khác để quét mã điểm danh.

### 💻 Các lệnh Terminal cần chạy:

#### 🔹 Bước 1: Khởi động Backend Spring Boot
Mở Terminal riêng của dự án Backend:
```powershell
./mvnw spring-boot:run
# Đảm bảo backend đã khởi động thành công và lắng nghe tại cổng 8080
```

#### 🔹 Bước 2: Build Web và khởi chạy Web Server
Tại thư mục gốc của frontend `fap_student_attendance_fe`:

```powershell
# 1. Biên dịch web bundle hoàn chỉnh (nếu có thay đổi code)
flutter build web

# 2. Khởi chạy máy chủ web tĩnh phục vụ toàn mạng LAN trên cổng 5000:
npx serve -s build/web -p 5000
```

> 💡 **Lưu ý**: Lệnh `npx serve -s build/web -p 5000` sẽ mở web server lắng nghe cả `localhost:5000` và địa chỉ IP mạng nội bộ của bạn (ví dụ: `http://192.168.1.101:5000`).

---

### 📝 Các bước thao tác Full chức năng trên Web:

1. **Giảng viên đăng nhập & quản lý:**
   - Mở trình duyệt máy tính, truy cập: **`http://localhost:5000`**
   - Đăng nhập với tài khoản Giảng viên (`LECTURER`).
   - Vào mục **Lớp học** ➔ Chọn môn học phụ trách ➔ Bấm **Import Excel** để nhập danh sách sinh viên.
   - Hệ thống hiển thị bảng danh sách sinh viên cùng thông báo nổi bật: **Tài khoản mới được tạo tự động với Tên đăng nhập là MSSV và Mật khẩu mặc định là `A123456`**.

2. **Giảng viên mở phiên điểm danh Live:**
   - Chọn buổi học hôm nay ➔ Nhấn **Bắt đầu điểm danh**.
   - Màn hình sẽ hiển thị:
     - **Mã PIN** lớn 6 chữ số.
     - **Mã QR Code động** chứa URL điểm danh theo IP LAN: `http://192.168.1.101:5000/#/student/check-in?...`
     - Bảng danh sách sinh viên theo dõi trạng thái điểm danh thời gian thực (Real-time).

3. **Sinh viên quét mã điểm danh:**
   - **Cách 1 (Bằng điện thoại thật)**: Dùng Camera hoặc Zalo quét mã QR trên màn hình máy tính của Giảng viên. Điện thoại sẽ mở trang Web check-in tự động điền mã PIN ➔ Sinh viên đăng nhập/nhấn **"ĐIỂM DANH NGAY"**.
   - **Cách 2 (Mô phỏng trên máy tính)**: Mở tab trình duyệt ẩn danh (Incognito) hoặc trình duyệt khác, truy cập link điểm danh được tạo hoặc đường dẫn `http://localhost:5000/#/student/check-in`.

4. **Xác nhận kết quả:**
   - Màn hình Giảng viên tự động đổi màu và cập nhật trạng thái của sinh viên thành **"Có mặt" (Present)** kèm mốc thời gian chính xác.
   - Giảng viên có thể điểm danh bù thủ công cho sinh viên nếu có lý do chính đáng.
   - Bấm **"Kết thúc phiên điểm danh"** để chốt kết quả và đồng bộ lên cơ sở dữ liệu.

---

## 4. KỊCH BẢN 2: Chạy Full Chức Năng Dạng WINDOWS DESKTOP

Kịch bản này Giảng viên sử dụng **Phần mềm ứng dụng Desktop Windows độc lập** (`.exe`). Màn hình Desktop sẽ trực tiếp tạo mã QR trỏ đến Web Server LAN để điện thoại của sinh viên quét điểm danh.

### 💻 Các lệnh Terminal cần chạy:

Cần mở **3 Terminal** song song:

#### 🔹 Terminal 1: Backend Spring Boot
```powershell
./mvnw spring-boot:run
```

#### 🔹 Terminal 2: Web Server cho điện thoại sinh viên truy cập
Mở tại thư mục frontend:
```powershell
npx serve -s build/web -p 5000
```
*(Nếu chưa build web gần đây, hãy chạy `flutter build web` trước 1 lần)*.

#### 🔹 Terminal 3: Khởi chạy Ứng dụng Desktop Windows
Mở tại thư mục frontend:
```powershell
flutter run -d windows
```

> 💡 **Tạo bản chạy độc lập (.exe) không cần Terminal:**  
> Nếu bạn muốn đóng gói thành file `.exe` để click chạy trực tiếp:
> ```powershell
> flutter build windows
> ```
> File thực thi nằm tại: `build\windows\x64\runner\Release\fap_student_attendance_fe.exe`.

---

### 📝 Các bước thao tác Full chức năng trên Desktop:

1. **Khởi động ứng dụng Windows:**
   - Cửa sổ phần mềm **Attendly** xuất hiện trên Windows.
   - Giảng viên thực hiện đăng nhập vào tài khoản.

2. **Kiểm tra thông số mạng:**
   - Ứng dụng Desktop đã tích hợp bộ dò tìm IP mạng tự động (`NetworkInfo.getLocalHost`).
   - Địa chỉ IP LAN (ví dụ: `192.168.1.101`) và cổng `5000` sẽ tự động gắn vào liên kết của mã QR.
   - *Nếu bạn chạy web server ở cổng khác (ví dụ 3000), bạn chỉ cần click vào biểu tượng **cây bút (✏️)** ngay cạnh dòng `Web phục vụ: ...` để đổi sang `192.168.1.101:3000` mà không cần sửa code.*

3. **Mở phiên điểm danh & Chiếu QR:**
   - Vào lịch dạy ➔ Chọn lớp ➔ Nhấn **"Mở phiên điểm danh"**.
   - Màn hình Desktop Windows phóng to mã QR và mã PIN.

4. **Sinh viên quét QR bằng Smartphone:**
   - Sinh viên kết nối cùng mạng Wi-Fi với máy tính Giảng viên.
   - Mở Camera hoặc ứng dụng quét mã QR quét mã trên màn hình Desktop.
   - Điện thoại lập tức tải giao diện điểm danh ➔ Sinh viên nhấn xác nhận có mặt.

5. **Theo dõi Realtime & Kết thúc:**
   - Cửa sổ Desktop của Giảng viên lập tức cập nhật sinh viên vừa quét thành trạng thái "Đã có mặt".
   - Giảng viên nhấn **"Đóng phiên"** khi hết giờ.

---

## 5. Quy trình kiểm thử Full Chức Năng từ A - Z (Checklist)

Để tự tin trình bày hoặc nghiệm thu bài tập, hãy thực hiện theo đúng thứ tự 6 bước sau:

- [ ] **Bước 1: Quản trị & Nhập liệu (Lecturer / Admin)**
  - Đăng nhập tài khoản Giảng viên.
  - Xem màn hình Tổng quan (Dashboard): Kiểm tra số lớp học phần phụ trách, tổng sinh viên đã đăng ký, học kỳ hoạt động.
  - Vào chi tiết lớp ➔ Tải file Excel mẫu ➔ Thực hiện **Import sinh viên**.
  - Kiểm tra thẻ thông báo: Xác nhận thấy **Mật khẩu mặc định: `A123456`**.

- [ ] **Bước 2: Cập nhật thông tin cá nhân (User Profile)**
  - Bấm vào Avatar góc phải ➔ Chọn **Thông tin cá nhân**.
  - Chỉnh sửa **Tên đăng nhập (Username)**, **Họ tên**, **Số điện thoại** ➔ Nhấn Lưu.
  - Đăng xuất và đăng nhập lại bằng Username mới để kiểm tra tính toàn vẹn.

- [ ] **Bước 3: Mở phiên điểm danh Live (Live Attendance Session)**
  - Chọn buổi học cần điểm danh ➔ Bấm **Bắt đầu điểm danh**.
  - Kiểm tra: Mã QR Code được render sắc nét, mã PIN 6 số hiển thị rõ ràng, địa chỉ `Web phục vụ: 192.168.1.101:5000` có nút chỉnh sửa ✏️.

- [ ] **Bước 4: Sinh viên điểm danh (Student Check-in)**
  - Dùng điện thoại (hoặc tab trình duyệt mới) quét QR.
  - Đăng nhập bằng tài khoản Sinh viên (Username: MSSV, Password: `A123456`).
  - Hệ thống tự điền mã PIN ➔ Bấm **"ĐIỂM DANH NGAY"**.
  - Màn hình điện thoại báo "Điểm danh thành công!".

- [ ] **Bước 5: Đồng bộ Realtime trên màn hình Giảng viên**
  - Màn hình Giảng viên ngay lập tức chuyển trạng thái của sinh viên đó sang màu xanh **"Có mặt"**.
  - Thử nghiệm tính năng **Điểm danh bù thủ công**: Click vào sinh viên vắng ➔ Chọn đổi thành "Có mặt" hoặc "Đi trễ".

- [ ] **Bước 6: Tổng kết & Tra cứu lịch sử (Attendance History)**
  - Giảng viên bấm **Kết thúc phiên điểm danh**.
  - Đăng nhập tài khoản Sinh viên ➔ Vào mục **Lịch sử điểm danh** ➔ Xác nhận buổi học vừa rồi đã được ghi nhận trạng thái Có mặt chính xác 100%.

---

## 6. Tài khoản thử nghiệm mẫu (Credentials)

| Vai trò (Role) | Tên đăng nhập (Username) | Mật khẩu (Password) | Quyền hạn chính |
|---|---|---|---|
| **Giảng viên** | `lecturer1` *(hoặc email GV)* | `123456` *(hoặc pass đã tạo)* | Quản lý môn học, import Excel, tạo QR điểm danh, xem thống kê |
| **Sinh viên (Tạo qua Excel)** | `HE170001` *(MSSV)* | `A123456` *(Mặc định)* | Quét mã QR, nhập PIN, xem lịch sử điểm danh cá nhân |
| **Quản trị viên** | `admin` | `admin123` | Quản trị hệ thống toàn quyền |

---

## 7. Xử lý sự cố thường gặp (Troubleshooting)

### ⚠️ Lỗi 1: Cổng 5000 hoặc 8080 bị chiếm (Port already in use)
- **Triệu chứng**: Chạy `npx serve` báo lỗi cổng đã được sử dụng.
- **Khắc phục**:
  1. Mở PowerShell kiểm tra tiến trình đang chiếm cổng:
     ```powershell
     Get-Process -Id (Get-NetTCPConnection -LocalPort 5000).OwningProcess
     ```
  2. Tắt tiến trình đó hoặc chạy sang cổng khác (ví dụ 3000):
     ```powershell
     npx serve -s build/web -p 3000
     ```
  3. Trên giao diện điểm danh, bấm nút **✏️** sửa `5000` thành `3000`.

### ⚠️ Lỗi 2: Điện thoại báo "Không thể kết nối máy chủ" khi quét QR
- **Khắc phục**:
  1. Kiểm tra máy tính và điện thoại đã kết nối **cùng 1 mạng Wi-Fi** chưa (điện thoại không được bật 4G/5G).
  2. Mở cổng Tường lửa Windows (Windows Defender Firewall):
     - Mở *Windows Defender Firewall with Advanced Security* ➔ *Inbound Rules* ➔ Cho phép cổng `5000` và `8080`.
  3. Nếu Wi-Fi trường học có chính sách chặn kết nối giữa các thiết bị nội bộ (AP Isolation), hãy dùng điện thoại hoặc laptop phát **Mobile Hotspot** cho nhau.

### ⚠️ Lỗi 3: Chạy `flutter run -d windows` bị lỗi Visual Studio C++
- **Khắc phục**: Mở **Visual Studio Installer** ➔ Chọn phiên bản VS 2022 ➔ Bấm **Modify** ➔ Tích chọn mục **"Desktop development with C++"** ➔ Bấm **Install/Modify** và khởi động lại máy.

---
🎯 **Chúc bạn thực hiện chạy và thuyết trình dự án thành công xuất sắc!**
