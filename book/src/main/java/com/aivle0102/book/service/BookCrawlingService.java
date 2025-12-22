package com.aivle0102.book.service;

import com.aivle0102.book.dto.BookDto;
import java.io.IOException;
import java.util.List;

public interface BookCrawlingService {
    List<BookDto> searchBooks(String keyword) throws IOException;

}
