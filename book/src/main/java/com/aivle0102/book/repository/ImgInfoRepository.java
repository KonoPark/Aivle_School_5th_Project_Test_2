package com.aivle0102.book.repository;

import com.aivle0102.book.domain.ImgInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ImgInfoRepository extends JpaRepository<ImgInfo, Long> {
    List<ImgInfo> findByBook_BookId(Long bookId);
    List<ImgInfo> findByBook_BookIdAndState(Long bookId, String state);

    void deleteByBook_BookId(Long bookId); //삭제 관련 추가

}
