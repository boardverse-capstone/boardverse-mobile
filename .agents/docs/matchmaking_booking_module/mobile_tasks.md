ĐẶC TẢ NGHIỆP VỤ PHÂN HỆ: ỨNG DỤNG DI ĐỘNG & BACKEND NGƯỜI CHƠI (PLAYER ECOSYSTEM)
Tài liệu chuẩn hóa nghiệp vụ dành riêng cho Lập trình viên Di động và Backend để tiến hành lập trình
I. MỤC TIÊU PHÂN HỆ
Hoàn thiện toàn bộ giải pháp công nghệ phía người dùng (Player), bao gồm việc tìm kiếm hệ thống quán theo thời gian thực, xây dựng giải pháp khớp phòng chờ trực tuyến (Lobby), kiểm soát cổng thanh toán xử lý cọc của đơn Đặt chỗ (Booking), tối ưu hóa quy trình định danh bằng mã QR động và tự động kích hoạt bộ công cụ đánh giá, xử lý vi phạm hậu phiên chơi.
II. ĐẶC TẢ CHI TIẾT CÁC NHIỆM VỤ, MỤC TIÊU VÀ NGHIỆP VỤ CHỨC NĂNG
Task 1: Tìm kiếm Quán và Kiểm tra Năng suất Ghế trống Thời gian thực
Mục tiêu: Cung cấp thông tin chính xác tuyệt đối về số lượng chỗ ngồi còn trống theo từng khung giờ, chặn đứng hoàn toàn rủi ro trùng lịch đặt chỗ trực tuyến trước khi khách hàng thực hiện các bước thanh toán tài chính.
Nghiệp vụ chi tiết cần triển khai:
Phía Backend (Hệ thống xử lý):
Xây dựng API tra cứu, tính toán số lượng ghế trống khả dụng của từng quán đối tác.
Triển khai logic tính toán: Hệ thống vận hành theo triết lý quản lý số chỗ ngồi (Seat-based), không chỉ định số bàn vật lý. Khi nhận tham số từ Client gửi lên, Backend phải lấy tổng số ghế đăng ký của quán trừ đi tổng số ghế đã bị khóa bởi các đơn đặt chỗ thành công (Booking) và các phiên chơi đang hoạt động (Session) trong cùng khung giờ.
Phía Ứng dụng Di động (Player Mobile App):
Xây dựng giao diện tìm kiếm quán dựa trên bộ lọc vị trí địa lý, tựa game board game cần chơi.
Khi người chơi điều chỉnh số lượng suất ghế cần đặt, ứng dụng tự động kích hoạt lệnh gọi API kiểm tra bất đồng bộ. Nếu Backend phản hồi số lượng ghế trống hiện tại không đáp ứng đủ , ứng dụng phải chuyển nút bấm đặt chỗ sang trạng thái vô hiệu hóa (Disabled) và hiển thị cảnh báo trực quan: "Quán không đủ số chỗ trống yêu cầu".
Task 2: Luồng Đặt chỗ và Kết toán Tiền cọc Trực tuyến
Mục tiêu: Thiết lập quy trình đặt chỗ có cọc bắt buộc nhằm giảm thiểu tối đa tỷ lệ bùng hẹn, đồng thời tự động kiểm soát hạn mức dòng tiền cọc theo đúng chính sách bảo vệ người tiêu dùng của hệ thống.
Nghiệp vụ chi tiết cần triển khai:
Phía Backend (Hệ thống xử lý):
Xây dựng hệ thống API xử lý tạo đơn đặt chỗ và tích hợp cơ chế lắng nghe phản hồi (Webhook) trạng thái từ cổng thanh toán đối tác.
Thực thi Luật BR-03 (Chặn trần tiền cọc): Hệ thống bắt buộc phải kiểm tra số tiền cọc gửi lên. Nếu số tiền cọc vượt quá biên độ 50% đơn giá giờ chơi đầu tiên hoặc giá vé vào cổng của quán đối tác, Backend phải lập tức từ chối khởi tạo đơn.
Quản lý trạng thái logic: Đơn mới khởi tạo mang trạng thái chờ cọc [Booking: Pending]. Nếu hệ thống nhận tín hiệu giao dịch thất bại từ Webhook, đơn tự động chuyển sang hủy [Booking: Cancelled] và lập tức giải phóng số lượng ghế đã giữ tạm thời trong bộ nhớ đệm. Nếu Webhook xác nhận giao dịch thành công, đơn chuyển trạng thái sang thành công [Booking: Success].
Phía Ứng dụng Di động (Player Mobile App):
Thiết kế màn hình tóm tắt thông tin đơn đặt chỗ, hiển thị số tiền cọc động được lấy từ cấu hình riêng biệt của từng quán.
Tích hợp bộ công cụ phát triển phần mềm (SDK) của cổng thanh toán để kích hoạt luồng trừ tiền tài khoản của khách hàng. Tiếp nhận kết quả trả về thời gian thực để chuyển đổi trạng thái giao diện tương ứng.
Task 3: Thuật toán Khớp phòng chờ trực tuyến (Lobby Matchmaking)
Mục tiêu: Tự động hóa quá trình ghép nhóm giữa các người chơi đơn lẻ hoặc các nhóm chưa đủ thành viên, tối ưu hóa công suất lấp đầy ghế thực tế cho các tựa game đòi hỏi quy mô người chơi lớn.
Nghiệp vụ chi tiết cần triển khai:
Phía Backend (Hệ thống xử lý):
Xây dựng logic quản lý và đồng bộ phòng chờ trực tuyến (Lobby).
Thực thi Luật BR-08 và BR-10: Hệ thống chỉ được phép sử dụng điểm uy tín hành vi (Karma) để làm bộ lọc điều kiện cho phép người chơi gia nhập phòng chờ, tuyệt đối không xét điểm trình độ kỹ năng (Elo) nhằm tránh phân tách cộng đồng giải trí.
Luồng Ghép đội trước - Đặt chỗ sau: Khi số lượng thành viên trong phòng chờ đạt trạng thái đầy (Ví dụ: 4/4 người) , Backend thực hiện khóa lệnh gia nhập ([Lobby: Closed]) và tự động gọi API khởi tạo một đơn đặt chỗ mang trạng thái chờ cọc [Booking: Pending], gán nghĩa vụ thanh toán tiền cọc trực tiếp lên tài khoản của Trưởng phòng chờ (Host).
Luồng Đặt chỗ trước - Ghép đội sau: Cho phép người chơi sở hữu đơn Booking_ID ở trạng thái thành công được khởi tạo phòng chờ tuyển thêm người. Backend phải thực thi lệnh chặn chặn không cho số lượng thành viên bấm tham gia vượt quá số lượng ghế trống khả dụng còn lại của chính đơn đặt chỗ đó.
Thực thi Luật BR-04 (Hủy phòng quá hạn): Cấu hình tác vụ quét ngầm tự động theo chu kỳ thời gian (Cron job), nếu đến mốc giờ hẹn chơi trừ đi khối thời gian thông báo (Lead-time) do quán cấu hình mà phòng chờ chưa đạt đủ số lượng thành viên tối thiểu của tựa game board game đã chọn, hệ thống thực hiện hủy phòng chờ ([Lobby: Failed]) để giải phóng ghế.
Phía Ứng dụng Di động (Player Mobile App):
Xây dựng giao diện thiết lập phòng chờ, cho phép Host cấu hình tựa game, bán kính tìm kiếm và mức điểm uy tín Karma tối thiểu của thành viên.
Task 4: Giải pháp Định danh nhóm qua Mã QR Động (Single Check-in)
Mục tiêu: Triển khai cơ chế xác thực một chạm tại quầy, đồng bộ hóa tức thì trạng thái của toàn bộ thành viên trong nhóm sang trạng thái đang chơi mà không cần thao tác thủ công từ nhân viên.
Nghiệp vụ chi tiết cần triển khai:
Phía Backend (Hệ thống xử lý):
Xây dựng API mã hóa dữ liệu động để sinh ra mã QR đại diện cho Booking_ID hoặc Lobby_ID chứa toàn bộ mảng danh sách mã tài khoản thành viên đã được phê duyệt trực tuyến.
Phía Ứng dụng Di động (Player Mobile App):
Thiết kế màn hình hiển thị mã QR Check-in trên ứng dụng của Host.
Cấu hình cơ chế lắng nghe sự kiện bất đồng bộ thời gian thực thông qua giao thức kết nối mạng (WebSocket hoặc Push Notification). Ngay khi nhân viên tại quầy POS quét mã thành công, ứng dụng di động của toàn bộ thành viên thuộc phòng chờ đó phải lập tức tự động cập nhật trạng thái đơn hàng sang [Booking: Checked-In] và chuyển hướng sang màn hình theo dõi phiên chơi đang diễn ra tại quán.
Task 5: Hệ thống Biểu quyết Hủy hẹn và Đánh giá hành vi (Karma)
Mục tiêu: Chống lại các hình thức xử phạt máy móc của hệ thống bằng giải pháp biểu quyết dân chủ của cộng đồng, đồng thời tự động cập nhật chỉ số uy tín hành vi của người chơi sau mỗi phiên trải nghiệm thực tế.
Nghiệp vụ chi tiết cần triển khai:
Phía Backend (Hệ thống xử lý):
Xây dựng hệ thống API thu thập và xử lý kết quả biểu quyết lỗi bùng hẹn giờ chót (No-show) và biểu mẫu chấm điểm thái độ.
Logic xử lý vi phạm: Khi nhân viên tại quầy POS thực hiện check-in với số lượng người thực tế đi thiếu tại quán (Ví dụ: Đơn đặt 4 nhưng thực tế chỉ đi 3) , Backend tiến hành đóng băng khoản cọc của thành viên vắng mặt. Hệ thống sẽ không xử phạt ngay. Khi phiên chơi tổng đóng lại, Backend thu thập dữ liệu biểu quyết từ các thành viên có mặt. Nếu số đông đồng thuận xác nhận "Vắng mặt không lý do chính đáng", hệ thống mới chính thức thực hiện khấu trừ tiền cọc chuyển vào hóa đơn tổng của nhóm và hạ điểm uy tín Karma của tài khoản vi phạm.
Phía Ứng dụng Di động (Player Mobile App):
Xây dựng giao diện hiển thị biểu mẫu biểu quyết No-show đối với thành viên vắng mặt và bảng chấm điểm thái độ đối lưu chéo (Cross-rating) giữa các thành viên, tự động kích hoạt hiển thị ngay khi phiên chơi tại quầy POS được nhân viên bấm đóng.

