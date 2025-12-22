package com.aivle0102.book.controller;
import com.aivle0102.book.dto.BookDto;
import com.aivle0102.book.service.BookCrawlingService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/books")
@RequiredArgsConstructor
public class BookCrawlingController {

    private final BookCrawlingService crawlingService;

    @GetMapping("/search")
    public List<BookDto> searchBooks(@RequestParam String keyword) throws IOException {
        return crawlingService.searchBooks(keyword);
    }
}
