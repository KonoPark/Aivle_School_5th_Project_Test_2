package com.aivle0102.book.controller;

import com.aivle0102.book.domain.UserInfo;
import com.aivle0102.book.dto.ChangePasswordRequest;
import com.aivle0102.book.service.LoginService;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import com.aivle0102.book.dto.UserSignUpRequest;
import com.aivle0102.book.service.UserService;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class AuthController {

    private final LoginService loginService;
    private final UserService userService;

    // 로그인
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody UserInfo user, HttpSession session) throws Exception {

        UserInfo loginUser = loginService.getUser(user);

        // 세션 저장
        session.setAttribute("user", loginUser.getUserId());

        // JSON 응답 생성
        Map<String, Object> body = new HashMap<>();
        body.put("status", "success");
        //body.put("message", "로그인 성공");
        body.put("userId", loginUser.getUserId());
        body.put("email", loginUser.getEmail());

        return ResponseEntity.ok(body);
    }


    //  회원가입

    @PostMapping("/join")
    public ResponseEntity<Map<String, Object>> signUp(
            @Valid @RequestBody UserSignUpRequest request,   // DTO 유효성 검사
            BindingResult bindingResult                       // @Valid 검사 결과
    ) {

        Map<String, Object> body = new HashMap<>();

        // 1) DTO 유효성 검사 실패 (@NotBlank, @Email, @Size 등)
        if (bindingResult.hasErrors()) {
            // 에러 하나만 꺼내서 메시지 반환
            String message = bindingResult.getFieldErrors().get(0).getDefaultMessage();

            body.put("status", "error");
            body.put("message", message);

            // code: 400
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
        }

        try {
            // 2) 실제 회원가입 비즈니스 로직
            UserInfo user = userService.signUp(request);

            Map<String, Object> data = new HashMap<>();
            data.put("userId", user.getUserId());
            data.put("email", user.getEmail());

            body.put("status", "success");
            body.put("message", "회원가입 성공");
            body.put("data", data);

            // code: 201
            return ResponseEntity.status(HttpStatus.CREATED).body(body);

        } catch (IllegalStateException e) {    // 3) 이미 가입된 이메일 같은 비즈니스 예외
            body.put("status", "error");
            body.put("message", e.getMessage());

            // code: 400
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);

        } catch (Exception e) {                // 4) 그 외 서버 내부 에러
            body.put("status", "error");
            body.put("message", "서버 내부 오류가 발생했습니다. 관리자에게 문의하세요.");

            // code: 500
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
        }
    }

    // ID 찾기
    @PostMapping("/find-id")
    public ResponseEntity<?> findId(@RequestBody Map<String, String> request) {
        String name = request.get("name");
        String phone = request.get("phone");

        UserInfo user = userService.findByNameAndPhone(name, phone);

        if (user == null) {
            return ResponseEntity.status(404).body(Map.of("message", "일치하는 정보가 없습니다."));
        }

        return ResponseEntity.ok(Map.of("email", user.getEmail()));
    }

    // PASSWORD 찾기
    @PostMapping("/find-pw")
    public ResponseEntity<?> findPassword(@RequestBody Map<String, String> request) {

        String email = request.get("email");
        String name = request.get("name");
        String phone = request.get("phone");

        Map<String, Object> body = new HashMap<>();

        try {
            String tempPassword = userService.resetPassword(email, name, phone);

            Map<String, Object> data = new HashMap<>();
            data.put("tempPassword", tempPassword);

            body.put("status", "success");
            body.put("message", "임시 비밀번호가 발급되었습니다.");
            body.put("data", data);

            return ResponseEntity.ok(body);

        } catch (IllegalArgumentException e) {
            body.put("status", "error");
            body.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);

        } catch (Exception e) {
            body.put("status", "error");
            body.put("message", "서버 내부 오류가 발생했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
        }
    }

    // PASSWORD 변경
    @PostMapping("/change-pw")
    public ResponseEntity<?> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            BindingResult bindingResult
    ) {
        // 1) DTO 검증 실패 시
        if (bindingResult.hasErrors()) {
            String message = bindingResult.getFieldErrors().get(0).getDefaultMessage();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of(
                            "status", "error",
                            "message", message
                    ));
        }

        Map<String, Object> body = new HashMap<>();

        try {
            // 2) 실제 비밀번호 변경 처리
            userService.changePassword(
                    request.getUserId(),
                    request.getCurrentPassword(),
                    request.getNewPassword()
            );

            body.put("status", "success");
            body.put("message", "비밀번호가 변경되었습니다. 다시 로그인 해 주세요.");
            return ResponseEntity.ok(body);

        } catch (IllegalArgumentException e) {
            body.put("status", "error");
            body.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);

        } catch (Exception e) {
            body.put("status", "error");
            body.put("message", "서버 내부 오류가 발생했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
        }
    }

    // 현재 로그인한 사용자 정보 조회
    @GetMapping("/me")
    public ResponseEntity<?> me(HttpSession session) {

        Object userIdObj = session.getAttribute("user");

        if (userIdObj == null) {
            // 세션에 user가 없는 상태 → 로그인 안 된 것
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of(
                            "status", "error",
                            "message", "로그인 정보가 없습니다."
                    ));
        }

        Long userId;
        try {
            userId = (Long) userIdObj;
        } catch (ClassCastException e) {
            session.invalidate();
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of(
                            "status", "error",
                            "message", "로그인 정보가 올바르지 않습니다."
                    ));
        }

        UserInfo user = userService.findById(userId);
        if (user == null) {
            session.invalidate();
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of(
                            "status", "error",
                            "message", "사용자를 찾을 수 없습니다."
                    ));
        }

        Map<String, Object> data = new HashMap<>();
        data.put("userId", user.getUserId());
        data.put("email", user.getEmail());

        return ResponseEntity.ok(
                Map.of(
                        "status", "success",
                        "data", data
                )
        );
    }


    @PostMapping("/logout")
    public ResponseEntity<?> logout(HttpSession session) {
        session.invalidate();
        return ResponseEntity.ok(
                Map.of(
                        "status", "success",
                        "message", "로그아웃 되었습니다."
                )
        );
    }
}
