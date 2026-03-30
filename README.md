Trong xu hướng phần cứng mã nguồn mở ngày càng phát triển, RISC-V trở thành một ISA
nổi bật nhờ thiết kế gọn, dễ mở rộng và phù hợp cho nhiều mục tiêu (giáo dục, nhúng, nghiên
cứu). Ở milestone này, nhóm tập trung xây dựng CPU RV32I dạng pipeline 5 tầng, nhằm cải
thiện thông lượng thực thi so với thiết kế single-cycle trước đó.
Thiết kế được chia thành các khối chức năng (fetch/decode/execute/memory/write-back), đi
kèm cơ chế xử lý data hazard và control hazard. Nhóm cũng triển khai nhiều model pipeline
như: non-forwarding, forwarding, always-taken, và 2-bit scheme prediction để đánh giá tác động
đến hiệu năng (IPC) và tỷ lệ đoán sai (misprediction).

Overview

Milestone 3 tập trung vào việc chuyển đổi thiết kế CPU RV32I từ kiến trúc single-cycle
(Milestone 2) sang kiến trúc pipeline 5 tầng IF–ID–EX–MEM–WB. Bằng cách phân rã quá
trình thực thi lệnh thành các giai đoạn và cho phép nhiều lệnh được xử lý đồng thời ở các stage
khác nhau, kiến trúc pipeline hướng tới mục tiêu tăng thông lượng (throughput) và cải thiện
hiệu năng tổng thể.
