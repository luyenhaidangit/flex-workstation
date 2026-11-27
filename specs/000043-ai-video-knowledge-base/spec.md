# Đặc tả tính năng: AI Video Knowledge Base

**Branch**: `000043-ai-video-knowledge-base`  
**Ngày tạo**: 2026-11-27  
**Chế độ Spec**: Full  
**Trạng thái**: Bản nháp  
**Ngày reconcile cuối**: Chưa reconcile  
**Người phụ trách**: Claude  
**Stakeholder xác nhận**: Claude  
**Đầu vào**: Xây dựng hệ thống tự động biến kho video trên Google Drive thành kho tri thức có thể đọc, tìm kiếm và hỏi đáp bằng AI mà không cần xem từng video; MVP tập trung vào kết nối Drive, danh sách video, tóm tắt tự động và hiển thị kết quả.

<!-- Lifecycle Trạng thái: Bản nháp (/speckit-specify) -> Đang triển khai (/speckit-implement) -> Hoàn thành (/speckit-converge sau khi 0 gap + Reconcile + Final Specialist Review pass; hoặc sửa tay: Đã thay thế bởi <feature-id>). Spec chỉ mô tả WHY + WHAT; HOW thuộc plan.md. Giữ đủ các đề mục §1–§20; mục không liên quan ghi "Không áp dụng — <lý do ngắn>". -->

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết kỹ thuật (HOW) thuộc về `plan.md`.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:
Tổ chức đang lưu một lượng lớn video (khóa học, họp, hướng dẫn, demo) trên Google Drive. Muốn biết một video nói gì, người dùng phải xem lại từ đầu; muốn tìm một kiến thức nằm ở đâu trong hàng trăm video thì gần như chỉ dựa vào tên file. Kiến thức vì vậy bị "chôn" trong video: tốn thời gian, dễ bỏ sót và không thể tổng hợp xuyên nhiều video.

**Tổng quan tính năng**:
Hệ thống tự động đồng bộ video từ Google Drive, phân tích cả lời nói lẫn nội dung hiển thị trên hình (slide, màn hình thao tác phần mềm), rồi tạo bản tóm tắt có cấu trúc kèm mục lục theo mốc thời gian. Kết quả được lưu thành kho tri thức để người dùng duyệt, tìm kiếm và hỏi đáp xuyên toàn bộ kho video, mỗi câu trả lời dẫn về đúng video và đúng thời điểm gốc. Mỗi phiên bản video chỉ phải phân tích một lần và có thể tra cứu nhiều lần.

---

## 2. Mục tiêu

- **MT-001**: Người dùng nắm được nội dung chính của một video trong vài phút đọc thay vì phải xem toàn bộ video.
- **MT-002**: Người dùng tìm được kiến thức cụ thể trong toàn bộ kho video bằng cách mô tả nội dung, không phụ thuộc tên file, và đi thẳng tới đoạn video chứa kiến thức đó.
- **MT-003**: Chi phí và tiến độ xử lý toàn bộ kho video luôn minh bạch, có thể kiểm soát và không phát sinh xử lý lặp không cần thiết.
- **MT-004**: Nội dung tri thức chỉ hiển thị cho người vẫn còn quyền với video gốc.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Kết nối với Google Drive bằng tài khoản người dùng và lấy danh sách video thuộc các nguồn (thư mục) được chọn.
- **MVP-002**: Tự động tạo bản tóm tắt có cấu trúc cho từng video có quyền tải, gồm cả thông tin từ lời nói và từ hình ảnh.
- **MVP-003**: Màn hình tổng quan và màn hình chi tiết video hiển thị trạng thái xử lý và kết quả tóm tắt.
- **MVP-004**: Mỗi phiên bản video chỉ xử lý một lần; lỗi tạm thời tự thử lại, lỗi quyền được hiển thị riêng.

Các giai đoạn sau MVP (không thuộc v1 nhưng thuộc tầm nhìn của spec): đồng bộ tăng dần tự động liên tục kèm theo dõi chi phí (P2), tìm kiếm và hỏi đáp xuyên kho video (P3), phân loại và tổng hợp tri thức theo chủ đề tự động (P3).

---

## 4. Người dùng & Bối cảnh

- **Người dùng chính**: Nhân sự trong tổ chức (học viên, kỹ sư, quản lý) cần tra cứu kiến thức từ video đã lưu trên Google Drive.
- **Người dùng quản trị**: Người phụ trách kết nối Drive, chọn nguồn video, theo dõi tiến độ và chi phí xử lý.
- **Bối cảnh sử dụng**: Khi cần nắm nhanh nội dung một video, tìm lại kiến thức đã nghe ở đâu đó, hoặc tổng hợp kiến thức về một chủ đề từ nhiều video.
- **Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ (không chuyên kỹ thuật) cho phần duyệt/tìm kiếm; quản trị viên cho phần kết nối và theo dõi chi phí.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Kết nối Google Drive và xem danh sách video (Ưu tiên: P1)

Quản trị viên kết nối tài khoản Google Drive, chọn thư mục chứa video, hệ thống liệt kê các video tìm thấy cùng trạng thái của từng video.

- **Lý do ưu tiên**: Không có nguồn video thì không có gì để phân tích; đây là điểm bắt đầu của mọi luồng.
- **Liên quan yêu cầu**: FR-001, FR-002, FR-003
- **Test độc lập**: Kết nối một tài khoản có sẵn thư mục chứa video và kiểm tra danh sách hiển thị đúng số video, tên, thời lượng, link gốc và trạng thái.

**Acceptance Criteria**:
1. **AC-001**: **Cho trước** quản trị viên chưa kết nối Drive, **Khi** hoàn tất cấp quyền và chọn một thư mục, **Thì** hệ thống liệt kê toàn bộ video trong thư mục đó (kể cả thư mục con) với trạng thái `PENDING`.
2. **AC-002**: **Cho trước** một video mà tài khoản chỉ được xem nhưng không được tải, **Khi** hệ thống kiểm tra quyền, **Thì** video được gắn `ACCESS_DENIED` kèm lý do dễ hiểu và không được đưa vào xử lý.
3. **AC-003**: **Cho trước** người dùng thu hồi quyền kết nối, **Khi** hệ thống cần truy cập Drive, **Thì** hệ thống báo cần kết nối lại và không xử lý thêm video mới.

### US-002 — Đọc bản tóm tắt có cấu trúc của một video (Ưu tiên: P1)

Người dùng mở một video đã phân tích xong và đọc ngay tóm tắt nhanh, tóm tắt đầy đủ, mục lục theo mốc thời gian, kiến thức chính, thẻ, nhóm chủ đề, mức độ, nội dung lời nói và thông tin rút ra từ hình ảnh, kèm link về video gốc.

- **Lý do ưu tiên**: Đây là giá trị cốt lõi người dùng nhận được từ hệ thống.
- **Liên quan yêu cầu**: FR-004, FR-005, FR-006, FR-007, FR-008
- **Test độc lập**: Với một video mẫu có cả lời nói và slide, kiểm tra mọi trường tóm tắt xuất hiện, mốc thời gian trong mục lục dẫn đúng vị trí và thông tin trên slide có mặt trong kết quả.

**Acceptance Criteria**:
1. **AC-004**: **Cho trước** một video đã `COMPLETED`, **Khi** người dùng mở trang chi tiết, **Thì** thấy tóm tắt nhanh (đọc trong khoảng 30 giây), tóm tắt đầy đủ, mục lục có mốc thời gian, kiến thức chính, thẻ, nhóm chủ đề, mức độ (cơ bản/nâng cao), nội dung lời nói, thông tin từ hình ảnh và link Drive gốc.
2. **AC-005**: **Cho trước** một mục trong mục lục, **Khi** người dùng chọn mục đó, **Thì** hệ thống dẫn tới đúng vị trí thời gian trong video gốc.
3. **AC-006**: **Cho trước** một video mà người nói chỉ tham chiếu "như trên màn hình" mà không đọc nội dung, **Khi** video được phân tích, **Thì** nội dung hiển thị trên màn hình/slide vẫn xuất hiện trong thông tin từ hình ảnh của bản tóm tắt.
4. **AC-007**: **Cho trước** một video dài, **Khi** được tóm tắt, **Thì** bản tóm tắt bao quát được các phần đầu, giữa và cuối của video, không chỉ phần đầu.

### US-003 — Theo dõi tiến độ xử lý và xử lý lỗi (Ưu tiên: P1)

Quản trị viên xem tổng số video, số đã hoàn thành, đang xử lý, bị lỗi và trạng thái chi tiết của từng video; lỗi tạm thời tự thử lại, lỗi quyền được tách riêng để xử lý.

- **Lý do ưu tiên**: Kho video lớn cần biết tiến độ và biết video nào chưa dùng được, nếu không hệ thống thành "hộp đen".
- **Liên quan yêu cầu**: FR-009, FR-010, FR-011
- **Test độc lập**: Đưa vào một lô video gồm video bình thường, video không có quyền tải và video hỏng; kiểm tra trạng thái cuối của từng video và số liệu tổng hợp.

**Acceptance Criteria**:
1. **AC-008**: **Cho trước** một lô video đang được xử lý, **Khi** quản trị viên mở màn hình tổng quan, **Thì** thấy tổng số video và số lượng theo từng trạng thái (`PENDING`, `DOWNLOADING`, `PROCESSING`, `SUMMARIZING`, `INDEXING`, `COMPLETED`, `FAILED`, `ACCESS_DENIED`).
2. **AC-009**: **Cho trước** một video gặp lỗi tạm thời (mạng, dịch vụ AI quá tải), **Khi** hệ thống xử lý, **Thì** video được thử lại tự động theo số lần giới hạn và chỉ chuyển `FAILED` khi hết lượt thử.
3. **AC-010**: **Cho trước** một video `FAILED` hoặc `ACCESS_DENIED`, **Khi** quản trị viên xem chi tiết, **Thì** thấy nguyên nhân dễ hiểu và có thể yêu cầu xử lý lại sau khi đã khắc phục.

### US-004 — Đồng bộ tăng dần, không xử lý lặp (Ưu tiên: P2)

Khi có video mới, video được thay nội dung hoặc chỉ đổi tên trên Drive, hệ thống tự phát hiện và chỉ xử lý phần thật sự cần xử lý.

- **Lý do ưu tiên**: Tránh tốn chi phí AI lặp và giữ kho tri thức luôn cập nhật mà không cần thao tác thủ công.
- **Liên quan yêu cầu**: FR-012, FR-013, FR-014
- **Test độc lập**: Thêm một video mới, đổi tên một video cũ và thay nội dung một video khác; kiểm tra chỉ video mới và video đổi nội dung được phân tích lại.

**Acceptance Criteria**:
1. **AC-011**: **Cho trước** kho đã đồng bộ, **Khi** có video mới xuất hiện trong nguồn đã chọn, **Thì** video đó được phát hiện và xử lý mà không cần quét lại toàn bộ kho.
2. **AC-012**: **Cho trước** một video đã `COMPLETED`, **Khi** video chỉ bị đổi tên hoặc di chuyển thư mục, **Thì** hệ thống chỉ cập nhật thông tin hiển thị và KHÔNG phân tích lại bằng AI.
3. **AC-013**: **Cho trước** một video đã `COMPLETED`, **Khi** nội dung video bị thay bằng phiên bản khác, **Thì** hệ thống phân tích lại phiên bản mới và giữ rõ đây là kết quả của phiên bản nào.
4. **AC-014**: **Cho trước** cùng một video bị kích hoạt xử lý nhiều lần, **Khi** các yêu cầu trùng nhau, **Thì** chỉ một lần xử lý được thực hiện.

### US-005 — Chỉ người có quyền mới xem được tri thức (Ưu tiên: P2)

Người dùng chỉ xem được bản tóm tắt, transcript và kết quả tìm kiếm của những video mà họ vẫn còn quyền truy cập trên Drive.

- **Lý do ưu tiên**: Bản tóm tắt chứa nội dung của video gốc; để lộ cho người không có quyền là rò rỉ dữ liệu.
- **Liên quan yêu cầu**: FR-015, FR-016, SEC-001, SEC-002
- **Test độc lập**: Dùng hai tài khoản, một có quyền một không có quyền với cùng video; kiểm tra tài khoản không quyền không thấy video ở danh sách, chi tiết và kết quả tìm kiếm.

**Acceptance Criteria**:
1. **AC-015**: **Cho trước** người dùng không có quyền với video gốc trên Drive, **Khi** truy cập trang chi tiết hoặc tìm kiếm, **Thì** video và nội dung của nó không xuất hiện.
2. **AC-016**: **Cho trước** người dùng từng có quyền nhưng bị thu hồi, **Khi** họ truy cập lại, **Thì** không còn xem được nội dung video đó.

### US-006 — Theo dõi chi phí AI (Ưu tiên: P2)

Quản trị viên xem chi phí AI đã phát sinh theo video và theo kỳ, đặt giới hạn để tránh vượt ngân sách.

- **Lý do ưu tiên**: Chi phí tỉ lệ với tổng thời lượng video; không kiểm soát được thì có thể vượt ngân sách khi xử lý cả kho.
- **Liên quan yêu cầu**: FR-017, FR-018
- **Test độc lập**: Xử lý một lô video nhỏ và đối chiếu chi phí ghi nhận với mức sử dụng thực tế; đặt giới hạn thấp và kiểm tra hệ thống dừng nhận xử lý mới khi chạm giới hạn.

**Acceptance Criteria**:
1. **AC-017**: **Cho trước** các video đã xử lý, **Khi** quản trị viên xem báo cáo chi phí, **Thì** thấy chi phí theo từng video, tổng theo kỳ và chi phí trung bình trên một giờ video.
2. **AC-018**: **Cho trước** quản trị viên đã đặt giới hạn chi phí, **Khi** chi phí đạt giới hạn, **Thì** hệ thống ngừng nhận video mới vào xử lý và báo rõ lý do; video đang xử lý dở được hoàn tất hoặc tạm dừng có thông báo.

### US-007 — Tìm kiếm trong toàn bộ kho video (Ưu tiên: P3)

Người dùng gõ từ khóa hoặc mô tả nội dung và nhận danh sách video/đoạn video liên quan, kể cả khi cách diễn đạt khác với nội dung gốc.

- **Lý do ưu tiên**: Giá trị lớn nhất khi kho có hàng trăm video, nhưng cần dữ liệu tóm tắt có sẵn trước.
- **Liên quan yêu cầu**: FR-019, FR-020
- **Test độc lập**: Với tập video mẫu, tìm bằng từ khóa chính xác và bằng mô tả đồng nghĩa; kiểm tra đúng video và đúng đoạn thời gian xuất hiện trong kết quả.

**Acceptance Criteria**:
1. **AC-019**: **Cho trước** kho có nhiều video đã `COMPLETED`, **Khi** người dùng tìm bằng từ khóa có trong nội dung, **Thì** kết quả gồm các video/đoạn liên quan kèm mốc thời gian.
2. **AC-020**: **Cho trước** người dùng mô tả bằng cách diễn đạt khác với lời nói gốc, **Khi** tìm kiếm, **Thì** vẫn nhận được các đoạn có ý nghĩa tương ứng.
3. **AC-021**: **Cho trước** nội dung chỉ xuất hiện trên hình (slide, màn hình) chứ không được nói ra, **Khi** tìm kiếm, **Thì** vẫn có thể tìm thấy.

### US-008 — Hỏi đáp AI xuyên toàn bộ kho video (Ưu tiên: P3)

Người dùng đặt câu hỏi bằng ngôn ngữ tự nhiên và nhận câu trả lời tổng hợp từ nhiều video, kèm nguồn video và mốc thời gian để kiểm chứng.

- **Lý do ưu tiên**: Biến kho video thành thư viện tri thức hỏi đáp được, nhưng phụ thuộc vào tìm kiếm và dữ liệu đã có.
- **Liên quan yêu cầu**: FR-021, FR-022, FR-023
- **Test độc lập**: Đặt câu hỏi có đáp án nằm ở hai video khác nhau và một câu hỏi không có đáp án trong kho; kiểm tra câu trả lời dẫn đúng nguồn và hệ thống thừa nhận khi không tìm thấy.

**Acceptance Criteria**:
1. **AC-022**: **Cho trước** câu hỏi mà đáp án nằm ở nhiều video, **Khi** người dùng gửi câu hỏi, **Thì** câu trả lời tổng hợp từ các video đó và nêu rõ từng nguồn video cùng mốc thời gian.
2. **AC-023**: **Cho trước** câu hỏi không có thông tin trong kho, **Khi** người dùng gửi câu hỏi, **Thì** hệ thống nói rõ không tìm thấy thông tin thay vì tự bịa câu trả lời.
3. **AC-024**: **Cho trước** người dùng chỉ có quyền với một phần video, **Khi** hỏi đáp, **Thì** câu trả lời và nguồn dẫn chỉ lấy từ các video họ có quyền xem.

### US-009 — Phân loại và tổng hợp tri thức theo chủ đề (Ưu tiên: P3)

Hệ thống tự gom video vào nhóm chủ đề, gắn thẻ nhất quán và phát hiện nội dung trùng lặp giữa các video.

- **Lý do ưu tiên**: Giúp duyệt kho lớn theo chủ đề, nhưng chỉ có giá trị khi kho đã đủ lớn và đã có tri thức nền.
- **Liên quan yêu cầu**: FR-024, FR-025
- **Test độc lập**: Với tập video thuộc vài chủ đề đã biết, kiểm tra video được gom đúng nhóm và các cặp video trùng nội dung được đánh dấu.

**Acceptance Criteria**:
1. **AC-025**: **Cho trước** kho có video thuộc nhiều chủ đề, **Khi** người dùng duyệt theo nhóm chủ đề, **Thì** mỗi video xuất hiện trong nhóm phù hợp với nội dung của nó.
2. **AC-026**: **Cho trước** hai video có nội dung phần lớn giống nhau, **Khi** hệ thống tổng hợp, **Thì** chúng được đánh dấu là có nội dung trùng lặp để người dùng cân nhắc.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Thư mục không chứa video hoặc chưa có video nào `COMPLETED` thì hiển thị trạng thái trống kèm hướng dẫn kết nối/chọn nguồn; hỏi đáp trả lời rõ là kho chưa có nội dung.
- **Dữ liệu không hợp lệ**: File không phải video, video hỏng hoặc không đọc được thì gắn `FAILED` kèm lý do; video không có lời nói (chỉ hình) hoặc không có hình (chỉ tiếng) vẫn được tóm tắt từ phần có sẵn; video quá ngắn hoặc im lặng toàn bộ được ghi nhận là "không có nội dung đáng tóm tắt".
- **Không có quyền**: Không được tải video → `ACCESS_DENIED`; quyền kết nối bị thu hồi → yêu cầu kết nối lại; người dùng mất quyền với video gốc → không thấy nội dung video đó.
- **Lỗi hệ thống / Timeout**: Dịch vụ AI hoặc Drive lỗi tạm thời được thử lại có giới hạn; hết lượt thử thì `FAILED` và cho phép xử lý lại thủ công. Lỗi ở một video không làm dừng các video khác.
- **Xung đột / Thao tác lặp lại**: Cùng một video bị kích hoạt nhiều lần chỉ xử lý một lần; hai lần đồng bộ chạy chồng nhau không tạo bản ghi trùng; video đổi nội dung giữa lúc đang xử lý thì kết quả cũ bị loại bỏ và xử lý lại theo phiên bản mới.
- **Trường hợp biên khác**: Video rất dài (nhiều giờ); video nhiều ngôn ngữ; video bị xóa hoặc chuyển vào thùng rác trên Drive sau khi đã phân tích (nội dung tri thức không còn hiển thị cho người dùng); thư mục chia sẻ chung nhiều người sở hữu; chạm giới hạn chi phí giữa chừng.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

<!-- Mỗi FR phải kiểm thử được, dùng PHẢI / KHÔNG ĐƯỢC và trace về US/AC. -->

- **FR-001** `[P1]`: Hệ thống PHẢI cho phép quản trị viên kết nối tài khoản Google Drive thông qua cơ chế cấp quyền của Google và chọn một hoặc nhiều thư mục làm nguồn video. *(Liên quan: US-001, AC-001, AC-003)*
- **FR-002** `[P1]`: Hệ thống PHẢI liệt kê video trong các nguồn đã chọn (kể cả thư mục con) kèm tên, thời lượng, ngày cập nhật, link Drive gốc và trạng thái xử lý. *(Liên quan: US-001, AC-001)*
- **FR-003** `[P1]`: Hệ thống PHẢI kiểm tra quyền tải của từng video trước khi xử lý và gắn `ACCESS_DENIED` kèm lý do khi không được phép. *(Liên quan: US-001, AC-002)*
- **FR-004** `[P1]`: Hệ thống PHẢI tạo cho mỗi video đã xử lý một bộ thông tin gồm: tóm tắt nhanh, tóm tắt đầy đủ, mục lục theo mốc thời gian, kiến thức chính, thẻ, nhóm chủ đề, mức độ, transcript, link Drive gốc và thông tin rút ra từ hình ảnh. *(Liên quan: US-002, AC-004)*
- **FR-005** `[P1]`: Hệ thống PHẢI phân tích cả lời nói và nội dung hiển thị trên hình (slide, màn hình thao tác, văn bản trên hình) khi tạo tóm tắt. *(Liên quan: US-002, AC-006)*
- **FR-006** `[P1]`: Hệ thống PHẢI gắn mốc thời gian cho transcript và mục lục để người dùng truy ngược tới đúng vị trí trong video gốc. *(Liên quan: US-002, AC-004, AC-005)*
- **FR-007** `[P1]`: Hệ thống PHẢI tóm tắt bao quát toàn bộ video dài, không bỏ sót các phần giữa và cuối. *(Liên quan: US-002, AC-007)*
- **FR-008** `[P1]`: Hệ thống PHẢI cho biết bản tóm tắt thuộc phiên bản nội dung video nào của Drive. *(Liên quan: US-002, AC-013)*
- **FR-009** `[P1]`: Hệ thống PHẢI theo dõi từng video qua các trạng thái `PENDING`, `DOWNLOADING`, `PROCESSING`, `SUMMARIZING`, `INDEXING`, `COMPLETED`, `FAILED`, `ACCESS_DENIED` và hiển thị trạng thái hiện tại cùng số liệu tổng hợp. *(Liên quan: US-003, AC-008)*
- **FR-010** `[P1]`: Hệ thống PHẢI tự động thử lại có giới hạn khi gặp lỗi tạm thời và chỉ chuyển `FAILED` khi hết lượt thử; lỗi quyền KHÔNG ĐƯỢC thử lại tự động. *(Liên quan: US-003, AC-009)*
- **FR-011** `[P1]`: Hệ thống PHẢI hiển thị nguyên nhân dễ hiểu cho video `FAILED`/`ACCESS_DENIED` và cho phép quản trị viên yêu cầu xử lý lại. *(Liên quan: US-003, AC-010)*
- **FR-012** `[P2]`: Hệ thống PHẢI phát hiện video mới hoặc video thay đổi trong nguồn đã chọn mà không cần quét lại toàn bộ kho. *(Liên quan: US-004, AC-011)*
- **FR-013** `[P2]`: Hệ thống PHẢI xác định một video "đã xử lý" theo định danh file trên Drive kết hợp với phiên bản nội dung; cùng định danh và cùng phiên bản thì KHÔNG ĐƯỢC phân tích lại. *(Liên quan: US-004, AC-012, AC-014)*
- **FR-014** `[P2]`: Hệ thống PHẢI chỉ cập nhật thông tin hiển thị (tên, vị trí) khi video đổi tên/di chuyển và PHẢI phân tích lại khi nội dung đổi. *(Liên quan: US-004, AC-012, AC-013)*
- **FR-015** `[P2]`: Hệ thống PHẢI chỉ hiển thị cho người dùng các video, tóm tắt, transcript và kết quả tìm kiếm của những video mà họ có quyền truy cập trên Drive. *(Liên quan: US-005, AC-015)*
- **FR-016** `[P2]`: Hệ thống PHẢI ngừng hiển thị nội dung video đối với người dùng khi quyền của họ bị thu hồi hoặc video bị xóa khỏi Drive. *(Liên quan: US-005, AC-016)*
- **FR-017** `[P2]`: Hệ thống PHẢI ghi nhận chi phí AI cho từng video và báo cáo theo video, theo kỳ và trung bình trên một giờ video. *(Liên quan: US-006, AC-017)*
- **FR-018** `[P2]`: Hệ thống PHẢI cho quản trị viên đặt giới hạn chi phí theo kỳ và PHẢI ngừng nhận video mới vào xử lý khi chạm giới hạn. *(Liên quan: US-006, AC-018)*
- **FR-019** `[P3]`: Hệ thống PHẢI cho phép tìm kiếm trong toàn bộ kho theo từ khóa và theo ý nghĩa, trả về video/đoạn liên quan kèm mốc thời gian. *(Liên quan: US-007, AC-019, AC-020)*
- **FR-020** `[P3]`: Hệ thống PHẢI đưa cả nội dung rút ra từ hình ảnh vào phạm vi tìm kiếm. *(Liên quan: US-007, AC-021)*
- **FR-021** `[P3]`: Hệ thống PHẢI trả lời câu hỏi ngôn ngữ tự nhiên bằng cách tổng hợp từ các video liên quan trong kho và nêu rõ nguồn video cùng mốc thời gian. *(Liên quan: US-008, AC-022)*
- **FR-022** `[P3]`: Hệ thống PHẢI nói rõ khi kho không có thông tin để trả lời và KHÔNG ĐƯỢC đưa ra câu trả lời không có nguồn trong kho. *(Liên quan: US-008, AC-023)*
- **FR-023** `[P3]`: Hệ thống PHẢI giới hạn nguồn của câu trả lời trong các video mà người hỏi có quyền xem. *(Liên quan: US-008, AC-024)*
- **FR-024** `[P3]`: Hệ thống PHẢI tự gán nhóm chủ đề và thẻ nhất quán cho video và cho phép duyệt kho theo nhóm. *(Liên quan: US-009, AC-025)*
- **FR-025** `[P3]`: Hệ thống PHẢI phát hiện và đánh dấu các video có nội dung trùng lặp đáng kể. *(Liên quan: US-009, AC-026)*
- **FR-026** `[P1]`: Hệ thống KHÔNG ĐƯỢC lưu giữ lâu dài bản sao file video gốc; chỉ giữ dữ liệu cần thiết để tạo và phục vụ tri thức. *(Liên quan: US-002, SEC-002)*

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mỗi cặp (video, phiên bản nội dung) chỉ được phân tích bằng AI tối đa một lần thành công; phân tích lại chỉ xảy ra khi nội dung thay đổi hoặc quản trị viên yêu cầu xử lý lại.
- **BR-002**: Video chỉ được đưa vào xử lý khi tài khoản kết nối có quyền tải video đó.
- **BR-003**: Quyền xem tri thức luôn kế thừa từ quyền truy cập video gốc trên Drive, không tạo hệ thống quyền riêng tách rời.
- **BR-004**: Lỗi tạm thời được thử lại có giới hạn; lỗi quyền và dữ liệu không hợp lệ không thử lại tự động.
- **BR-005**: Khi chạm giới hạn chi phí, hệ thống dừng nhận video mới và thông báo cho quản trị viên; không tự nâng giới hạn.
- **BR-006**: Mọi nhận định trong bản tóm tắt và câu trả lời hỏi đáp phải truy ngược được về video và mốc thời gian nguồn.
- **BR-007**: Đổi tên hoặc di chuyển video không làm mất kết quả đã phân tích.

**Luồng trạng thái**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa tồn tại | Phát hiện video | `PENDING` | Video nằm trong nguồn đã chọn |
| `PENDING` | Kiểm tra quyền tải | `ACCESS_DENIED` | Không có quyền tải |
| `PENDING` | Bắt đầu lấy nội dung | `DOWNLOADING` | Có quyền tải và còn trong giới hạn chi phí |
| `DOWNLOADING` | Lấy xong nội dung | `PROCESSING` | Lấy thành công |
| `PROCESSING` | Phân tích lời nói và hình ảnh xong | `SUMMARIZING` | Phân tích thành công |
| `SUMMARIZING` | Tổng hợp xong | `INDEXING` | Tóm tắt thành công |
| `INDEXING` | Lập chỉ mục xong | `COMPLETED` | Kết quả đã sẵn sàng tra cứu |
| `DOWNLOADING`, `PROCESSING`, `SUMMARIZING`, `INDEXING` | Gặp lỗi tạm thời | Giữ bước hiện tại và thử lại | Còn lượt thử |
| `DOWNLOADING`, `PROCESSING`, `SUMMARIZING`, `INDEXING` | Gặp lỗi hoặc hết lượt thử | `FAILED` | Hết lượt thử hoặc lỗi không khắc phục tự động |
| `FAILED`, `ACCESS_DENIED` | Quản trị viên yêu cầu xử lý lại | `PENDING` | Nguyên nhân đã được khắc phục |
| `COMPLETED` | Nội dung video đổi | `PENDING` | Phiên bản nội dung mới |

---

## 9. Thực thể dữ liệu

<!-- Chỉ nêu ý nghĩa nghiệp vụ và quan hệ; không ghi bảng DB, kiểu cột hay payload API. -->

- **Kết nối Drive**: Liên kết giữa tổ chức và một tài khoản Google Drive đã cấp quyền; có trạng thái còn hiệu lực hoặc cần kết nối lại.
- **Nguồn video**: Thư mục trên Drive được chọn để đồng bộ; một kết nối có nhiều nguồn.
- **Video**: Một file video trên Drive; có thông tin hiển thị (tên, thời lượng, vị trí, link gốc), quyền tải và trạng thái xử lý; thuộc một nguồn.
- **Phiên bản video**: Một trạng thái nội dung cụ thể của video; mỗi video có một hoặc nhiều phiên bản và mỗi phiên bản có tối đa một kết quả tri thức hiện hành.
- **Công việc xử lý**: Một lần xử lý cho một phiên bản video, ghi nhận tiến độ, số lần thử lại và nguyên nhân lỗi.
- **Transcript**: Toàn bộ lời nói của một phiên bản video, chia thành các đoạn có mốc thời gian.
- **Thông tin hình ảnh**: Nội dung quan trọng trên hình (slide, màn hình, văn bản) kèm mốc thời gian.
- **Bản tóm tắt**: Gồm tóm tắt nhanh, tóm tắt đầy đủ, mục lục theo mốc thời gian, kiến thức chính, mức độ; gắn với một phiên bản video.
- **Thẻ & Nhóm chủ đề**: Nhãn phân loại dùng chung cho nhiều video.
- **Đoạn tri thức**: Một đoạn nội dung nhỏ (từ transcript, hình ảnh hoặc tóm tắt) phục vụ tìm kiếm và hỏi đáp, luôn truy ngược được về video và mốc thời gian.
- **Bản ghi chi phí AI**: Chi phí AI phát sinh cho mỗi lần xử lý, theo video và kỳ; có thể đối chiếu với giới hạn chi phí.
- **Giới hạn chi phí**: Ngưỡng chi phí do quản trị viên đặt theo kỳ.

---

## 10. Phân quyền & Bảo mật

- **Ai được xem / thao tác**: Quản trị viên kết nối Drive, chọn nguồn, theo dõi tiến độ, chi phí và yêu cầu xử lý lại. Người dùng thường xem tóm tắt, tìm kiếm và hỏi đáp trên các video họ có quyền truy cập trên Drive.
- **Ai bị chặn**: Người dùng không có quyền với video gốc không xem được nội dung video đó dưới bất kỳ hình thức nào (danh sách, chi tiết, kết quả tìm kiếm, câu trả lời, nguồn dẫn).
- **Dữ liệu nhạy cảm**: Có — nội dung video có thể chứa thông tin nội bộ; thông tin xác thực kết nối Drive là dữ liệu nhạy cảm cần được bảo vệ.
- **SEC-001**: Hệ thống PHẢI kiểm tra quyền và phạm vi dữ liệu trước khi thực hiện thao tác, kể cả tìm kiếm và hỏi đáp.
- **SEC-002**: Hệ thống PHẢI loại bỏ nội dung khỏi tầm nhìn của người dùng ngay khi quyền với video gốc không còn hiệu lực.
- **SEC-003**: Thông tin xác thực kết nối Drive PHẢI được bảo vệ, KHÔNG ĐƯỢC hiển thị hoặc ghi vào nhật ký dưới dạng đọc được.
- **SEC-004**: Hệ thống CHỈ xin quyền truy cập Drive ở mức tối thiểu cần để đọc video và quyền thư mục, KHÔNG ĐƯỢC xin quyền ghi hoặc xóa.

---

## 11. Audit & Lịch sử thay đổi

- **Có cần audit không**: Có. Cần ghi lại: ai (quản trị viên/người dùng), thao tác gì (kết nối/ngắt kết nối Drive, thêm/bỏ nguồn, yêu cầu xử lý lại, đặt/đổi giới hạn chi phí), thời điểm, giá trị trước/sau của giới hạn chi phí và nguồn video, lý do khi có. Lịch sử xử lý từng video (trạng thái, số lần thử, nguyên nhân lỗi) phải xem lại được.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Một video được xử lý xong và có thể đọc trong khoảng thời gian hợp lý so với thời lượng video; cụ thể, 90% video thời lượng dưới 60 phút hoàn tất (`COMPLETED`) trong vòng 30 phút kể từ khi bắt đầu xử lý.
- **NFR-002**: Màn hình danh sách và chi tiết video phản hồi trong vòng 3 giây cho kho tới 2.000 video.
- **NFR-003**: Hệ thống chịu được việc xử lý hàng loạt: lỗi ở một video không làm ngừng các video khác; việc khởi động lại hệ thống không làm mất tiến độ hay xử lý trùng.
- **NFR-004**: Tìm kiếm và hỏi đáp (P3) trả kết quả đầu tiên trong vòng 10 giây cho kho tới 2.000 video.

---

## 13. Tiêu chí thành công *(bắt buộc)*

<!-- Đo lường được, không phụ thuộc công nghệ (không nêu framework/DB/API latency nội bộ). -->

- **SC-001**: Quản trị viên kết nối Drive, chọn thư mục và thấy danh sách video đầu tiên trong vòng 5 phút kể từ lúc bắt đầu.
- **SC-002**: Người dùng nắm được nội dung chính của một video 60 phút bằng việc đọc phần tóm tắt trong không quá 5 phút.
- **SC-003**: Trong bộ video mẫu đại diện (khoảng 20–30 video), người đánh giá xác nhận tóm tắt đã bao quát ít nhất 90% ý chính và các mốc thời gian trong mục lục sai lệch không quá 30 giây so với thực tế.
- **SC-004**: Với video có nội dung quan trọng chỉ xuất hiện trên hình, ít nhất 80% nội dung đó có mặt trong bản tóm tắt hoặc thông tin hình ảnh theo đánh giá của người xem mẫu.
- **SC-005**: 100% video có quyền tải và không bị lỗi được xử lý xong mà không cần can thiệp thủ công; 100% lỗi quyền được hiển thị đúng và tách khỏi lỗi hệ thống.
- **SC-006**: Không có video nào bị phân tích bằng AI hai lần cho cùng một phiên bản nội dung, kể cả khi bị kích hoạt trùng hoặc chỉ đổi tên.
- **SC-007**: 100% các lần kiểm thử với tài khoản không có quyền cho thấy không rò rỉ nội dung video (danh sách, chi tiết, tìm kiếm, hỏi đáp).
- **SC-008**: Chi phí AI thực tế trên mỗi giờ video nằm trong ngân sách mà tổ chức đặt ra sau đợt đánh giá bộ video mẫu và quản trị viên xem được chi phí theo từng video.
- **SC-009**: Với tập câu hỏi mẫu, ít nhất 85% câu trả lời hỏi đáp (P3) dẫn đúng video và mốc thời gian chứa thông tin, và 100% câu hỏi ngoài kho được từ chối trả lời thay vì bịa đáp án.

---

## 14. Giả định & Ràng buộc

- **Giả định**:
  - Tổ chức dùng một hoặc vài tài khoản Google (cá nhân hoặc Workspace) làm nơi lưu video; quản trị viên có quyền đọc các thư mục cần đồng bộ.
  - Phần lớn video là tiếng Việt hoặc tiếng Anh; video nhiều ngôn ngữ được hỗ trợ ở mức tốt nhất có thể.
  - Quy mô ban đầu từ vài trăm đến vài nghìn video, thời lượng từ vài phút đến vài giờ.
  - Người dùng cuối đăng nhập bằng cùng danh tính Google đang dùng trên Drive để việc kiểm tra quyền khớp với quyền thực tế trên Drive.
  - Phụ đề hoặc transcript có sẵn (SRT/VTT) được ưu tiên dùng khi có; nếu không thì hệ thống tự tạo transcript.
  - Chi phí AI được chấp nhận ở mức vận hành thường xuyên; ngân sách cụ thể do tổ chức đặt qua giới hạn chi phí.
  - Một bộ video mẫu 20–30 video sẽ được dùng để đánh giá chất lượng và chi phí trước khi xử lý toàn bộ kho.
- **Ràng buộc**:
  - Quyền xem video không đồng nghĩa với quyền tải; chỉ video có quyền tải mới được phân tích.
  - Nội dung video có thể nhạy cảm; hệ thống không lưu giữ lâu dài bản sao video gốc.
  - Kết quả AI có thể sai sót; người dùng luôn có đường dẫn về video và mốc thời gian gốc để kiểm chứng.

---

## 15. Ngoài phạm vi

- Chỉnh sửa, cắt ghép hoặc tạo video mới.
- Phân tích video ngoài Google Drive (YouTube, mạng nội bộ, ổ đĩa cục bộ, nền tảng khác).
- Phát video trong ứng dụng thay cho trình phát của Drive (MVP chỉ dẫn link và mốc thời gian).
- Nhận diện khuôn mặt, phân biệt người nói theo danh tính cá nhân.
- Dịch tự động nội dung giữa các ngôn ngữ.
- Quản lý phân quyền riêng tách rời quyền trên Drive.
- Tìm kiếm, hỏi đáp và phân loại tự động ở phiên bản v1 (thuộc các giai đoạn sau MVP).
- Xử lý theo thời gian thực/livestream.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp giảm thiểu |
|--------|----------|----------|----------------------|
| Chi phí AI vượt ngân sách khi xử lý cả kho | Trung | Cao | Giới hạn chi phí, theo dõi chi phí từng video, đánh giá trước trên bộ video mẫu |
| Tóm tắt thiếu hoặc sai ý, bỏ sót nội dung trên hình | Trung | Cao | Đánh giá chất lượng trên bộ video mẫu, luôn dẫn mốc thời gian để kiểm chứng, phản hồi từ người dùng |
| Rò rỉ nội dung cho người không có quyền | Thấp | Cao | Kiểm tra quyền ở mọi điểm truy cập, loại nội dung khi quyền thu hồi, kiểm thử bằng nhiều tài khoản |
| Video không cho tải hoặc quyền bị thu hồi giữa chừng | Cao | Trung | Kiểm tra quyền tải trước, gắn `ACCESS_DENIED` rõ ràng, hướng dẫn khắc phục |
| Video rất dài hoặc chất lượng âm thanh kém làm kết quả thấp | Trung | Trung | Tóm tắt phân tầng cho video dài, ghi nhận mức tin cậy, cho phép xử lý lại |
| Hạn mức/giới hạn của Drive hoặc dịch vụ AI làm chậm xử lý hàng loạt | Trung | Trung | Giới hạn số video xử lý song song, thử lại có kiểm soát, hiển thị tiến độ |
| Thông tin nhạy cảm trong video bị gửi tới dịch vụ AI bên ngoài | Trung | Cao | Cho phép tổ chức chọn nguồn được xử lý, ghi rõ chính sách dữ liệu, kiểm soát nguồn ở mức thư mục |

---

## 17. Phụ thuộc

- Tài khoản Google Drive có quyền đọc và tải video của các thư mục cần đồng bộ.
- Dịch vụ AI có khả năng hiểu lời nói và hình ảnh trong video (lựa chọn cụ thể thuộc `plan.md`).
- Quyết định của stakeholder về ngân sách chi phí AI và danh sách thư mục/nguồn được phép xử lý.
- Tài liệu `docs/architecture/system-map.md` để xác định vị trí hệ thống mới trong workspace khi lập plan (Constitution VI).

---

## 18. Câu hỏi mở

<!-- Tối đa 3 marker [CẦN LÀM RÕ: ...] cho các điểm chặn scope, bảo mật, dữ liệu hoặc UX chính. Ghi "Không có" nếu đã rõ. -->

- Không có — các điểm chưa rõ (quy mô, ngôn ngữ, danh tính người dùng, ngân sách) đã được ghi thành giả định ở §14 và có thể điều chỉnh qua `/speckit-clarify`.

---

## Clarifications

<!-- Do /speckit-clarify quản lý (`### Session YYYY-MM-DD` -> `- Q: ... → A: ...`). Khi trả lời xong mục ở §18, thay marker bằng `[ĐÃ LÀM RÕ → Clarifications / Session YYYY-MM-DD]`. -->

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

<!-- Chi tiết 16 tiêu chí chất lượng được chấm tại checklists/requirements.md (tránh lặp lại tại đây). -->

- [ ] Quality gate tại `checklists/requirements.md` đạt `Pass` hoặc `Pass có điều kiện`.
- [ ] Mọi câu hỏi mở chặn phạm vi/dữ liệu/bảo mật tại §18 đã được giải quyết hoặc ghi nhận ngoại lệ.
- [ ] Đánh giá tác động tài liệu nghiệp vụ (§20) đã hoàn tất (không còn `CHƯA ĐÁNH GIÁ`).

---

## 20. Đánh giá tác động tài liệu nghiệp vụ

<!-- Gate bắt buộc do /speckit-docbiz cập nhật sau lần sửa cuối của spec.md và trước /speckit-plan. -->

- **Trạng thái**: CHƯA ĐÁNH GIÁ
- **Căn cứ**: Chưa đánh giá — chờ `/speckit-docbiz` sau lần sửa cuối của spec.
- **Tài liệu đã cập nhật**: Không áp dụng
