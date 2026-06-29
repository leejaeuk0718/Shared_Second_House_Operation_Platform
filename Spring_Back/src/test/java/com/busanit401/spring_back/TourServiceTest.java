package com.busanit401.spring_back;

import com.busanit401.spring_back.domain.service.TourService;
import com.busanit401.spring_back.dto.TourResponseListDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TourServiceTest {

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private TourService tourService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(tourService, "serviceKey", "dummy_mock_key_for_test");
    }

    @Test
    @DisplayName("정상 조회 - 전체 데이터(totalCount)가 1개뿐일 때 1페이지를 요청하면 isLast가 true여야 한다")
    void getTourListByRegion_Success_IsLast_True() {
        // given
        String regionCode = "26";
        int pageNo = 1;

        Map<String, Object> mockItem = new HashMap<>();
        mockItem.put("title", "다대포생태탐방로");
        mockItem.put("firstimage", "https://image.com/test.jpg");
        mockItem.put("addr1", "부산광역시 사하구");
        mockItem.put("contentid", "3027228");

        // 💡 단건/다건 완벽 대응을 위해 ArrayList로 명확히 감싸서 주입
        List<Map<String, Object>> itemWrapperList = new ArrayList<>();
        itemWrapperList.add(mockItem);

        Map<String, Object> itemsMap = new HashMap<>();
        itemsMap.put("item", itemWrapperList);

        Map<String, Object> bodyMap = new HashMap<>();
        bodyMap.put("items", itemsMap);
        bodyMap.put("totalCount", 1); // 서비스 내부에서 String.valueOf()를 쓰므로 숫자로 넣어도 안전합니다.

        Map<String, Object> resMap = new HashMap<>();
        resMap.put("body", bodyMap);

        Map<String, Object> mockApiResponse = new HashMap<>();
        mockApiResponse.put("response", resMap);

        when(restTemplate.getForObject(any(URI.class), eq(Map.class))).thenReturn(mockApiResponse);

        // when
        TourResponseListDto result = tourService.getTourListByRegion(regionCode, pageNo);

        // then
        assertThat(result).isNotNull();
        assertThat(result.getTours()).isNotEmpty();
        assertThat(result.getTours()).hasSize(1);
        assertThat(result.getTours().get(0).getTitle()).isEqualTo("다대포생태탐방로");
        assertThat(result.isLast()).isTrue();
    }

    @Test
    @DisplayName("정상 조회 - 가져온 데이터가 딱 10개고 전체(totalCount)가 20개일 때 (1페이지 조회시) isLast는 false여야 한다")
    void getTourListByRegion_Success_IsLast_False() {
        // given
        String regionCode = "26";
        int pageNo = 1;

        Map<String, Object> mockItem = new HashMap<>();
        mockItem.put("title", "테스트관광지");

        List<Map<String, Object>> itemWrapperList = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            itemWrapperList.add(mockItem);
        }

        Map<String, Object> itemsMap = new HashMap<>();
        itemsMap.put("item", itemWrapperList);

        Map<String, Object> bodyMap = new HashMap<>();
        bodyMap.put("items", itemsMap);
        bodyMap.put("totalCount", 20);

        Map<String, Object> resMap = new HashMap<>();
        resMap.put("body", bodyMap);

        Map<String, Object> mockApiResponse = new HashMap<>();
        mockApiResponse.put("response", resMap);

        when(restTemplate.getForObject(any(URI.class), eq(Map.class))).thenReturn(mockApiResponse);

        // when
        TourResponseListDto result = tourService.getTourListByRegion(regionCode, pageNo);

        System.out.println("==================================================");
        System.out.println("🧪 [테스트 콘솔 출력] TourService 파싱 결과 성공!");
        System.out.println("▶ 가져온 총 관광지 개수 : " + result.getTours().size() + "개");
        System.out.println("▶ 마지막 페이지인가요? : " + result.isLast());

        if (!result.getTours().isEmpty()) {
            System.out.println("▶ 변환된 첫 번째 관광지 타이틀 : " + result.getTours().get(0).getTitle());
            System.out.println("▶ 변환된 첫 번째 관광지 주소 : " + result.getTours().get(0).getAddr1());
        }
        System.out.println("==================================================");

        // then
        assertThat(result).isNotNull();
        assertThat(result.getTours()).hasSize(10);
        assertThat(result.isLast()).isFalse();
    }

    @Test
    @DisplayName("데이터 없음 - 공공데이터 API가 결과가 없어서 빈 문자열(\"\")을 주었을 때 빈 리스트와 isLast=true를 반환한다")
    void getTourListByRegion_NoItems() {
        // given
        Map<String, Object> bodyMap = new HashMap<>();
        bodyMap.put("items", "");
        bodyMap.put("totalCount", 0);

        Map<String, Object> resMap = new HashMap<>();
        resMap.put("body", bodyMap);

        Map<String, Object> mockApiResponse = new HashMap<>();
        mockApiResponse.put("response", resMap);

        when(restTemplate.getForObject(any(URI.class), eq(Map.class))).thenReturn(mockApiResponse);

        // when
        TourResponseListDto result = tourService.getTourListByRegion("11", 1);

        // then
        assertThat(result.getTours()).isEmpty();
        assertThat(result.isLast()).isTrue();
    }
}