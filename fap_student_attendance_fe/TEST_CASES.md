# 📋 BẢNG ĐẶC TẢ TEST CASE HỆ THỐNG ĐIỂM DANH SINH VIÊN — ATTENDLY (FAP ATTENDANCE)

> **Dành cho Đội ngũ QA / Tester & Phát triển**  
> **Dự án**: FAP Student Attendance System (Attendly Frontend & Backend Integration)  
> **Nền tảng kiểm thử**: Web (Chrome/Edge), Mobile Browser (Android/iOS Safari), Windows App  
> **Phiên bản tài liệu**: 2.0  
> **Cập nhật ngày**: 2026-09-25  

---

## 📑 MỤC LỤC

1. [Quy ước & Phân loại Test Case](#1-quy-ước--phân-loại-test-case)
2. [Môi trường & Dữ liệu Chuẩn bị (Test Setup)](#2-môi-trường--dữ-liệu-chuẩn-bị-test-setup)
3. [Module 1: Xác thực & Tài khoản (Authentication & Profile)](#3-module-1-xác-thực--tài-khoản-auth)
4. [Module 2: Quản lý Khóa học & Sinh viên (Courses - Giảng viên)](#4-module-2-quản-lý-khóa-học-courses---giảng-viên)
5. [Module 3: Tìm kiếm & Đăng ký Môn học (Course Enrollment - Sinh viên)](#5-module-3-tìm-kiếm--đăng-ký-môn-học-sinh-viên)
6. [Module 4: Tạo & Quản lý Phiên Điểm danh (Sessions & Dynamic QR - Giảng viên)](#6-module-4-tạo--quản-lý-phiên-điểm-danh-sessions---giảng-viên)
7. [Module 5: Điểm danh QR & Mã PIN (Check-In - Sinh viên)](#7-module-5-điểm-danh-qr--mã-pin-check-in---sinh-viên)
8. [Module 6: Bảo mật, Chống Gian lận & Xử lý Mã Lỗi (Anti-Fraud & Security)](#8-module-6-bảo-mật-chống-gian-lận--xử-lý-mã-lỗi-security)
9. [Module 7: Nhật ký & Thống kê Chuyên cần (Attendance History - Sinh viên)](#9-module-7-nhật-ký--thống-kê-chuyên-cần-history---sinh-viên)
10. [Module 8: Giao diện Đa nền tảng & Mobile Responsive (Cross-Platform UI)](#10-module-8-giao-diện-đa-nền-tảng--mobile-responsive)
11. [Ma trận Truy xuất & Nghiệm thu (Test Execution Checklist)](#11-ma-trận-truy-xuất--nghiệm-thu)

---

## 1. Quy ước & Phân loại Test Case

### 1.1. Cấu trúc mã Test Case
- Format: `TC_[MODULE]_[STT]`
  - `AUTH`: Xác thực, Đăng nhập, Đăng ký, Quản lý tài khoản
  - `CRS`: Quản lý môn học (Giảng viên)
  - `ENRL`: Tìm kiếm & Đăng ký môn (Sinh viên)
  - `SES`: Phiên điểm danh, Tạo ca, Trình chiếu QR động TOTP
  - `CHK`: Điểm danh sinh viên (Quét QR, Nhập PIN)
  - `SEC`: Kiểm thử bảo mật (Wi-Fi IP, Thiết bị gian lận, Hết hạn)
  - `HIST`: Nhật ký & Thống kê chuyên cần
  - `RESP`: Giao diện Responsive Mobile & Desktop

### 1.2. Mức độ ưu tiên (Priority)
- **P1 (Critical / Blocker)**: Tính năng sống còn (Đăng nhập, Tạo phiên, Quét QR điểm danh, Bảo mật Wi-Fi / Chống gian lận).
- **P2 (Major)**: Tính năng quan trọng (Đăng ký môn, Nhập PIN dự phòng, Cập nhật thông tin, Thống kê lịch sử).
- **P3 (Minor)**: Trải nghiệm phụ, Bộ lọc tìm kiếm, Giao diện chuyển đổi theme, Thông báo trạng thái.

---

## 2. Môi trường & Dữ liệu Chuẩn bị (Test Setup)

### 2.1. Cấu hình môi trường
- **Backend API**: `http://localhost:8080` (hoặc IP LAN máy chủ `http://192.168.x.x:8080`)
- **Frontend Web**: `http://localhost:5000` (hoặc cổng chạy `flutter run`)
- **Thiết bị kiểm thử**:
  - Máy tính Giảng viên (Desktop / Laptop): Web Browser (Google Chrome, Edge) độ phân giải ≥ 1280x720.
  - Thiết bị Sinh viên (Smartphone): Trình duyệt di động (Chrome Android / Safari iOS) hoặc App Flutter Mobile.
  - 2 Thiết bị di động khác nhau cùng kết nối vào 1 mạng Wi-Fi phòng học.

### 2.2. Tài khoản thử nghiệm mẫu (Seed Data)
| Role | Email | Mật khẩu | Mã người dùng | Ghi chú |
|---|---|---|---|---|
| `LECTURER` | `teacher@fpt.edu.vn` | `123456` | `GV001` | Tài khoản Giảng viên giảng dạy |
| `STUDENT` | `student1@fpt.edu.vn` | `123456` | `SE192947` | Sinh viên kiểm thử chính (Thiết bị A) |
| `STUDENT` | `student2@fpt.edu.vn` | `123456` | `SE190002` | Sinh viên kiểm thử phụ (Thiết bị B) |

---

## 3. Module 1: Xác thực & Tài khoản (AUTH)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_AUTH_001** | Đăng nhập thành công với vai trò Giảng viên | Tài khoản `teacher@fpt.edu.vn` đã tồn tại | 1. Mở trang `/auth`<br>2. Chọn tab "Đăng nhập"<br>3. Nhập Email & Mật khẩu<br>4. Nhấn "ĐĂNG NHẬP" | Email: `teacher@fpt.edu.vn`<br>Pass: `123456` | - Chuyển hướng đến `/lecturer/courses`<br>- Lưu JWT Token vào local storage<br>- Sidebar hiển thị đầy đủ menu Giảng viên | Positive | P1 |
| **TC_AUTH_002** | Đăng nhập thành công với vai trò Sinh viên | Tài khoản `student1@fpt.edu.vn` đã tồn tại | 1. Mở trang `/auth`<br>2. Nhập Email & Mật khẩu<br>3. Nhấn "ĐĂNG NHẬP" | Email: `student1@fpt.edu.vn`<br>Pass: `123456` | - Chuyển hướng đến `/student/dashboard`<br>- Trên Mobile hiển thị BottomNavigationBar 4 Tab<br>- Hiển thị đúng tên sinh viên | Positive | P1 |
| **TC_AUTH_003** | Đăng nhập thất bại do sai mật khẩu | Tài khoản đã tồn tại | 1. Mở trang `/auth`<br>2. Nhập email đúng, mật khẩu sai<br>3. Nhấn "ĐĂNG NHẬP" | Email: `student1@fpt.edu.vn`<br>Pass: `wrongpass` | - Hiển thị thông báo lỗi màu đỏ rõ ràng (SnackBar / Alert)<br>- Giữ nguyên form, không chuyển trang | Negative | P1 |
| **TC_AUTH_004** | Đăng nhập thất bại do để trống trường bắt buộc | Mở trang `/auth` | 1. Để trống Email hoặc Mật khẩu<br>2. Nhấn "ĐĂNG NHẬP" | Email: ` ` hoặc Pass: ` ` | - Hiển thị validation báo lỗi dưới ô nhập liệu: "Vui lòng nhập email / mật khẩu"<br>- Không gửi request lên server | Validation | P2 |
| **TC_AUTH_005** | Đăng ký tài khoản Sinh viên mới thành công | Email chưa từng đăng ký | 1. Mở `/auth`<br>2. Chọn tab "Tạo tài khoản mới"<br>3. Nhập Họ tên, Mã SV, Email, Mật khẩu<br>4. Chọn vai trò "Sinh viên"<br>5. Nhấn "ĐĂNG KÝ TÀI KHOẢN" | Họ tên: Nguyễn Văn A<br>MSSV: SE199999<br>Email: `nguyenvana@fpt.edu.vn`<br>Pass: `123456`<br>Role: `STUDENT` | - Đăng ký thành công, thông báo chúc mừng<br>- Tự động đăng nhập hoặc chuyển sang tab Đăng nhập để sử dụng ngay | Positive | P1 |
| **TC_AUTH_006** | Đăng ký thất bại do Email không đúng định dạng | Mở form Đăng ký | 1. Nhập email sai định dạng (thiếu @, thiếu domain)<br>2. Nhấn "ĐĂNG KÝ" | Email: `invalid-email-test` | - Báo lỗi form: "Email không đúng định dạng"<br>- Nút bấm không kích hoạt gửi API | Validation | P2 |
| **TC_AUTH_007** | Đăng ký thất bại do Mật khẩu quá ngắn (< 6 ký tự) | Mở form Đăng ký | 1. Nhập đầy đủ thông tin, mật khẩu đặt 3 ký tự<br>2. Nhấn Đăng ký | Pass: `123` | - Báo lỗi: "Mật khẩu phải có ít nhất 6 ký tự" | Boundary | P2 |
| **TC_AUTH_008** | Kiểm tra nút bật/tắt hiển thị mật khẩu | Form Đăng nhập hoặc Đăng ký | 1. Nhập mật khẩu<br>2. Nhấn icon mắt ẩn/hiện<br>3. Quan sát text | Text: `123456` | - Khi bật: hiển thị rõ text `123456`<br>- Khi tắt: hiển thị dạng dấu chấm đen `••••••` | UI | P3 |
| **TC_AUTH_009** | Tự động khôi phục phiên đăng nhập (Auto-login) | Đã đăng nhập trước đó | 1. Tắt trình duyệt hoặc Refresh lại trang F5<br>2. Truy cập lại URL gốc `/` | LocalStorage còn token hợp lệ | - Ứng dụng tự động kiểm tra token hợp lệ và đưa vào Dashboard theo Role, không bắt đăng nhập lại | Functional | P1 |
| **TC_AUTH_010** | Đăng xuất tài khoản (Logout) | Đang đăng nhập | 1. Nhấn nút "Đăng xuất" ở Menu / Sidebar / Drawer<br>2. Xác nhận | — | - Xóa sạch Token và User profile trong bộ nhớ<br>- Chuyển hướng dứt khoát về trang `/auth` | Positive | P1 |

---

## 4. Module 2: Quản lý Khóa học (COURSES - Giảng viên)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_CRS_001** | Xem danh sách môn học của Giảng viên | Đã đăng nhập vai trò `LECTURER` | 1. Vào menu "Môn học phụ trách" (`/lecturer/courses`) | — | - Hiển thị danh sách các khóa học đã tạo<br>- Mỗi khóa học có Mã môn, Tên môn, Học kỳ, Phòng học, Số SV | Positive | P1 |
| **TC_CRS_002** | Tạo môn học mới thành công | Đang ở trang Môn học | 1. Nhấn "Thêm môn học mới"<br>2. Điền Mã môn, Tên môn, Kỳ học, Phòng học, Số tín chỉ<br>3. Nhấn "LƯU MÔN HỌC" | Mã: `PRM323`<br>Tên: `Lập trình Di động`<br>Kỳ: `Fall2026`<br>Phòng: `BE-302` | - Hiển thị SnackBar thành công<br>- Khóa học mới xuất hiện ngay trên danh sách môn học | Positive | P1 |
| **TC_CRS_003** | Tạo môn học thất bại do trùng mã môn trong kỳ | Đã có môn `PRM323` kỳ `Fall2026` | 1. Nhấn Thêm môn học<br>2. Nhập trùng mã `PRM323`<br>3. Nhấn Lưu | Mã: `PRM323` | - Backend trả về lỗi Conflict (409)<br>- Frontend hiển thị cảnh báo "Môn học đã tồn tại trong kỳ này" | Negative | P2 |
| **TC_CRS_004** | Cập nhật thông tin môn học | Khóa học đã tồn tại | 1. Nhấn nút "Chỉnh sửa" tại môn `PRM323`<br>2. Đổi phòng học thành `AL-405`<br>3. Nhấn "LƯU THAY ĐỔI" | Phòng: `AL-405` | - Cập nhật thành công, dữ liệu mới được hiển thị ngay trên giao diện | Positive | P2 |
| **TC_CRS_005** | Xem danh sách sinh viên trong lớp học phần | Môn học đã có SV đăng ký | 1. Nhấn vào môn học hoặc icon "Danh sách SV"<br>2. Quan sát bảng sinh viên | — | - Hiển thị đầy đủ Họ tên, MSSV, Email của các sinh viên đã ghi danh vào môn | Positive | P2 |
| **TC_CRS_006** | Import danh sách sinh viên từ file Excel | Có file `.xlsx` danh sách SV đúng định dạng | 1. Nhấn "Import sinh viên Excel"<br>2. Chọn file Excel từ máy tính<br>3. Nhấn Tải lên | File: `danh_sach_lop.xlsx` | - Hệ thống phân tích file, import thành công các sinh viên vào lớp<br>- Báo số lượng sinh viên đã import thành công | Functional | P2 |

---

## 5. Module 3: Tìm kiếm & Đăng ký Môn học (ENRL - Sinh viên)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_ENRL_001** | Tìm kiếm môn học theo từ khóa | Đã đăng nhập vai trò `STUDENT` | 1. Vào trang "Tìm môn" (`/student/courses`)<br>2. Nhập từ khóa vào ô tìm kiếm | Từ khóa: `PRM` hoặc `Di động` | - Danh sách tự động lọc hiển thị các môn học khớp với mã hoặc tên môn | Positive | P2 |
| **TC_ENRL_002** | Lọc môn học theo Học kỳ | Đang ở trang `/student/courses` | 1. Mở Dropdown "Học kỳ"<br>2. Chọn kỳ `Fall2026` | Học kỳ: `Fall2026` | - Chỉ hiển thị các môn học được mở trong kỳ `Fall2026` | Positive | P2 |
| **TC_ENRL_003** | Đăng ký môn học thành công | Môn học chưa đủ số lượng, SV chưa đăng ký | 1. Tìm môn học mong muốn<br>2. Nhấn nút "Đăng ký môn"<br>3. Xác nhận trên hộp thoại Modal | Môn: `PRM323` | - Trạng thái môn chuyển thành "Đã đăng ký" (chip màu xanh)<br>- Môn học lập tức xuất hiện tại Cổng sinh viên (`/student/dashboard`) | Positive | P1 |
| **TC_ENRL_004** | Hủy đăng ký môn học | Sinh viên đã đăng ký môn trước đó | 1. Nhấn nút "Hủy đăng ký"<br>2. Xác nhận trong hộp thoại | Môn: `PRM323` | - Hủy thành công, nút chuyển lại thành "Đăng ký môn"<br>- Môn học bị xóa khỏi Dashboard cá nhân | Positive | P2 |
| **TC_ENRL_005** | Hiển thị hộp thoại Dialog chuẩn trên Mobile | Xem trên màn hình Mobile (< 800px) | 1. Nhấn nút Đăng ký môn trên điện thoại<br>2. Quan sát hộp thoại xác nhận | Màn hình điện thoại | - Dialog co giãn vừa vặn (maxWidth 420), không tràn màn hình, nút bấm to rõ | Responsive | P2 |

---

## 6. Module 4: Tạo & Quản lý Phiên Điểm danh (SES - Giảng viên)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_SES_001** | Tạo phiên điểm danh với chu kỳ QR mặc định 20 giây | Đăng nhập Giảng viên, đã có môn học | 1. Vào trang Tạo phiên (`/sessions/create`)<br>2. Chọn môn học, ca học (Slot 1)<br>3. Kiểm tra ô "Chu kỳ đổi mã QR"<br>4. Nhấn "TẠO PHIÊN ĐIỂM DANH" | Chu kỳ QR: `20 giây` (mặc định) | - Phiên được tạo thành công với `qrRefreshSeconds: 20`<br>- Tự động chuyển đến màn hình Trình chiếu QR (`/sessions/:id/live`) | Positive | P1 |
| **TC_SES_002** | Tùy chỉnh chu kỳ đổi mã QR (10s, 30s, 60s) | Đang ở form Tạo phiên | 1. Mở Dropdown "Chu kỳ đổi mã QR"<br>2. Chọn mức khác (ví dụ: 10s hoặc 30s)<br>3. Nhấn Tạo phiên | Chu kỳ: `10 giây` hoặc `30 giây` | - Phiên được khởi tạo với chu kỳ đã chọn<br>- Trên màn hình live đếm ngược đúng chu kỳ đó | Functional | P2 |
| **TC_SES_003** | Tự động nhận diện IP Wi-Fi giảng viên (Adaptive Wi-Fi) | Máy tính GV đang kết nối Wi-Fi phòng học | 1. Mở form Tạo phiên<br>2. Quan sát ô "IP Giảng viên / Subnet" | Kết nối Wi-Fi thực tế (VD: `192.168.1.116`) | - Ô IP tự động điền IP của giảng viên<br>- Có tùy chọn bật/tắt ràng buộc IP Wi-Fi | Security | P1 |
| **TC_SES_004** | Trình chiếu Mã QR động TOTP & Thanh đếm ngược | Phiên điểm danh đang mở | 1. Quan sát màn hình Live QR (`/sessions/:id/live`)<br>2. Đợi hết chu kỳ đếm ngược (20 giây) | Chu kỳ: 20s | - Thanh đếm ngược chạy từ 20s về 0s mượt mà<br>- Khi hết 20s, mã QR tự động thay đổi sang mã mới (TOTP Token mới)<br>- Không bị giật hoặc đơ màn hình | Functional | P1 |
| **TC_SES_005** | Hiển thị mã PIN dự phòng cho sinh viên | Đang trình chiếu phiên | 1. Quan sát góc màn hình live QR | — | - Hiển thị mã PIN 6 số to rõ ràng (ví dụ: `839201`)<br>- Mã PIN giữ nguyên hoặc có thời hạn theo cấu hình phiên | Functional | P2 |
| **TC_SES_006** | Cập nhật thời gian thực danh sách SV đã điểm danh | Phiên đang mở, SV thực hiện điểm danh | 1. Giảng viên mở màn hình Live QR<br>2. Sinh viên quét mã điểm danh thành công<br>3. Quan sát danh sách trên máy GV | SV: `SE192947` | - Bảng kết quả điểm danh trên máy GV tự động nhảy tên SV mà không cần F5 tải lại trang (thông qua Polling / SSE)<br>- Đếm số lượng SV có mặt tăng lên (+1) | Real-time | P1 |
| **TC_SES_007** | Đóng / Kết thúc phiên điểm danh thủ công | Phiên đang hoạt động | 1. Giảng viên nhấn nút "Kết thúc phiên"<br>2. Xác nhận kết thúc | — | - Trạng thái phiên chuyển thành `CLOSED`<br>- Mã QR bị ẩn hoặc làm mờ<br>- Sinh viên quét sau thời điểm này sẽ bị từ chối | Positive | P1 |

---

## 7. Module 5: Điểm danh QR & Mã PIN (CHK - Sinh viên)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_CHK_001** | Điểm danh thành công qua quét mã QR động | SV đã kết nối Wi-Fi phòng học, đã đăng ký môn | 1. Mở camera điện thoại quét mã QR trên màn chiếu<br>2. Nhấn vào liên kết deep-link mở ra<br>3. Kiểm tra thông tin phiên trên màn hình Check-in<br>4. Nhấn nút "ĐIỂM DANH NGAY" | Deep-link chứa `sessionId` và `qrCodeSecret` hợp lệ | - Chuyển sang màn hình Kết quả thành công (`/attendance/result`)<br>- Hiển thị Icon tích xanh, ghi nhận "Có mặt"<br>- Lưu lịch sử điểm danh | Positive | P1 |
| **TC_CHK_002** | Điểm danh thành công bằng mã PIN 6 số dự phòng | Camera SV bị hỏng / không quét được QR | 1. Vào Tab "Quét QR" (`/student/scan`)<br>2. Chuyển sang Tab "Nhập mã PIN"<br>3. Nhập mã PIN 6 chữ số hiển thị trên màn chiếu<br>4. Nhấn "XÁC NHẬN ĐIỂM DANH" | Mã PIN: `839201` | - Gửi request điểm danh theo phương thức `MANUAL_PIN`<br>- Hiển thị kết quả Điểm danh thành công | Positive | P1 |
| **TC_CHK_003** | Đồng hồ đếm ngược trên màn hình Xác nhận điểm danh | Mở màn hình `/attendance/check-in` | 1. Xem thời gian hiệu lực còn lại của mã QR<br>2. Chờ thời gian đếm ngược giảm dần | — | - Hiển thị thời gian đếm ngược chính xác (phút:giây dạng monospace)<br>- Nếu quá hạn trước khi bấm, hiển thị cảnh báo yêu cầu quét lại mã mới | Functional | P2 |
| **TC_CHK_004** | Tự động điền thông tin ca học & tên giảng viên | Mở link QR điểm danh | 1. Quan sát các trường thông tin trên màn hình Check-In | — | - Hiển thị đúng Tên môn học, Mã lớp, Slot học, Tên giảng viên và IP Wi-Fi đã phát hiện | Functional | P2 |

---

## 8. Module 6: Bảo mật, Chống Gian lận & Xử lý Mã Lỗi (SEC)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào / Tình huống | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_SEC_001** | **Chống điểm danh hộ (Trùng thiết bị - Device Anti-Fraud)** | Sinh viên A đã dùng điện thoại A điểm danh thành công | 1. Đăng xuất Sinh viên A trên điện thoại A<br>2. Đăng nhập tài khoản Sinh viên B trên cùng điện thoại A<br>3. Quét mã QR điểm danh cho Sinh viên B | Cùng Device Fingerprint / Cookie thiết bị | - Backend chặn lại với mã lỗi `DEVICE_ALREADY_USED`<br>- Màn hình kết quả hiển thị thông báo đỏ: *"Thiết bị này đã điểm danh cho một sinh viên khác trong buổi học này"*<br>- Không ghi nhận điểm danh cho SV B | Security | P1 |
| **TC_SEC_002** | **Chặn điểm danh từ xa (Sai Subnet Wi-Fi)** | Giảng viên phát Wi-Fi dải `192.168.1.x`. SV dùng mạng 4G/5G hoặc Wi-Fi ngoài lớp | 1. Sinh viên tắt Wi-Fi phòng học, bật 4G<br>2. Nhận ảnh chụp mã QR từ bạn trong lớp và quét link điểm danh<br>3. Nhấn "ĐIỂM DANH NGAY" | IP Public / Subnet ngoài dải mạng GV | - Backend từ chối với mã lỗi `INVALID_IP_ADDRESS`<br>- Frontend hiển thị thông báo lỗi thân thiện: *"Địa chỉ IP của bạn không trùng với mạng Wi-Fi của phòng học"*<br>- Hướng dẫn: *"Vui lòng kết nối vào Wi-Fi phòng học"* | Security | P1 |
| **TC_SEC_003** | **Chặn mã QR đã hết hạn (TOTP Expiration)** | Phiên cấu hình chu kỳ QR 20s | 1. Sinh viên chụp lại ảnh mã QR<br>2. Đợi 40 giây sau (đã qua chu kỳ đổi mã QR)<br>3. Thực hiện quét và bấm điểm danh bằng mã cũ | Mã TOTP cũ đã quá hạn 20s | - Backend trả về mã lỗi `SESSION_EXPIRED` hoặc `INVALID_QR_TOKEN`<br>- Frontend hiển thị: *"Mã QR đã hết hạn, vui lòng quét mã mới nhất trên màn chiếu"* | Security | P1 |
| **TC_SEC_004** | **Chặn điểm danh khi phiên đã đóng (Session Closed)** | Giảng viên đã nhấn "Kết thúc phiên" | 1. Sinh viên quét mã QR sau khi GV đã đóng phiên<br>2. Nhấn "ĐIỂM DANH NGAY" | Phiên trạng thái `CLOSED` | - Báo lỗi `SESSION_CLOSED`: *"Phiên điểm danh đã kết thúc bởi giảng viên"* | Security | P1 |
| **TC_SEC_005** | **Chặn sinh viên chưa ghi danh vào môn học** | Sinh viên C chưa đăng ký môn `PRM323` | 1. Sinh viên C quét mã điểm danh môn `PRM323`<br>2. Nhấn Điểm danh | Tài khoản SV chưa enroll môn học | - Báo lỗi `STUDENT_NOT_ENROLLED`: *"Bạn chưa đăng ký tham gia lớp học phần này"* | Security | P1 |
| **TC_SEC_006** | **Chặn điểm danh lặp lại nhiều lần (Already Checked In)** | Sinh viên A đã điểm danh thành công | 1. Sinh viên A quét lại mã QR một lần nữa<br>2. Bấm Điểm danh tiếp | Sinh viên đã có trạng thái Có mặt | - Báo thông báo: *"Bạn đã được ghi nhận điểm danh cho buổi học này rồi"*<br>- Không ghi đè hay tạo bản ghi trùng lặp | Business Logic | P2 |
| **TC_SEC_007** | **Nhập sai mã PIN 6 số** | Phiên đang mở | 1. Vào Tab Nhập mã PIN<br>2. Nhập mã PIN sai (ví dụ: `000000`)<br>3. Bấm xác nhận | PIN: `000000` | - Báo lỗi: *"Mã PIN không chính xác, vui lòng kiểm tra lại trên màn chiếu"* | Negative | P2 |

---

## 9. Module 7: Nhật ký & Thống kê Chuyên cần (HIST - Sinh viên)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_HIST_001** | Xem tỷ lệ chuyên cần & thống kê tổng quan | Sinh viên đã tham gia nhiều buổi học | 1. Vào mục "Lịch sử" (`/student/history`)<br>2. Quan sát 4 ô chỉ số thống kê | — | - Hiển thị đúng: Tổng số buổi, Có mặt, Vắng mặt<br>- Tỷ lệ % chuyên cần = (Có mặt / Tổng) * 100%<br>- Nếu tỷ lệ ≥ 80% hiển thị màu xanh lá; nếu < 80% hiển thị cảnh báo đỏ | Positive | P1 |
| **TC_HIST_002** | Lọc lịch sử theo Khoảng thời gian (Từ ngày - Đến ngày) | Đang ở trang Lịch sử | 1. Nhấn nút chọn "Từ ngày" (VD: `01/09/2026`)<br>2. Nhấn nút chọn "Đến ngày" (VD: `25/09/2026`)<br>3. Nhấn "Lọc dữ liệu" | Khoảng ngày: `01/09/2026` - `25/09/2026` | - Danh sách chỉ hiển thị các buổi điểm danh trong khoảng ngày đã chọn<br>- Các thẻ chỉ số thống kê tự động tính toán lại theo khoảng ngày | Positive | P2 |
| **TC_HIST_003** | Lọc lịch sử theo Môn học cụ thể | Đang ở trang Lịch sử | 1. Mở Dropdown "Chọn môn học"<br>2. Chọn môn `PRM323`<br>3. Quan sát kết quả | Môn: `PRM323` | - Chỉ hiển thị các buổi học thuộc môn `PRM323`<br>- Tỷ lệ chuyên cần hiển thị riêng cho môn `PRM323` | Positive | P2 |
| **TC_HIST_004** | Lọc lịch sử theo Trạng thái (Có mặt / Vắng mặt) | Đang ở trang Lịch sử | 1. Chọn Dropdown trạng thái "Vắng mặt" | Trạng thái: `ABSENT` | - Lọc ra tất cả các buổi vắng mặt để sinh viên theo dõi nguy cơ cấm thi | Positive | P2 |
| **TC_HIST_005** | Hiển thị dạng Thẻ (Card List) trên Mobile | Mở bằng điện thoại (< 800px) | 1. Mở trang Lịch sử trên điện thoại<br>2. Cuộn xem danh sách | Màn hình điện thoại | - Các buổi học hiển thị dạng Card bo góc độc lập (không dùng bảng Table tràn ngang)<br>- Đầy đủ: Mã môn, Ngày giờ, Tên giảng viên, Slot, Phương thức (QR/PIN) | Responsive | P1 |

---

## 10. Module 8: Giao diện Đa nền tảng & Mobile Responsive (RESP)

| Mã TC | Tên Test Case | Điều kiện tiên quyết | Các bước thực hiện | Dữ liệu đầu vào / Thiết bị | Kết quả mong đợi | Loại TC | Mức ưu tiên |
|---|---|---|---|---|---|---|---|
| **TC_RESP_001** | Thanh điều hướng dưới đáy (Bottom Navigation Bar) cho SV | Màn hình di động (`width < 800px`), Role `STUDENT` | 1. Đăng nhập tài khoản Sinh viên trên điện thoại<br>2. Quan sát thanh điều hướng đáy màn hình | Màn hình Mobile (< 800px) | - Xuất hiện cố định BottomNavigationBar gồm **4 Tab**: *Buổi học*, *Tìm môn*, *Quét QR*, *Lịch sử*<br>- Bấm chuyển tab mượt mà, đổi icon và màu sắc active chính xác | Responsive | P1 |
| **TC_RESP_002** | Ẩn Sidebar và hiển thị Drawer trên Mobile | Màn hình di động (`width < 800px`) | 1. Mở bất kỳ trang nào trên mobile<br>2. Nhấn icon Menu 3 gạch trên AppBar | Mobile Browser / App | - Sidebar cố định tự động ẩn<br>- Bấm Menu mở ra Navigation Drawer từ bên trái, có logo và thông tin tài khoản | Responsive | P2 |
| **TC_RESP_003** | Lưới chỉ số thống kê 2x2 trên Mobile | Màn hình di động | 1. Mở trang Lịch sử (`/student/history`) trên điện thoại | Mobile Screen | - 4 ô chỉ số tự động xếp thành lưới 2 cột x 2 hàng, không bị tràn ngang hay vỡ chữ | Responsive | P2 |
| **TC_RESP_004** | Bộ lọc xếp chồng theo chiều dọc (Stacked Filters) | Màn hình di động | 1. Mở trang Tìm môn (`/student/courses`) trên điện thoại | Mobile Screen | - Ô tìm kiếm và Dropdown học kỳ tự động xếp dọc (1 cột), không bị đè lên nhau khi bàn phím ảo bật lên | Responsive | P2 |
| **TC_RESP_005** | Không phát sinh lỗi Overflow trên toàn bộ màn hình | Kiểm thử trên nhiều kích cỡ màn hình (360px, 390px, 412px, 768px, 1920px) | 1. Dùng DevTools chuyển đổi các thiết bị (iPhone SE, iPhone 14 Pro, Pixel 7, iPad, Desktop)<br>2. Duyệt qua tất cả các trang | Các kích thước màn hình | - Không xuất hiện vệt sọc vàng đen cảnh báo RenderFlex Overflow<br>- Bố cục co giãn tự nhiên, nội dung dài cuộn được (`SingleChildScrollView`) | UI/UX | P1 |

---

## 11. Ma trận Truy xuất & Nghiệm thu (Test Execution Checklist)

Dành cho Tester tích dấu `[x]` khi hoàn thành kiểm thử trên môi trường thực tế:

### 11.1. Luồng Giảng viên (Lecturer Flow)
- [ ] **TC_AUTH_001**: Đăng nhập tài khoản Giảng viên thành công
- [ ] **TC_CRS_001**: Xem danh sách môn học phụ trách
- [ ] **TC_CRS_002**: Tạo môn học mới thành công
- [ ] **TC_CRS_004**: Cập nhật thông tin phòng học / môn học
- [ ] **TC_CRS_006**: Import danh sách sinh viên bằng file Excel
- [ ] **TC_SES_001**: Tạo phiên điểm danh với chu kỳ QR 20s mặc định
- [ ] **TC_SES_002**: Tùy chỉnh chu kỳ QR (10s, 30s, 60s)
- [ ] **TC_SES_003**: Kiểm tra tính năng tự động nhận diện IP Wi-Fi
- [ ] **TC_SES_004**: Trình chiếu màn hình Live QR: đếm ngược 20s và đổi mã QR TOTP
- [ ] **TC_SES_005**: Màn hình Live hiển thị mã PIN 6 số dự phòng
- [ ] **TC_SES_006**: Bảng kết quả nhảy sinh viên có mặt thời gian thực (Real-time)
- [ ] **TC_SES_007**: Giảng viên bấm kết thúc phiên điểm danh thành công

### 11.2. Luồng Sinh viên (Student Flow)
- [ ] **TC_AUTH_002**: Đăng nhập tài khoản Sinh viên thành công
- [ ] **TC_RESP_001**: Hiển thị BottomNavigationBar 4 Tab trên Mobile
- [ ] **TC_ENRL_001**: Tìm kiếm môn học theo từ khóa
- [ ] **TC_ENRL_003**: Đăng ký môn học thành công
- [ ] **TC_CHK_001**: Quét mã QR điểm danh thành công khi kết nối Wi-Fi phòng học
- [ ] **TC_CHK_002**: Điểm danh thành công bằng mã PIN 6 số
- [ ] **TC_HIST_001**: Xem tỷ lệ chuyên cần & màu sắc cảnh báo (>80% xanh, <80% đỏ)
- [ ] **TC_HIST_002**: Lọc lịch sử chuyên cần theo Từ ngày - Đến ngày
- [ ] **TC_HIST_005**: Lịch sử điểm danh hiển thị dạng Card List không bị vỡ bảng

### 11.3. Luồng Bảo mật & Chống Gian lận (Security & Anti-Fraud Flow)
- [ ] **TC_SEC_001**: **1 Thiết bị điểm danh cho 2 SV khác nhau** ➔ Bị chặn lỗi `DEVICE_ALREADY_USED`
- [ ] **TC_SEC_002**: **Bật 4G / mạng ngoài lớp quét QR** ➔ Bị chặn lỗi `INVALID_IP_ADDRESS`
- [ ] **TC_SEC_003**: **Chụp ảnh QR cũ quá 20s quét lại** ➔ Bị chặn lỗi `SESSION_EXPIRED`
- [ ] **TC_SEC_004**: **Quét khi phiên đã đóng** ➔ Bị chặn lỗi `SESSION_CLOSED`
- [ ] **TC_SEC_005**: **SV chưa đăng ký môn quét QR** ➔ Bị chặn lỗi `STUDENT_NOT_ENROLLED`
- [ ] **TC_SEC_006**: **SV điểm danh lần 2 trong cùng buổi** ➔ Báo đã có mặt, không lặp lại

---

> **Tổng kết**:  
> - Tổng số Test Case đặc tả: **43 Test Cases**  
> - Độ phủ: 8 Module (Authentication, Course, Enrollment, Sessions, Check-In, Anti-Fraud Security, History, Responsive UI)  
> - Tiêu chí Pass: 100% các Test Case mức **P1 (Critical)** và tối thiểu 95% các Test Case mức **P2/P3** đạt kết quả mong đợi.
