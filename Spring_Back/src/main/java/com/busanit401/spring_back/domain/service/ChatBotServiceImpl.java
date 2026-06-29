package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.controller.ChatBotController;
import com.busanit401.spring_back.domain.repository.ChatBotRepository;
import com.busanit401.spring_back.dto.ChatBotFaqDocDTO;
import com.busanit401.spring_back.dto.ChatBotScoredDocDTO;
import com.busanit401.spring_back.domain.service.rag.*;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * {@link ChatBotService} 구현. {@link ChatBotController}가
 * "고르고 호출"만 하도록, 코퍼스 로드·검색기 조립을 여기로 모은다.
 *
 * <p><b>캐싱 전략</b>
 * <ul>
 *   <li><b>Lucene(단어)</b> — 키와 무관하고 코퍼스에만 의존 → 색인을 <b>첫 요청 때 1회 조립</b>해 캐시.
 *       {@link LuceneBm25RetrieverForRag}는 불변·스레드세이프 인메모리 색인이라 재사용해도 안전하고,
 *       {@link AutoCloseable}이므로 빈 종료 시 {@link #close()}에서 닫는다.</li>
 *   <li><b>임베딩(의미)</b> — Gemini 키가 <b>매 요청 파라미터</b>로 들어오므로 키에 묶인
 *       {@code provider}·{@link EmbeddingRetrieverForRag}는 요청마다 새로 만든다(FAQ 20행이라 비용 0).
 *       코퍼스 벡터는 캐시를 재사용한다.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class ChatBotServiceImpl implements ChatBotService {

    @Value("${gemini.api.key:}")
    private String apiKey;

    /** 문서 임베딩과 동일해야 하는 Gemini 모델(질의 임베딩도 같은 모델/차원이어야 코사인이 유효). */
    private static final String EMBED_MODEL = "gemini-embedding-2";
    private static final int DIM = 1536;
    /** 답변 생성(G) 모델. */
    private static final String CHAT_MODEL = "gemini-2.5-flash";

    private final ChatBotRepository chatBotRepository;   // FAQ 코퍼스 로드
    private final WebClient googleWebClient;      // Gemini 임베딩·생성 REST 호출용(공용 빈)
    private final SuggesterForRag suggesterForRag;     // 추천검색어 자동완성(Lucene, 비용 0)

    /** 키와 무관한 조립물(코퍼스·id맵·Lucene 색인). 첫 요청 때 1회 조립 후 재사용. */
    private record Corpus(List<ChatBotFaqDocDTO> docs, Map<String, ChatBotFaqDocDTO> byId, LuceneBm25RetrieverForRag lucene) {}
    private volatile Corpus cache;   // 멀티스레드 환경에서 최신값 가시성(확인) 보장

    @Override
    public List<SearchHit> luceneSearch(String query, int limit) {
        Corpus c = corpus();
        return toHits(c.lucene().searchScored(query, limit), c.byId()); //id, 점수, 질문, 답변
    }

    @Override
    public List<SearchHit> embeddingSearch(String query, int limit) {
        Corpus c = corpus();
        // 질의 임베딩 제공자: 문서와 동일 모델/차원, task_type 없음. 키에 묶이므로 요청마다 새로 만든다.
        GeminiQueryEmbeddingProviderForRag provider = new GeminiQueryEmbeddingProviderForRag(
                googleWebClient, apiKey, EMBED_MODEL, DIM, null);
        EmbeddingRetrieverForRag emb = new EmbeddingRetrieverForRag("embedding", c.docs(), provider);
        return toHits(emb.searchScored(query, limit), c.byId());    //id, 점수, 질문, 답변
    }

    @Override
    public List<SearchHit> fusionSearch(String query, int limit) {
        Corpus c = corpus();
        // 임베딩은 키에 묶이므로 요청마다 새로 조립. Lucene은 캐시된 색인 재사용.
        GeminiQueryEmbeddingProviderForRag provider = new GeminiQueryEmbeddingProviderForRag(
                googleWebClient, apiKey, EMBED_MODEL, DIM, null);
        EmbeddingRetrieverForRag emb = new EmbeddingRetrieverForRag("embedding", c.docs(), provider);
        // 대화 경로 주력: LuceneBM25(단어) + 임베딩(의미)을 Min-Max 정규화 후 0.5:0.5 가중합으로 융합.
        FusionRetrieverForRag fusion = FusionRetrieverForRag.weightedSum(   //[lucence, embedding]방식과 가중치로 점수 계산
                "lucene_bm25+embedding(weighted)",
                List.of(c.lucene(), emb),
                new double[]{0.3, 0.7});
        return toHits(fusion.searchScored(query, limit), c.byId()); //id, 점수, 질문, 답변
    }

    @Override
    public AnswerResult answer(String query, int topK) {
        // 1·2단계(검색·점수·추림): 이미 구현된 가중합 융합 재사용 → 근거 FAQ topK개
        List<SearchHit> sources = fusionSearch(query, topK);    //가중합한 상위 k개의 [id, 점수, 질문, 답변]
        // 3단계: 근거를 묶어 프롬프트 구성
        String prompt = buildPrompt(buildContext(sources), query);
        // 4단계: 생성 모델로 최종 답변
        GeminiChatClientForRag chat = new GeminiChatClientForRag(googleWebClient, apiKey, CHAT_MODEL);
        String answer = chat.generate(prompt);
        return new AnswerResult(query, answer, sources);
    }

    @Override
    public List<SuggesterForRag.Suggestion> suggest(String input, int limit) {
        return suggesterForRag.suggest(input, limit);
    }

    @Override
    public SearchHit faqById(String id) {
        ChatBotFaqDocDTO doc = chatBotRepository.findById(id);
        if (doc == null) {
            throw new IllegalArgumentException("FAQ를 찾을 수 없습니다: id=" + id);
        }
        return new SearchHit(doc.getId(), 0.0, doc.getQuestion(), doc.getAnswer());
    }

    /** 검색된 FAQ들을 "[FAQ] Q: ..\nA: .." 형태로 빈 줄 구분해 근거 블록 구성. */
    private String buildContext(List<SearchHit> sources) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < sources.size(); i++) {
            if (i > 0) {
                sb.append("\n\n");
            }
            SearchHit h = sources.get(i);
            sb.append("[FAQ] Q: ").append(h.question()).append("\nA: ").append(h.answer());
        }
        return sb.toString();
    }

    /** 근거 자료만 바탕으로 답하도록 지시하는 고객센터 상담원 프롬프트. */
    private String buildPrompt(String context, String query) {
        return """
                너는 '세컨하우스' 고객센터 상담원이야.
                아래 FAQ 자료만 근거로 사용자 질문에 친절하게 답변해줘.
                자료에 없는 내용이면 모른다고 솔직하게 말하고, 고객센터로 문의를 안내해.
                사용자 질문이 의미 없는 입력이거나 참고 자료와 무관하면, 답을 지어내지 말고 모른다고 안내해.

                [참고 자료]
                %s

                [사용자 질문]
                %s

                [답변]""".formatted(context, query);
    }

    /** 코퍼스·id맵·Lucene 색인을 첫 호출 때 1회 조립(이후 캐시). */
    private Corpus corpus() {
        Corpus local = cache;
        if (local != null) {
            return local;   //Corpus가 존재 한다면 있는 Corpus그대로 사용
        }
        synchronized (this) {
            if (cache == null) {    //Corpus가 없다면
                List<ChatBotFaqDocDTO> docs = chatBotRepository.findAll();  //db에 저장된 질문 문서들을 읽어옴(id, 질의, 답변, 벡터)
                Map<String, ChatBotFaqDocDTO> byId = new LinkedHashMap<>(); //넣은 순서대로 맵핑(id가 index로 작용해서 검색시 모든 값을 순회하지 않고 값을 빼낼수 있음)
                for (ChatBotFaqDocDTO d : docs) {
                    byId.put(d.getId(), d);
                }
                LuceneBm25RetrieverForRag lucene = new LuceneBm25RetrieverForRag("lucene_bm25", docs);  //LuceneBm25RetrieverForRag내부에서 전체 순회가 필요
                cache = new Corpus(docs, byId, lucene);
            }
            return cache;
        }
    }

    /** (id+점수) 결과에 질문/답변을 붙여 {@link SearchHit}로 변환. */
    private List<SearchHit> toHits(List<ChatBotScoredDocDTO> scored, Map<String, ChatBotFaqDocDTO> byId) {
        List<SearchHit> hits = new ArrayList<>(scored.size());
        for (ChatBotScoredDocDTO s : scored) {
            ChatBotFaqDocDTO doc = byId.get(s.getId());
            hits.add(new SearchHit(s.getId(), s.getScore(),
                    doc == null ? null : doc.getQuestion(),
                    doc == null ? null : doc.getAnswer()));
        }
        return hits;
    }

    /** 앱 종료 시 캐시된 Lucene 색인(Reader/Directory/Analyzer) 해제. */
    @PreDestroy
    public void close() {
        Corpus c = cache;
        if (c != null) {
            c.lucene().close();
        }
    }
}