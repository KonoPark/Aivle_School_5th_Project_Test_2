package com.aivle0102.book.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;


@Configuration
public class WebConfig implements WebMvcConfigurer {

   @Override
   public void addCorsMappings(CorsRegistry registry) {
   registry.addMapping("/**")
       .allowedOrigins("http://localhost:3000")
       .allowedMethods("GET", "POST", "PUT", "DELETE")
       .allowedHeaders("*")
       .allowCredentials(true)
       .maxAge(3600);
   }

    @Override
      public void addResourceHandlers(ResourceHandlerRegistry registry) {

          // OS마다 경로 다르게 설정 가능 (Windows 기준)
          String uploadPath = System.getProperty("user.dir") + "/uploads/book/";

          registry.addResourceHandler("/uploads/**")        // 프론트에서 접근 URL
                  .addResourceLocations("file:" + uploadPath); // 실제 파일 저장 경로
      }
}