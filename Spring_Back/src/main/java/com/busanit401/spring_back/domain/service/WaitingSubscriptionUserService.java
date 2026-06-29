package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.SubscriptionsUser;
import com.busanit401.spring_back.domain.User;
import com.busanit401.spring_back.domain.WaitingSubscriptionUser;
import com.busanit401.spring_back.dto.waitingSubscriptionUser.WaitingSubscriptionReq;
import com.busanit401.spring_back.dto.waitingSubscriptionUser.WaitingSubscriptionResp;
import com.busanit401.spring_back.dto.waitingSubscriptionUser.WaitingSubscriptionSearchCondition;
import com.busanit401.spring_back.enums.MemberStatus;
import com.busanit401.spring_back.enums.NotificationType;
import com.busanit401.spring_back.enums.SubscriptionStatus;
import com.busanit401.spring_back.exception.BusinessException;
import com.busanit401.spring_back.exception.DuplicateException;
import com.busanit401.spring_back.exception.EntityNotFoundException;
import com.busanit401.spring_back.exception.ErrorCode;
import com.busanit401.spring_back.exception.InvalidStateException;
import com.busanit401.spring_back.domain.repository.SubscriptionsUserRepository;
import com.busanit401.spring_back.domain.repository.UserRepository;
import com.busanit401.spring_back.domain.repository.WaitingSubscriptionUserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
@Log4j2
@Transactional(readOnly = true)
public class WaitingSubscriptionUserService {

    private final WaitingSubscriptionUserRepository waitingRepository;
    private final SubscriptionsUserRepository subscriptionsUserRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    // 구독 신청 (대표)
    @Transactional
    public List<WaitingSubscriptionResp> apply(Long leaderId, WaitingSubscriptionReq req) {
        User leader = findActiveUser(leaderId);

        validateDuplicateSubscription(leaderId, req.getAccommodationId());

        // [날짜 검증 추가] 같은 숙소의 PENDING/ACTIVE 구독과 날짜 겹침 사전 차단 (save() 전 호출)
        validateDateOverlap(req.getAccommodationId(), req.getStartDate(),
                req.getStartDate().plusMonths(req.getDurationMonths()));

        List<User> members = findMembers(req.getMemberIdentifiers());
        validateMembersFound(req.getMemberIdentifiers(), members);

        SubscriptionsUser subscriptionsUser = SubscriptionsUser.create(
                leader, req);
        subscriptionsUserRepository.save(subscriptionsUser);

        List<WaitingSubscriptionUser> waitingList = buildWaitingList(subscriptionsUser, leader, members);
        waitingRepository.saveAll(waitingList);

        // 멤버 없이 대표만 신청한 경우 즉시 관리자 알림 발송
        boolean allApproved = waitingList.stream()
                .allMatch(w -> w.getStatus() == MemberStatus.APPROVED);
        if (allApproved) {
            notificationService.notifyAdmin(
                    NotificationType.SUBSCRIPTION_READY,
                    "새로운 구독 신청이 승인 대기 중입니다. (구독 ID: " + subscriptionsUser.getId() + ")",
                    subscriptionsUser.getId()
            );
        }

        return waitingList.stream()
                .map(WaitingSubscriptionResp::from)
                .collect(Collectors.toList());
    }

    // 멤버 동의
    @Transactional
    public WaitingSubscriptionResp approveMember(Long subscriptionsUserId, Long userId) {
        WaitingSubscriptionUser waiting = findWaiting(subscriptionsUserId, userId);
        validatePendingStatus(waiting);
        waiting.approve();

        // 모든 멤버가 동의했는지 체크
        boolean allApproved = waitingRepository
                .findAllBySubscriptionsUserId(subscriptionsUserId)
                .stream()
                .allMatch(w -> w.getStatus() == MemberStatus.APPROVED);

        // 전원 동의 시 관리자한테 알림 전송
        if (allApproved) {
            notificationService.notifyAdmin(
                    NotificationType.SUBSCRIPTION_READY,
                    "새로운 구독 신청이 승인 대기 중입니다. (구독 ID: " + subscriptionsUserId + ")",
                    subscriptionsUserId
            );
            log.info("[전원 동의 완료] subscriptionsUserId: {}", subscriptionsUserId);
        }

        return WaitingSubscriptionResp.from(waiting);
    }

    // 멤버 거절
    @Transactional
    public WaitingSubscriptionResp rejectMember(Long subscriptionsUserId, Long userId) {
        WaitingSubscriptionUser waiting = findWaiting(subscriptionsUserId, userId);
        validatePendingStatus(waiting);
        waiting.reject();
        return WaitingSubscriptionResp.from(waiting);
    }

    // 내가 초대받은 목록 조회
    public List<WaitingSubscriptionResp> getMyInvitations(Long userId) {
        return waitingRepository.findAllByUserIdAndStatus(userId, MemberStatus.PENDING)
                .stream()
                .map(WaitingSubscriptionResp::from)
                .collect(Collectors.toList());
    }

    // 관리자 - 복합 조건 검색
    public List<WaitingSubscriptionResp> searchByCondition(WaitingSubscriptionSearchCondition condition) {
        return waitingRepository.searchByCondition(condition)
                .stream()
                .map(WaitingSubscriptionResp::from)
                .collect(Collectors.toList());
    }

    // -----------------------------------------------
    // Private 메서드
    // -----------------------------------------------

    private List<WaitingSubscriptionUser> buildWaitingList(
            SubscriptionsUser subscriptionsUser, User leader, List<User> members) {
        List<WaitingSubscriptionUser> waitingList = new java.util.ArrayList<>();
        waitingList.add(WaitingSubscriptionUser.createLeader(subscriptionsUser, leader));
        members.stream()
                .map(member -> WaitingSubscriptionUser.createMember(subscriptionsUser, member))
                .forEach(waitingList::add);
        return waitingList;
    }

    private List<User> findMembers(List<String> identifiers) {
        if (identifiers == null || identifiers.isEmpty()) return List.of();
        return userRepository.findAllByUsernameInOrEmailIn(identifiers);
    }

    private void validateMembersFound(List<String> identifiers, List<User> members) {
        if (identifiers == null || identifiers.isEmpty()) return;
        Set<String> foundIdentifiers = members.stream()
                .flatMap(u -> Stream.of(u.getUsername(), u.getEmail()))
                .collect(Collectors.toSet());
        List<String> notFound = identifiers.stream()
                .filter(id -> !foundIdentifiers.contains(id))
                .collect(Collectors.toList());
        if (!notFound.isEmpty()) {
            throw new EntityNotFoundException(
                    ErrorCode.MEMBER_NOT_FOUND);
        }
    }

    private void validateDuplicateSubscription(Long userId, Long accommodationId) {
        if (subscriptionsUserRepository.existsByUserIdAndAccommodationIdAndStatus(
                userId, accommodationId, SubscriptionStatus.ACTIVE)) {
            throw new DuplicateException(ErrorCode.DUPLICATE_SUBSCRIPTION);
        }
    }

    // [날짜 검증 추가] 신청 날짜가 기존 PENDING/ACTIVE 구독과 겹치는지 체크
    private void validateDateOverlap(Long accommodationId, LocalDate newStart, LocalDate newEnd) {
        List<SubscriptionStatus> checkStatuses = List.of(SubscriptionStatus.PENDING, SubscriptionStatus.ACTIVE);
        boolean hasOverlap = !subscriptionsUserRepository
                .findOverlappingSubscriptions(accommodationId, newStart, newEnd, checkStatuses)
                .isEmpty();
        if (hasOverlap) {
            throw new BusinessException(ErrorCode.SUBSCRIPTION_DATE_CONFLICT);
        }
    }

    private void validatePendingStatus(WaitingSubscriptionUser waiting) {
        if (waiting.getStatus() != MemberStatus.PENDING) {
            throw new InvalidStateException(ErrorCode.ALREADY_PROCESSED);
        }
    }

    private WaitingSubscriptionUser findWaiting(Long subscriptionsUserId, Long userId) {
        return waitingRepository.findBySubscriptionsUserIdAndUserId(subscriptionsUserId, userId)
                .orElseThrow(() -> new EntityNotFoundException(ErrorCode.MEMBER_NOT_FOUND));
    }

    private User findActiveUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException(ErrorCode.MEMBER_NOT_FOUND));
        if (user.getDeletedAt() != null) {
            throw new InvalidStateException(ErrorCode.DELETED_USER);
        }
        return user;
    }
}