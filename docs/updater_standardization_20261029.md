# Chuẩn hóa engine updater VXDeck

Version: 1.1.0 — Ngày update: 2026-10-30

Track chỉnh sửa sau update/release. [Contract chung](../../_summary/standard_docs/auto_update_standards.md); ngoại lệ Deck chỉ ở shell popup, không miễn updater.

## Controller và trust
- AppUpdateController.shared là process owner: UI observe status/version/progress/error/noticeVisible/release, start() một lần; check(manual:), dismiss(), install(prepare:) dùng chung cho notice và Settings. Đóng popup không hủy/tạo job khác. prepare phải flush dữ liệu; controller tự terminate sau helper ACK, không UI exit0 hoặc tự download DMG.
- AppUpdater actor single-flight; check15s/download300s, download byte progress thật. Ed25519 signed_payload raw bytes xác thực appID com.ztools.vxdeck, stable version cao hơn, architecture và URL release chính xác, size/hash; codesign stage trước install. Chỉ thay chính bundle đang chạy và không chạy từ DMG.
- Helper stage cùng parent/volume, identity và digest recheck sau ACK/parent exit, wait30s hữu hạn; giữ backup, swap failure hoặc launch failure có rollback. Receipt awaiting_launch_confirmation không đồng nghĩa thành công; startup xác nhận bundle version/executable hash mới đánh completed. Không rm -rf app đích.

## Release signing cần bàn giao khi được giao release
- Public trust anchor: Sources/VXDeckCore/Services/UpdaterTrust.swift; key riêng giữ ngoài repo app, không in/log/commit/upload tự động. Root checkpoint ghi nơi key local; không đưa bytes vào tài liệu.
- scripts/sign_update_manifest.py đọc VXDECK_SIGNING_KEY_FILE (local) hoặc VXDECK_SIGNING_PRIVATE_KEY (CI); key phải khớp public key đã compile. package_release.sh gọi signer và workflow nhận GitHub Secret cùng tên. **Chưa upload secret hoặc phát hành bản mới trong task này.** Người điều phối release phải được user cho phép upload đúng secret/repo trước khi thao tác; không thay key chỉ để chữa CI.
- Manifest có signed_payload/signature; top-level legacy metadata chỉ giúp client cũ hiển thị, client mới không dùng nó làm trust. Release cũ unsigned bị từ chối trung thực; không fallback auto-install unsigned hoặc fake-current. Bản đầu có updater an toàn này cần bootstrap từ bundle mới khi release được giao.

## Evidence
CoreTests và security tests (manifest/tamper/wrong key/app/URL/arch/version) đã PASS; helper4tests dùng filesystem/codesign thật trên bundle fixture, launcher thay true/false để thử giữ backup, rollback, tamper sauACK và changedtarget. **Không thay native GUI/updateE2E**. Chưa xác nhận public signed manifest hoặc app đã cài. UI store/Settings checker cũ cần Anti chuyển sang shared controller, không coi engine source mới đã đủ AU-01…AU-16.

## Settings sheet và bàn giao thoát app (2026-10-30)

- Hai entry Settings/notice tiếp tục dùng cùng controller, single-flight và flush trước cài.
- Sau helper ACK, `UpdateApplicationTermination.request` phát tín hiệu để root tắt binding Settings/dialog, kết thúc sheet còn gắn và unwind modal session nếu có. Chờ AppKit tháo sheet thực sự (tối đa5s), rồi yêu cầu `NSApp.terminate`. Không force-exit; vẫn qua application delegate. Hết hạn vẫn giữ watchdog/recovery của helper, không giả thành công.
- Không đóng Settings khi kiểm tra/tải/xác minh hoặc prepare/stage lỗi. Chỉ tháo modal sau ACK; giữ nguyên trust/receipt/rollback và timeout.
- Hồi quy native: `python3 scripts/test_update_termination.py` tạo floating NSPanel với SwiftUI Settings sheet thật, đối chiếu terminate cũ, notice đã đóng Settings và Settings sau sửa. Fixture không tải/swap app thật, không thay signed update E2E N→N+1.
- Kết quả2026-10-30: baseline còn chạy và delegate không được gọi; notice và Settings sau sửa đều kết thúc qua delegate đúng1lần. Source build/core/security/SDK được lưu riêng trong báo cáo task.
