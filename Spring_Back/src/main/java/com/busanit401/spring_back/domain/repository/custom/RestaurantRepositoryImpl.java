package com.busanit401.spring_back.domain.repository.custom;

import com.busanit401.spring_back.domain.entity.QRestaurant;
import com.busanit401.spring_back.domain.entity.Restaurant;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;

import java.util.List;

@RequiredArgsConstructor
public class RestaurantRepositoryImpl implements RestaurantRepositoryCustom {

    private final JPAQueryFactory queryFactory;
    private final QRestaurant restaurant = QRestaurant.restaurant;

    @Override
    public List<Restaurant> findByAccommodationIdAndPlaceIdIn(Long accommodationId, List<String> placeIds) {
        if (placeIds == null || placeIds.isEmpty()) {
            return List.of();
        }
        return queryFactory
                .selectFrom(restaurant)
                .where(restaurant.accommodation.id.eq(accommodationId),
                        restaurant.placeId.in(placeIds))
                .fetch();
    }

    @Override
    public List<Restaurant> findByAccommodationIdOrderByPopularity(Long accommodationId) {
        return queryFactory
                .selectFrom(restaurant)
                .where(restaurant.accommodation.id.eq(accommodationId))
                // popularityRank 오름차순(0이 가장 인기), 값 없으면 뒤로
                .orderBy(restaurant.popularityRank.asc().nullsLast(),
                        restaurant.name.asc())
                .fetch();
    }
}