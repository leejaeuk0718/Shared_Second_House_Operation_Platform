package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.entity.Restaurant;
import com.busanit401.spring_back.domain.repository.custom.RestaurantRepositoryCustom;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RestaurantRepository extends JpaRepository<Restaurant, Long>,
        RestaurantRepositoryCustom {
}