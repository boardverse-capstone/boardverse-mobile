Tài liệu này tập trung mô tả chi tiết, toàn diện mọi khía cạnh nghiệp vụ, quy tắc ứng xử, các trường hợp xử lý thông thường, kịch bản thay thế và các tình huống phát sinh lỗi đối với luồng tính năng Ghép đội trực tuyến (Matchmaking) gắn liền với Đặt bàn và Vận hành tại quầy.

I. KHÁM PHÁ BOARD GAME VÀ ĐỀ XUẤT ĐỊA ĐIỂM XUNG QUANH
1. Nghiệp vụ Tìm kiếm trò chơi và Đề xuất quán cafe
Luồng thông thường: Người chơi mở ứng dụng di động, nhập tên hoặc chọn danh mục thuộc tính (thể loại, số lượng người chơi, thời gian chơi) của tựa game Board Game mà họ muốn trải nghiệm. Hệ thống truy xuất kho dữ liệu toàn hệ thống và hiển thị thông tin chi tiết về tựa game đó. Khi người chơi chọn tựa game này, hệ thống sẽ tự động xác định vị trí hiện tại của người chơi (qua GPS) và đưa ra danh sách các quán cafe đối tác hiện đang có sẵn hộp game này trong kho, sắp xếp theo thứ tự khoảng cách từ gần đến xa. Danh sách quán cũng hiển thị kèm thông tin về số lượng bàn trống thực tế tại thời điểm đó để người chơi cân nhắc. Từ đây, người chơi có thể đưa ra quyết định: tiến hành tạo phòng chơi mới hoặc tìm các phòng chơi sẵn có của tựa game này tại quán đó.

Luồng thay thế (Kho game của quán hết hàng khả dụng): Nếu tựa game người chơi tìm kiếm có trong danh mục của quán nhưng tất cả các hộp game đó đều đang trong trạng thái "Đang được thuê chơi" bởi các bàn khác tại quầy, hệ thống vẫn hiển thị quán đó trong danh sách đề xuất nhưng sẽ gắn nhãn trạng thái "Chờ game trống" kèm thời gian ước tính giải phóng hộp game để người chơi chủ động chuẩn bị.

Tình huống ngoại lệ (Xử lý khi không có quyền vị trí): Nếu người chơi tắt quyền truy cập định vị vị trí (GPS) trên thiết bị, hệ thống sẽ bỏ qua bước lọc khoảng cách và lập tức hiển thị toàn bộ danh sách các quán cafe đối tác đang sở hữu tựa game này kèm theo địa chỉ cụ thể của từng quán. Ngay trên giao diện danh sách này, hệ thống hiển thị một thông báo nhắc nhở kèm nút chức năng để người chơi có thể bấm nhanh nhằm bật lại quyền GPS, hoặc một thanh nhập liệu thủ công để điền vị trí hiện tại (Quận/Huyện, Tỉnh/Thành phố). Khi người chơi cấp quyền hoặc nhập vị trí thành công, danh sách các quán cafe có game sẽ ngay lập tức được sắp xếp và cập nhật lại theo khoảng cách tối ưu để đưa ra kết quả phù hợp nhất.

Tình huống ngoại lệ (Ngoài phạm vi dịch vụ): Nếu tựa game người chơi tìm kiếm hoàn toàn không có sẵn tại bất kỳ quán cafe đối tác nào xung quanh phạm vi địa lý quy định (ví dụ trong bán kính 15km), hệ thống sẽ thông báo không tìm thấy địa điểm phù hợp và tự động gợi ý các tựa game có phong cách chơi tương đồng (cùng thể loại hoặc cơ chế) đang có sẵn tại các quán gần đó.

II. KHỞI TẠO VÀ THAM GIA PHÒNG CHỜ TRỰC TUYẾN
1. Nghiệp vụ Khởi tạo phòng chờ
Sau khi đã chọn được tựa game và quán cafe ưng ý từ bước tìm kiếm đề xuất, hệ thống thực hiện kiểm tra thuộc tính số lượng người chơi quy định của tựa game đó để điều hướng nghiệp vụ:

Kiểm tra điều kiện số lượng người chơi: * Nếu tựa game được chọn có cấu hình hỗ trợ chơi một mình (Số người chơi tối thiểu bằng 1) và người chơi muốn chơi đơn, hệ thống sẽ bỏ qua luồng ghép đội trực tuyến và dẫn thẳng người chơi đến giao diện Đặt bàn trực tiếp tại quán (Booking solo session).

Nếu tựa game bắt buộc phải chơi theo nhóm hoặc người chơi chọn chế độ chơi nhóm, hệ thống mới kích hoạt luồng khởi tạo phòng chờ (Matchmaking). Lúc này, hệ thống sẽ tự động hiển thị khoảng số lượng người chơi thích hợp của tựa game (Ví dụ: Avalon cần 5-10 người, Ma Sói cần 7-15 người) để hỗ trợ chủ phòng thiết lập số lượng slot trống cần tuyển thêm một cách chính xác.

Luồng thông thường: Người chơi chọn nút tạo phòng trực tiếp từ giao diện của tựa game và quán cafe đã chọn. Hệ thống hiển thị sức chứa và tình trạng mặt bằng hiện tại của quán đó để xác nhận lại. Chủ phòng tiến hành chọn cấu hình phòng chơi bao gồm: khung giờ hẹn và số lượng vị trí trống cần tuyển thêm dựa trên số người chơi thích hợp của game. Khi hệ thống kiểm tra điểm uy tín cá nhân của chủ phòng đạt chuẩn, một phòng chờ trực tuyến sẽ được thiết lập ở chế độ Công khai để mở rộng tìm kiếm cho những người chơi khác có cùng mối quan tâm về tựa game này.

Luồng bổ sung (Mời bạn bè vào phòng): Ngay sau khi phòng chờ được khởi tạo (ở cả chế độ Công khai hoặc Riêng tư), chủ phòng có quyền sử dụng tính năng "Mời bạn bè". Chủ phòng có thể chọn người chơi trong danh sách bạn bè trực tuyến của tài khoản hoặc gửi mã phòng/liên kết mời trực tiếp qua các nền tảng mạng xã hội. Khi bạn bè bấm chấp nhận lời mời, họ sẽ lập tức được xếp vào phòng chờ, hệ thống tự động trừ đi số lượng slot trống tương ứng và đồng bộ danh sách thành viên thời gian thực mà không cần qua bộ lọc quét tự động của hệ thống.

Luồng thay thế (Phòng riêng tư): Chủ phòng có thể cấu hình phòng sang chế độ Riêng tư. Ở chế độ này, phòng sẽ không hiển thị trên danh sách tìm kiếm chung của hệ thống. Thay vào đó, một liên kết mã hóa và một mã vùng phòng sẽ được cấp để chủ phòng chủ động gửi riêng cho bạn bè của mình vào chơi, bỏ qua các điều kiện lọc người tự động.

Tình huống ngoại lệ:

Nếu điểm uy tín của chủ phòng nằm dưới ngưỡng quy định do các vi phạm trước đó, hệ thống từ chối quyền tạo phòng và thông báo thời gian bị hạn chế.

Nếu số lượng người chơi (bao gồm chủ phòng và bạn bè được mời trực tiếp) vượt quá giới hạn sức chứa tối đa của các bàn trống hiện có tại quán cafe vào khung giờ đó, hệ thống sẽ từ chối lệnh mời hoặc lệnh tạo phòng, đồng thời cảnh báo yêu cầu đổi quán hoặc đổi sang một tựa game khác cần ít diện tích bàn hơn.

Nếu quán cafe được chọn đã hết chỗ hoặc không có bàn vật lý nào đáp ứng được số lượng người tối đa của tựa game yêu cầu vào khung giờ đó, hệ thống sẽ cảnh báo yêu cầu đổi quán hoặc đổi sang một tựa game khác cần ít diện tích bàn hơn.

Tạo danh sách các API cần thiết cho tính năng mời bạn bè

Xác định cấu trúc bảng dữ liệu lưu trữ thông tin phòng chờ

Viết kịch bản kiểm thử cho tình huống mời bạn bè vượt quá số chỗ của bàn

III. QUY TRÌNH CAM KẾT VÀ KIỂM SOÁT VẮNG MẶT
1. Nghiệp vụ Đặt cọc giữ phòng
Luồng thông thường: Khi phòng đã đủ người và bị khóa, hệ thống yêu cầu tất cả các thành viên phải thực hiện đặt cọc một khoản tiền cam kết trong vòng 5 phút. Khi người cuối cùng hoàn tất đóng cọc, lịch hẹn được xác nhận chính thức. Một mã xác thực đặt chỗ duy nhất được gửi về ứng dụng của tất cả thành viên, đồng thời trạng thái bàn vật lý tại quán cafe chuyển sang chế độ đã đặt lịch cố định.

Tình huống ngoại lệ: Nếu quá 5 phút quy định mà có bất kỳ thành viên nào không hoàn tất việc đặt cọc, hệ thống tự động hủy toàn bộ phòng chơi. Khoản tiền cọc của những người đã đóng trước đó được hoàn trả đầy đủ. Thành viên không thực hiện nghĩa vụ đóng cọc đúng hạn sẽ bị hệ thống tự động trừ điểm uy tín cá nhân.

2. Nghiệp vụ Kiểm soát thời gian đến (Xử lý No-Show)
Luồng thông thường: Nhóm người chơi di chuyển đến quán đúng giờ hẹn và xuất trình mã xác thực đặt chỗ trên điện thoại cho nhân viên tại quầy để làm thủ tục nhận bàn.

Tình huống ngoại lệ (Vắng mặt hoàn toàn): Thời gian giữ bàn tối đa tại quán là 1 tiếng kể từ giờ hẹn trên lịch. Nếu quá thời hạn này mà nhóm khách vẫn chưa có mặt để thực hiện thủ tục nhận bàn tại quầy, hệ thống tự động hủy lịch đặt, giải phóng bàn vật lý tại quán về trạng thái trống, tịch thu toàn bộ số tiền cọc của căn phòng đó để bồi thường thiệt hại cho quán cafe, đồng thời trừ điểm uy tín nặng đối với tất cả thành viên trong phòng.

IV. VẬN HÀNH TẠI BÀN VÀ KIỂM SOÁT KHO BOARD GAME
1. Nghiệp vụ Khớp số lượng người và Nhận bàn
Luồng thông thường: Khi nhân viên quét mã xác thực đặt chỗ, hệ thống hiển thị danh sách thành viên đăng ký. Nhân viên kiểm đếm số người thực tế có mặt. Nếu đủ người, nhân viên xác nhận trên hệ thống quầy. Trạng thái bàn chuyển sang chế độ đang sử dụng, hệ thống bắt đầu tính giờ chơi tự động dựa trên thời gian thực và khoản tiền đặt cọc trước đó của người chơi được chuyển thành điểm trừ trực tiếp vào hóa đơn cuối cùng. Nhân viên bàn giao hộp game chính thức cho nhóm chơi.

Luồng thay thế (Thiếu người thực tế): Nếu số lượng người đến thực tế ít hơn danh sách đăng ký trực tuyến:

Nhân viên ghi nhận số lượng thực tế có mặt. Những thành viên không đến đúng hẹn sẽ bị hệ thống đánh dấu vắng mặt, hủy tiền cọc cá nhân và trừ điểm uy tín.

Hệ thống kiểm tra điều kiện quy định tối thiểu về số người của tựa game đã chọn. Nếu số người thực tế đến quán không đáp ứng đủ (ví dụ: game yêu cầu tối thiểu 7 người nhưng chỉ có 5 người đến), hệ thống quầy sẽ đưa ra cảnh báo không đủ điều kiện chơi và tự động gợi ý danh sách các tựa game thay thế phù hợp với số lượng 5 người hiện tại đang có sẵn trong kho của quán. Nhóm khách chọn game mới, nhân viên cập nhật thông tin và tiến hành mở phiên tính giờ.

2. Nghiệp vụ Trả game và Kiểm kho linh kiện
Luồng thông thường: Sau khi chơi xong, nhóm khách mang hộp game ra quầy để trả và yêu cầu tính tiền. Nhân viên chọn bàn tương ứng trên sơ đồ và bấm lệnh trả game. Màn hình quầy lập tức hiển thị một bảng danh mục kiểm tra chi tiết toàn bộ các cấu phần, linh kiện có trong hộp game đó (số lượng quân bài, xúc xắc, mô hình, token...). Nhân viên kiểm đếm thủ công tại quầy, nếu mọi thứ đầy đủ và nguyên vẹn thì tích chọn hợp lệ để chuyển sang bước thanh toán.

Tình huống ngoại lệ (Mất hoặc hỏng linh kiện): Nếu nhân viên phát hiện một hoặc nhiều chi tiết trong hộp game bị mất hoặc hư hỏng do lỗi của khách hàng, nhân viên sẽ nhập số lượng lỗi tương ứng vào danh mục kiểm tra trên màn hình. Hệ thống sẽ tự động tra cứu bảng quy định giá trị đền bù cấu phần của quán đã thiết lập trước đó, tự động nhân với số lượng lỗi và cộng trực tiếp khoản tiền phạt này thành một mục chi phí bổ sung vào hóa đơn tổng của bàn chơi.

V. QUY TRÌNH THANH TOÁN VÀ ĐÁNH GIÁ CHẤT LƯỢNG KHÁCH HÀNG
1. Nghiệp vụ Tính hóa đơn và Chia tiền tại quầy
Luồng thông thường: Khi quy trình kiểm kho hoàn tất, hệ thống dừng lệnh tính giờ và tính toán hóa đơn tổng theo nguyên tắc: tổng thời gian chơi thực tế nhân với đơn giá khung giờ, cộng thêm phí phạt linh kiện lỗi (nếu có), và trừ đi tổng số tiền cọc hợp lệ của các thành viên có mặt. Nhân viên chọn tính năng chia đều hóa đơn. Hệ thống lấy tổng số tiền chia cho số lượng người chơi thực tế đã điểm danh trước đó và đưa ra con số chính xác cho từng cá nhân. Nhân viên tiến hành thu tiền của từng người theo phần được chia. Sau khi thu đủ 100% hóa đơn, bàn chơi đóng lại và sơ đồ mặt bằng hiển thị trạng thái trống để đón lượt khách tiếp theo.

Tình huống ngoại lệ (Chơi chưa đủ thời gian tối thiểu): Trường hợp nhóm khách trả bàn quá sớm (ví dụ mới chơi 10 phút), hệ thống khi tính tiền sẽ tự động áp dụng quy định về thời lượng chơi tối thiểu của quán (ví dụ làm tròn lên block 30 phút hoặc 1 tiếng tùy quy định) để tính toán chi phí, không tính theo số phút lẻ nhằm bảo đảm chi phí vận hành cho đối tác.

2. Nghiệp vụ Đánh giá chéo và Cập nhật chỉ số hệ thống
Luồng thông thường: Ngay khi hóa đơn tại quầy được thanh toán hoàn tất và đóng phiên chơi, hệ thống phát thông báo yêu cầu thực hiện đánh giá đến ứng dụng di động của tất cả thành viên trong căn phòng đó.

Đánh giá uy tín (Karma): Các người chơi tiến hành tích chọn đánh giá thái độ của những người chơi cùng dựa trên các tiêu chí như: đi đúng giờ, thái độ văn minh, không có hành vi độc hại. Hệ thống tiếp nhận dữ liệu và tự động tính toán để cộng hoặc trừ điểm uy tín trực tiếp vào hồ sơ cá nhân của từng người, làm cơ sở lọc người cho các phiên ghép đội tiếp theo.

Đánh giá thứ hạng (Elo): Đối với các tựa game mang tính thi đấu, đối kháng chiến thuật, ứng dụng hiển thị biểu mẫu nhập kết quả trận đấu (Ai thắng, ai thua, hoặc hòa). Khi các bên xác nhận đồng thuận với kết quả được nhập, hệ thống sẽ tự động tính toán lại điểm thứ hạng để cập nhật vị trí mới của người chơi trên bảng xếp hạng chung. Quy trình nghiệp vụ kết thúc toàn diện.