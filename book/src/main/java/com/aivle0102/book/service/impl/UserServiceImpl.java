package com.aivle0102.book.service.impl;

import com.aivle0102.book.domain.UserInfo;
import com.aivle0102.book.dto.UserSignUpRequest;
import com.aivle0102.book.repository.UserInfoRepository;
import com.aivle0102.book.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserInfoRepository userInfoRepository;

    @Override
    @Transactional
    public UserInfo signUp(UserSignUpRequest request) {

        // 1) 이메일 중복 체크 (이미 해놨으면 그대로 두고)
        userInfoRepository.findByEmail(request.getEmail())
                .ifPresent(user -> {
                    throw new IllegalStateException("이미 가입된 이메일입니다.");
                });

        // 2) 입력값 정리 + 유저 엔티티 생성
        UserInfo user = new UserInfo();
        user.setEmail(request.getEmail().trim().toLowerCase()); // 앞뒤 공백 제거 + 소문자 통일
        user.setPassword(request.getPassword());                 // 실서비스면 여기서 암호화
        user.setName(request.getName().trim());
        user.setPhone(request.getPhone() != null ? request.getPhone().trim() : null);

        // 3) 저장
        return userInfoRepository.save(user);
    }

    @Override
    @Transactional(readOnly = true)
    public UserInfo findByNameAndPhone(String name, String phone) {
        return userInfoRepository.findByNameAndPhone(name, phone)
                .orElse(null);
    }

    @Override
    @Transactional
    public String resetPassword(String email, String name, String phone) {

        UserInfo user = userInfoRepository
                .findByEmailAndNameAndPhone(email, name, phone)
                .orElseThrow(() -> new IllegalArgumentException("일치하는 사용자 정보가 없습니다."));

        // 임시 비밀번호 생성 (8자리)
        String tempPassword = UUID.randomUUID().toString().substring(0, 8);

        // 비밀번호 변경 (지금은 평문이지만, 나중에 암호화 가능)
        user.setPassword(tempPassword);
        userInfoRepository.save(user);

        return tempPassword;
    }

    @Override
    @Transactional
    public void changePassword(Long userId, String currentPassword, String newPassword) {

        UserInfo user = userInfoRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 지금은 평문 비밀번호라서 단순 비교
        if (!user.getPassword().equals(currentPassword)) {
            throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
        }

        // 새 비밀번호 == 기존 비밀번호 인지 체크
        if (currentPassword.equals(newPassword)) {
            throw new IllegalArgumentException("새 비밀번호는 이전 비밀번호와 달라야 합니다.");
        }

        // 새 비밀번호로 변경 (실서비스면 암호화 필수)
        user.setPassword(newPassword);
        userInfoRepository.save(user);
    }

    @Override
    @Transactional(readOnly = true)
    public UserInfo findById(Long userId) {
        return userInfoRepository.findById(userId).orElse(null);
    }
}