TRẠNG THÁI CHI TIẾT
1. Trạng thái Đơn đặt chỗ (Booking States)
Quản lý vòng đời của đơn đặt chỗ từ lúc người chơi thao tác trên ứng dụng di động cho đến khi có mặt tại quán.
PENDING_DEPOSIT (Chờ đặt cọc): Khách vừa bấm đặt chỗ trên ứng dụng di động. Hệ thống tạm thời giữ số lượng ghế tương ứng trong kho trong vòng 5 phút để chờ phản hồi từ cổng thanh toán.
CONFIRMED (Đặt chỗ thành công): Hệ thống nhận được phản hồi giao dịch thanh toán tiền cọc thành công từ cổng thanh toán. Ghế được chính thức chuyển sang trạng thái giữ chỗ cho khách.
CHECKED_IN (Đã check-in): Khách đã đến quán và nhân viên quét mã thành công. Đơn đặt chỗ hoàn thành mục đích giữ chỗ và chuyển giao dữ liệu sang phân hệ quản lý phiên chơi tại quán.
EXPIRED (Quá hạn giữ chỗ): Quá giờ hẹn chơi cộng với thời gian trễ tối đa cho phép (ví dụ 30 phút) mà nhóm khách không đến quán quét mã. Hệ thống tự động giải phóng ghế và kích hoạt luật phạt đóng băng cọc.
CANCELLED_BY_PLAYER (Khách chủ động hủy): Người chơi chủ động bấm hủy đơn trên ứng dụng di động trước khung giờ quy định. Tiền cọc được xử lý hoàn/phạt theo chính sách thời gian của quán.
CANCELLED_BY_CAFE (Quán chủ động hủy): Quản lý quán chủ động thực hiện lệnh hủy đơn trên thiết bị điểm bán do các tình huống quá tải ghế thực tế bất khả kháng tại quán. Hệ thống tự động hoàn cọc 100% cho người chơi.
2. Trạng thái Phòng chờ trực tuyến (Lobby States)
Quản lý tiến trình khớp phòng, tìm kiếm và tuyển thêm thành viên chơi game trên ứng dụng di động.
OPEN (Đang tuyển người): Phòng chờ hiển thị công khai trên ứng dụng di động. Hệ thống liên tục quét bán kính vị trí và gửi thông báo mời các người chơi thỏa mãn điểm uy tín gia nhập phòng.
FULL (Đã đủ người): Số lượng người tham gia phòng chờ đã đạt mức tối đa theo cấu hình của tựa game, hoặc Trưởng nhóm chủ động bấm khóa phòng sớm để chuẩn bị đặt chỗ.
TIMEOUT_FAILED (Hủy do quá hạn tuyển): Đến mốc giờ hẹn chơi trừ đi thời gian thông báo quy định mà phòng chờ vẫn không gom đủ số lượng người chơi tối thiểu để bắt đầu tựa game đã chọn. Hệ thống tự động giải tán phòng chờ.
HOST_CANCELLED (Trưởng nhóm hủy): Trưởng nhóm chủ động bấm giải tán phòng chờ khi phòng đang ở trạng thái tuyển người.
IN_PROGRESS (Đang diễn ra): Trạng thái đồng bộ khi nhóm khách đã hoàn tất thủ tục check-in tại quầy điểm bán và ván game thực tế đã chính thức bắt đầu.
CLOSED (Đã đóng phòng): Phiên chơi tại quán kết thúc hoàn toàn. Trạng thái phòng chờ đóng lại để hệ thống ghi nhận xong lịch sử trận đấu, biến động điểm trình độ và kích hoạt màn hình đánh giá uy tín.
3. Trạng thái Ghế ngồi vật lý (Seat Slot States)
Quản lý năng suất và tính khả dụng thời gian thực của từng đơn vị chỗ ngồi trong kho tài nguyên của quán.
AVAILABLE (Trống khả dụng): Ghế đang trống, sẵn sàng tiếp đón khách vãng lai tại quầy hoặc cho phép khách đặt chỗ trực tuyến trên ứng dụng di động.
HOLDING (Giữ chỗ tạm thời): Ghế bị khóa tạm thời trong vòng 5 phút khi có giao dịch đặt chỗ đang chờ xử lý thanh toán cọc trên cổng thanh toán trực tuyến.
RESERVED (Đã được giữ chỗ): Ghế đã được đặt cọc thành công, hệ thống khóa suất ghế này trong khung giờ hẹn chơi của khách để nhân viên tiếp đón chuẩn bị vị trí ngồi.
IN_USE (Đang sử dụng): Khách đã ngồi vào vị trí chơi và phiên tính giờ chơi đang hoạt động công khai trên hệ thống.
4. Trạng thái Phiên chơi tại quán (Session States)
Gồm hai cấp độ: Phiên chơi tổng (Group Session - Quản lý chung cả nhóm và bộ game) và Phiên chơi cá nhân (Individual Session - Quản lý độc lập thời gian thực của từng người chơi phục vụ luồng tách/ghép/khách vô danh).
4.1. Trạng thái của Phiên chơi tổng (Group Session States)
ACTIVE (Đang hoạt động): Phiên chơi tổng của nhóm đang đếm giờ chơi thời gian thực và đang được gán liên kết với mã vạch của tựa game nhóm đang mượn.
CHECKING (Kiểm kho trung gian): Nhóm khách mang bộ game ra quầy trả khi kết thúc ván chơi hoặc khi có người về sớm. Hệ thống khóa tạm thời tính năng in hóa đơn để nhân viên thực hiện đếm linh kiện trên bảng kiểm kê số hóa.
UNPAID (Chờ thanh toán): Nhân viên hoàn tất quy trình đối chiếu linh kiện số hóa, hệ thống chốt số phút chơi, áp biểu phí cấu hình và xuất hóa đơn tổng của nhóm ở trạng thái chờ thu tiền.
PAID (Đã thanh toán): Đại diện nhóm hoàn tất thanh toán hóa đơn tổng. Phiên chơi tổng chính thức đóng lại và giải phóng toàn bộ số ghế của nhóm về kho trống.
4.2. Trạng thái của Phiên chơi cá nhân (Individual Session States)
PLAYING (Đang chơi): Tài khoản người chơi (hoặc suất khách vô danh) đang được kích hoạt đếm phút tính tiền giờ chơi lũy tiến thời gian thực tại nhóm.
SUSPENDED_MUTATION (Treo dịch chuyển): Trạng thái bộ nhớ đệm khi một cá nhân hoàn thành bước kiểm kê game ở nhóm cũ để chuẩn bị nhảy sang nhóm mới. Trục thời gian tổng của người này vẫn chạy ngầm nhưng liên kết nhóm bị treo để chờ nhân viên quét mã nhập vào đơn nhóm mới.
FINISHED (Đã kết thúc): Người chơi đã hoàn tất nghĩa vụ thanh toán hóa đơn cá nhân (trong luồng về sớm một phần) hoặc đã được kết toán gộp chung vào hóa đơn tổng khi cả nhóm ra về. Thời gian chơi của cá nhân này chính thức dừng đếm.

