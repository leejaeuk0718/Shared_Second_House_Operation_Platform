package com.busanit401.spring_back.domain.repository.custom;

import com.busanit401.spring_back.domain.QUser;
import com.busanit401.spring_back.domain.User;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class UserRepositoryImpl implements UserRepositoryCustom {

    private final JPAQueryFactory queryFactory;
    private final QUser user = QUser.user;

    @Override
    public List<User> searchByKeyword(String keyword) {
        return queryFactory
                .selectFrom(user)
                .where(
                        user.deletedAt.isNull()
                                .and(
                                        user.username.containsIgnoreCase(keyword)
                                                .or(user.nickname.containsIgnoreCase(keyword))
                                )
                )
                .orderBy(user.createdDate.desc())
                .fetch();
    }
}
