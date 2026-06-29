package com.busanit401.spring_back.dto;

import lombok.Getter;
import lombok.Setter;
import java.util.List;

@Getter @Setter
public class TourApiResponse {
    private ResponseBody body;

    @Getter @Setter
    public static class ResponseBody {
        private ResponseItems items;
    }

    @Getter @Setter
    public static class ResponseItems {
        private List<ResponseItem> item;
    }

    @Getter @Setter
    public static class ResponseItem {
        private String title;
        private String firstimage;
        private String addr1;
        private String contentid;
    }
}