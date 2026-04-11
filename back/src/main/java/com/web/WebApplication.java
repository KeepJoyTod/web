package com.web;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootApplication
@MapperScan("com.web.mapper")
public class WebApplication {

    public static void main(String[] args) {
        SpringApplication.run(WebApplication.class, args);
    }

    @Bean
    public CommandLineRunner initSchema(JdbcTemplate jdbcTemplate) {
        return args -> {
            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS notifications (
                  id bigint(20) NOT NULL AUTO_INCREMENT,
                  user_id bigint(20) NOT NULL,
                  type varchar(32) NOT NULL,
                  title varchar(255) NOT NULL,
                  content text NULL,
                  related_id varchar(64) NULL,
                  is_read tinyint(4) NOT NULL DEFAULT 0,
                  read_time datetime NULL,
                  create_time datetime DEFAULT CURRENT_TIMESTAMP,
                  update_time datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  PRIMARY KEY (id),
                  KEY idx_user_id (user_id),
                  KEY idx_user_read (user_id, is_read),
                  KEY idx_related_id (related_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
                """);

            jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS reviews (
                  id bigint(20) NOT NULL AUTO_INCREMENT,
                  user_id bigint(20) NOT NULL,
                  order_id bigint(20) NOT NULL,
                  product_id bigint(20) NOT NULL,
                  rating int(11) NOT NULL,
                  content text NULL,
                  images text NULL,
                  create_time datetime DEFAULT CURRENT_TIMESTAMP,
                  update_time datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  PRIMARY KEY (id),
                  KEY idx_user_id (user_id),
                  KEY idx_order_id (order_id),
                  KEY idx_product_id (product_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
                """);
        };
    }
}
