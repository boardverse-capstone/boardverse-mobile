# HỆ THỐNG CONTEXT NỀN CHO AI CHUYÊN PHÂN HỆ: GHÉP ĐỘI & ĐẶT CHỖ

Tài liệu này quy định tất cả các quy tắc kinh doanh, logic trạng thái và luồng nghiệp vụ cốt lõi của hệ thống BoardVerse. Bất kỳ mã nguồn nào được sinh ra (API, Cơ sở dữ liệu, Logic nghiệp vụ) đều phải tuân thủ nghiêm ngặt các điều kiện ràng buộc trong tệp tin này.

---

## I. KIẾN TRÚC THỰC THỂ & TRIẾT LÝ QUẢN LÝ TÀI NGUYÊN

1. **Quản lý theo Chỗ ngồi (Seat-based):** Hệ thống quản lý tài nguyên của quán theo tổng số lượng chỗ ngồi (Ghế trống khả dụng), không quản lý sơ đồ bàn vật lý (Physical Table) trên môi trường trực tuyến. Nhân viên tại quầy (Web POS) là người toàn quyền chỉ định vị trí ngồi thực tế khi khách đến.
2. **Quản lý theo Phiên chơi (Session-based):** Hệ thống quản lý tài chính và thời gian dựa trên trục thời gian thực tế của từng mã định danh người chơi (User ID). Người chơi không cần tương tác với ứng dụng di động để kết thúc, toàn bộ quy trình đóng phiên và xuất hóa đơn được điều khiển tự động bởi Nhân viên từ thiết bị Web POS.
3. **Định danh nhóm (Host-led Check-in):** Cho phép quét một lần mã định danh của Trưởng nhóm (Host) để kích hoạt phiên chơi cho toàn bộ thành viên trực tuyến, tối ưu hóa trải nghiệm người dùng và giảm tải vận hành cho nhân viên.

---

## II. QUY TẮC RÀNG BUỘC KINH DOANH (BUSINESS RULES - BR)

### 1. Quy tắc cấu hình cấu trúc biểu phí của quán (Cafe Pricing Configuration)
* **BR-01 (Mô hình kinh doanh khả dụng):** Quán đối tác bắt buộc phải chọn 1 trong 2 mô hình tính tiền để hệ thống áp dụng logic xuất hóa đơn:
    * *Mô hình 1 (Thời gian thực):* Tính tiền theo khối thời gian (Giá giờ đầu + Giá lũy tiến block số phút).
    * *Mô hình 2 (Vào cổng trọn gói):* Thu phí cố định duy nhất (Giá giờ đầu = Giá vé vào cổng; Giá các block tiếp theo = 0 VNĐ).
* **BR-02 (Ràng buộc giới hạn tiền cọc):** Mức phí đặt cọc trực tuyến không được là một giá trị cố định, mà cho phép Quản lý quán (Cafe Manager) tự do cấu hình thay đổi tùy thuộc vào định giá vé của từng quán.
* **BR-03 (Công thức chặn trần tiền cọc):** Hệ thống bắt buộc phải thực hiện kiểm tra và chặn không cho Quản lý quán lưu cấu hình nếu mức cọc vượt quá 50% giá trị vé cơ bản của cá nhân:
    $$\text{Phí đặt cọc} \le 50\% \times \text{Mức phí giờ đầu (hoặc Giá vé vào cổng)}$$
* **BR-04 (Khóa biến động giá):** Hệ thống chặn toàn bộ thao tác chỉnh sửa biểu phí giờ chơi của Quản lý quán trong suốt khung giờ quán đang hoạt động. Tính năng cập nhật giá chỉ được mở khóa khi trạng thái của quán là đóng cửa. Mọi thay đổi giá phải được hệ thống tự động lên lịch gửi thông báo Push đến toàn bộ người chơi đã có lịch hẹn Booking trong tuần.

### 2. Quy tắc Đơn đặt chỗ & Phòng chờ trực tuyến (Booking & Matchmaking)
* **BR-05 (Điều kiện xác định Booking thành công):** Đơn đặt chỗ trực tuyến chỉ được phê duyệt trạng thái `[Booking: Success]` khi và chỉ khi thỏa mãn đồng thời:
    * Số ghế khách đặt nhỏ hơn hoặc bằng Tổng số ghế trống còn lại của quán trong khung giờ đó.
    * Hệ thống nhận được phản hồi trạng thái giao dịch thanh toán cọc thành công (`Payment: Success`) từ cổng thanh toán đối tác.
* **BR-06 (Thời hạn giữ chỗ):** Đơn đặt chỗ thành công có hiệu lực trong vòng X phút (Cấu hình bởi từng quán, tối đa 30 phút). Quá thời hạn này, trạng thái tự động chuyển thành `[Expired]`, hệ thống tự động giải phóng ghế trống về kho trực tuyến để đón khách vãng lai.
* **BR-07 (Ràng buộc quy mô phòng chờ):** Số lượng thành viên tối đa tham gia một phòng chờ trực tuyến (`Lobby`) không được vượt quá số lượng chỗ ngồi (`Seat_Count`) đã được xác nhận tại đơn đặt chỗ liên kết.
* **BR-08 (Hạn định thời gian hủy phòng):** Đối với luồng ghép đội trước - đặt chỗ sau, hệ thống tự động hủy phòng chờ nếu trước giờ hẹn chơi X phút thông báo mà số lượng thành viên tham gia phòng vẫn chưa đạt quy mô tối thiểu của tựa game đã lựa chọn.
* **BR-09 (Bảo lưu dữ liệu tài chính):** Số tiền cọc trực tuyến ban đầu của Host chỉ được hệ thống thực hiện cấn trừ duy nhất một lần vào hóa đơn tổng khi có lệnh kết thúc toàn bộ phiên chơi của nhóm tại máy điểm bán.
* **BR-10 (Tiêu chí lọc phòng chờ):** Quy trình ghép đội trực tuyến chỉ thực hiện quét và lọc điều kiện thành viên dựa trên điểm uy tín Karma, tuyệt đối không xét điểm trình độ Elo (Elo chỉ dùng trong phân hệ Giải đấu).
* **BR-11 (Giới hạn độ tuổi sử dụng):** Hệ thống giới hạn độ tuổi đăng ký tài khoản người chơi từ 13 tuổi trở lên để bảo vệ tài sản có giá trị cao tại quán đối tác.

### 3. Quy tắc kiểm kê linh kiện & Khách vô danh (Inventory & Guest Slot Rules)
* **BR-12 (Kiểm kê trung gian bắt buộc):** Khi phát sinh yêu cầu thanh toán một phần (Partial Checkout) để có thành viên về sớm trong một phiên chơi chung, hệ thống khóa tính năng in hóa đơn rời nhóm cho đến khi nhân viên thực hiện xác nhận bảng kiểm kê linh kiện số hóa (`Digital Component Checklist`) của tựa game đang mượn trên Web POS.
* **BR-13 (Ràng buộc trách nhiệm tài sản của Khách vô danh):** Suất khách vô danh (`Guest_Slot`) được thêm thủ công trên POS (Trường hợp khách hết pin/không dùng ứng dụng) không có tư cách chịu trách nhiệm tài sản độc lập. 
* **BR-14 (Chặn gán phí phạt cho khách vô danh):** Hệ thống chặn không cho phép nhân viên gán chi phí đền bù linh kiện mất/hỏng vào hóa đơn của `Guest_Slot`. Phí phạt phát sinh bắt buộc phải xử lý dứt điểm ngay tại bước kiểm kê trung gian: hoặc thu trực tiếp từ người về sớm thông qua biên bản ghi nhận của nhân viên, hoặc gộp toàn bộ vào hóa đơn tổng của người chơi khởi tạo (Host) để nhóm tự đối lưu tiền mặt nội bộ trước khi lệnh đóng phiên chơi cá nhân được phê duyệt.

---

## III. CHI TIẾT LUỒNG VẬN HÀNH THỰC TẾ (USE CASES & EDGE CASES)

### 1. Luồng Thuận Lợi (Happy Path)
1. **Khởi tạo trực tuyến:** Host tạo `Lobby` chơi game *Catan* lúc 19:00 tại Thủ Đức, yêu cầu tuyển thêm 3 người (Thỏa mãn điểm uy tín Karma > 80). Ba người chơi B, C, D bấm xin tham gia. Phòng chờ đạt trạng thái đầy (4/4 người).
2. **Xác nhận đặt chỗ:** Hệ thống kiểm tra công suất ghế trống của quán lân cận tại khung giờ 19:00 -> Đủ điều kiện -> Host thực hiện thanh toán cọc thành công ứng với cấu hình giá cọc của quán (Không vượt quá 50% tiền vé) -> Cấp mã `Booking_ID` [Success].
3. **Thủ tục vào quán (Check-in nhanh):** Nhóm đến quán lúc 19:00. Nhân viên quét duy nhất mã QR đặt chỗ trên máy của Host. Hệ thống tự động kích hoạt phiên chơi chung (`Session: Active`) đồng loạt cho tất cả thành viên trong nhóm và chạy đếm giờ. Nhân viên quét barcode giao game *Catan* cho khách.
4. **Kết toán quy trình tự động:** Nhóm chơi xong mang trả game. Nhân viên kiểm kê đủ linh kiện trên màn hình checklist số hóa của POS. Hệ thống chốt số phút sử dụng thực tế, nhân đơn giá giờ chơi, cấn trừ tiền cọc trực tuyến của Host và xuất hóa đơn tổng. Khách thanh toán ra về. Quy trình kết thúc tự động hoàn toàn, ứng dụng di động hiển thị màn hình đánh giá chéo điểm Karma giữa các thành viên.

### 2. Luồng Ngoại Lệ (Exception Path) - Xử lý tính toán khi tách/ghép nhóm
**Tình huống:** Nhóm A gồm 3 người (A1, A2, A3) đến quán cùng lúc lúc 12:00. Đến 13:00, A1 và A2 thanh toán về sớm, A3 ở lại và di chuyển sang ngồi chơi chung với Nhóm B (đã chơi sẵn tại quán từ trước).

**Xử lý nghiệp vụ trên hệ thống:**
* **Bước 1:** A1 và A2 ra quầy báo về sớm. Nhân viên mở đơn Nhóm A trên POS, dùng tính năng "Thanh toán một phần" chọn mã định danh của A1 và A2.
* **Bước 2 (Kiểm kê bắt buộc):** Hệ thống chặn in hóa đơn. Nhân viên đếm linh kiện của Nhóm A. Nếu phát hiện thiếu quân cờ, hệ thống bắt buộc nhân viên gán phí phạt vào hóa đơn về sớm này hoặc gộp vào đơn của Host nhóm A để thu tiền mặt dứt điểm trước khi đóng phiên. Tiền cọc ban đầu của đơn Nhóm A được khấu trừ hoàn toàn tại hóa đơn này. Trạng thái phiên chơi của A1 và A2 chuyển thành `[Ended]`.
* **Bước 3 (Duy trì phiên độc lập):** Phiên chơi của thành viên A3 tại Nhóm A vẫn được hệ thống tiếp tục chạy đếm phút ở chế độ độc lập (`Stand-alone Session`), độc lập hoàn toàn với game cũ đã thu hồi.
* **Bước 4 (Hợp nhất dữ liệu thực địa):** A3 di chuyển sang ngồi cùng Nhóm B lúc 13:00. Nhân viên dùng máy điểm bán quét mã ứng dụng của A3 và bấm nút "Chuyển phiên nhập nhóm" (Merge Session) vào mã đơn hiện tại của Nhóm B. Hệ thống liên kết mã định danh của A3 vào danh sách thành viên hoạt động của Nhóm B mà không ngắt quãng tổng thời gian có mặt tại quán của A3.
* **Bước 5 (Kết toán tổng hợp):** Khi Nhóm B kết thúc phiên chơi (ví dụ lúc 15:00), nhân viên bấm kết thúc phiên tổng trên máy điểm bán. Hóa đơn cuối cùng của Nhóm B sẽ tự động cộng thêm phần tiền giờ chơi thực tế của thành viên A3 (tính tổng lũy tiến từ 12:00 đến 15:00 là 3 tiếng chơi). Thành viên A3 chịu biểu phí giờ chơi thuần của Nhóm B trong giai đoạn sau và không được mang phần cọc cũ của đơn nhóm A theo.

---

## IV. MA TRẬN CHUYỂN ĐỔI TRẠNG THÁI HỆ THỐNG (STATE MACHINE)
[Trống - Available]
│ (Khách đặt chỗ trực tuyến + Thanh toán cọc thành công - BR-01, BR-03)
▼
[Đã giữ chỗ - Reserved]
│
├─► (Quá hạn X phút không đến check-in - BR-06) ──► [Quá hạn - Expired] ──► Tịch thu cọc, Giải phóng ghế
│
└─► (Nhân viên quét QR của Host để nhận diện cả nhóm)
│
▼
[Đang sử dụng - In-Use]
│
├─► (Phát sinh người về sớm) ──► Kích hoạt Quy trình BR-12 (Kiểm kê bắt buộc giữa giờ)
│
└─► (Trả game + Đếm đủ linh kiện lúc kết thúc) ──► Thực hiện BR-07 (Khấu trừ cọc vào hóa đơn tổng)
│
▼
[Thanh toán thành công - Paid] ──► Hệ thống tự động chuyển trạng thái ghế về [Trống - Available]


*Yêu cầu: Tuyệt đối tuân thủ logic kiểm tra điều kiện (Validation) trước khi thực hiện các câu lệnh cập nhật (Update) trạng thái cơ sở dữ liệu.* 

