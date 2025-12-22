package com.aivle0102.book.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Builder
@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ImgInfo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long imgId;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private UserInfo user;

    @ManyToOne
    @JoinColumn(name = "book_id", nullable = false)
    private BookInfo book;

    @Column(nullable = false)
    private String origImgName;

    @Column(nullable = false)
    private String imgName;

    @Column(nullable = false, length = 1000)
    private String imgUrl;

    @Column(nullable = false, length = 1)
    private String state;

    @Column(nullable = false)
    private LocalDateTime startDate;

    @Column(nullable = false)
    private LocalDateTime endDate;

    @Column(nullable = false)
    private LocalDateTime regDate;
}
