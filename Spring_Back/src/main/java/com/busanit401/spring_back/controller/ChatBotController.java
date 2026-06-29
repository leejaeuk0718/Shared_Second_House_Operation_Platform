package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.ChatBotService;
import com.busanit401.spring_back.domain.service.ChatBotService.SearchHit;
import com.busanit401.spring_back.domain.service.rag.SuggesterForRag;
import com.busanit401.spring_back.security.auth.CustomUserDetails;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Log4j2
@Tag(name = "Joldo - 운영 FAQ 검색(최종)", description = "LuceneBM25 / 임베딩 개별 확인")
@RestController
@RequestMapping("/api/chatBot")
@RequiredArgsConstructor
public class ChatBotController {

    private final ChatBotService chatBotService;

    @GetMapping("/lucene")
    @Operation(summary = "LuceneBM25 검색 (단어 매칭)(최종)",
            description = "질의를 LuceneBM25로 검색해 상위 N개 FAQ를 반환. Gemini 키 불필요.")
    public Map<String, Object> lucene(
            @Parameter(description = "사용자 질의", example = "강아지 데려가도 되나요?")
            @RequestParam String q,
            @Parameter(description = "반환 개수", example = "5")
            @RequestParam(defaultValue = "5") int limit) {

        return toResponse("lucene_bm25", q, chatBotService.luceneSearch(q, limit));
    }

    @GetMapping("/embedding")
    @Operation(summary = "임베딩 검색 (의미 매칭)(최종)",
            description = "질의를 Gemini로 임베딩해 의미 코사인으로 상위 N개 FAQ를 반환. "
                    + "단어가 안 겹쳐도 의미가 가까우면 잡는다. Gemini 키 필요(파라미터 key).")
    public Map<String, Object> embedding(
            @Parameter(description = "사용자 질의", example = "반려동물 동반 가능한가요?")
            @RequestParam String q,
            @Parameter(description = "반환 개수", example = "5")
            @RequestParam(defaultValue = "5") int limit) {

        return toResponse("embedding", q, chatBotService.embeddingSearch(q, limit));
    }

    @GetMapping("/fusion")
    @Operation(summary = "가중합 융합 검색 (단어+의미)(최종 주력)",
            description = "LuceneBM25(단어)와 임베딩(의미)을 Min-Max 정규화 후 0.5:0.5 가중합으로 융합해 "
                    + "상위 N개 FAQ를 반환. 대화 경로 주력 방식. Gemini 키 필요(파라미터 key).")
    public Map<String, Object> fusion(
            @Parameter(description = "사용자 질의", example = "반려동물 동반 가능한가요?")
            @RequestParam String q,
            @Parameter(description = "반환 개수", example = "5")
            @RequestParam(defaultValue = "5") int limit) {

        return toResponse("lucene_bm25+embedding(weighted)", q, chatBotService.fusionSearch(q, limit));
    }

    @GetMapping("/chat")
    @Operation(summary = "RAG 답변 생성 (검색 + 생성)",
            description = "가중합 융합으로 상위 topK FAQ를 근거로 추리고, 그 근거만 바탕으로 "
                    + "gemini-2.5-flash가 최종 답변을 생성한다. Gemini 키 필요(파라미터 key).")
    public ChatBotService.AnswerResult chat(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Parameter(description = "사용자 질의", example = "반려동물 동반 가능한가요?")
            @RequestParam String q,
            @Parameter(description = "근거로 쓸 FAQ 개수", example = "3")
            @RequestParam(defaultValue = "3") int topK) {

        // /api/** 가 permitAll 이라 토큰이 없으면 userDetails 가 null 일 수 있다.
        // (SecurityConfig는 건드리지 않음 — JWT가 오면 검증해 식별, 없으면 그대로 통과)
        Long userId = (userDetails != null) ? userDetails.getId() : null;
        log.info("✅ [ChatBotController] RAG 답변 요청 → userId: {}, q: {}", userId, q);
        return chatBotService.answer(q, topK);
    }

    @GetMapping("/suggest")
    @Operation(summary = "추천검색어 자동완성 (오타 보정)",
            description = "입력 일부/오타로도 FAQ 후보를 제안. Lucene FuzzySuggester라 임베딩·LLM 비용 0, "
                    + "Gemini 키 불필요. 후보를 고르면 /faq/{id}로 답변을 가져온다.")
    public List<SuggesterForRag.Suggestion> suggest(
            @Parameter(description = "입력(일부/오타 허용)", example = "반려동")
            @RequestParam String q,
            @Parameter(description = "후보 개수", example = "5")
            @RequestParam(defaultValue = "5") int limit) {

        return chatBotService.suggest(q, limit);
    }

    @GetMapping("/faq/{id}")
    @Operation(summary = "FAQ 단건 답변 (추천검색어 클릭)",
            description = "자동완성 후보를 고르면 id로 질문+답변을 바로 반환. Gemini 키 불필요.")
    public SearchHit faqById(
            @Parameter(description = "FAQ id", example = "1")
            @PathVariable String id) {

        return chatBotService.faqById(id);
    }

    /** 검색 결과를 method·query·count·results(id·점수·질문·답변) 형태의 JSON으로 변환. */
    private Map<String, Object> toResponse(String method, String query, List<SearchHit> hits) {
        List<Map<String, Object>> results = new ArrayList<>();
        for (SearchHit h : hits) {
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("id", h.id());
            r.put("score", h.score());
            r.put("question", h.question());
            r.put("answer", h.answer());
            results.add(r);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("method", method);
        out.put("query", query);
        out.put("count", results.size());
        out.put("results", results);
        return out;
    }
}