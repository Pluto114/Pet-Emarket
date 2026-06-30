# Pet-Emarket Vector Store — Knowledge Base Design

> **Role**: Stores embedding vectors for AI RAG (Retrieval-Augmented Generation) chat,  
> enabling semantic search over pet-care knowledge, product info, and FAQ documents.  
> **Provider**: MongoDB Atlas Vector Search / local MongoDB with `$vectorSearch` aggregation.

---

## 1. Collection Design

### `knowledge_chunks`

Stores document chunks with their embedding vectors for semantic retrieval.

| Field | Type | Description |
|---|---|---|
| `_id` | ObjectId | Auto-generated |
| `chunk_id` | String | Unique chunk identifier, e.g. `"faq-cat-diet-001"` |
| `source` | String | Document source type: `faq`, `care_guide`, `product_desc`, `policy` |
| `title` | String | Chunk title summary |
| `content` | String | Chunk text content (max ~512 tokens) |
| `embedding` | Array[Double] | Embedding vector (e.g., 1536 dimensions for text-embedding-3-small) |
| `metadata` | Object | `{category, tags, relatedProductIds, language}` |
| `created_at` | Date | Chunk creation timestamp |
| `updated_at` | Date | Last update timestamp |

### Example Document

```json
{
  "_id": ObjectId("..."),
  "chunk_id": "care-cat-feeding-001",
  "source": "care_guide",
  "title": "How much should I feed my kitten per day?",
  "content": "Kittens under 6 months should be fed 3-4 times a day with high-protein kitten food. Adult cats (1-7 years) can be fed 2 times a day. Always provide fresh water and avoid giving cow milk as it can cause digestive issues.",
  "embedding": [0.012, -0.034, ..., 0.089],
  "metadata": {
    "category": "Feeding",
    "tags": ["kitten", "diet", "nutrition"],
    "relatedProductIds": [4, 5],
    "language": "zh-CN"
  },
  "created_at": ISODate("2026-01-15T00:00:00Z"),
  "updated_at": ISODate("2026-06-01T00:00:00Z")
}
```

---

## 2. Index Configuration

### Vector Index (MongoDB Atlas)

```json
{
  "name": "idx_knowledge_vector",
  "type": "vectorSearch",
  "fields": [
    {
      "path": "embedding",
      "similarity": "cosine",
      "numDimensions": 1536
    }
  ]
}
```

- **Index name**: `idx_knowledge_vector`
- **Similarity metric**: cosine (preferred for text embeddings)
- **Dimensions**: 1536 (OpenAI text-embedding-3-small)

### Secondary Indexes

```javascript
// Source + category filter index
db.knowledge_chunks.createIndex(
  { source: 1, "metadata.category": 1 },
  { name: "idx_knowledge_source_category" }
);

// Full-text search fallback
db.knowledge_chunks.createIndex(
  { content: "text", title: "text" },
  { name: "idx_knowledge_fulltext" }
);
```

---

## 3. Data Population

### Seed Script

Two seed scripts already exist in `ai-recommendation-service/scripts/`:

| Script | Records | Description |
|---|---|---|
| `seed_knowledge.js` | 10 docs | Core FAQ and care guides (cat/dog basics) |
| `seed_knowledge_v2.js` | 16 docs | Extended knowledge base with more detailed care topics |

Run via:

```bash
# From project root
mongosh pet_emarket < ai-recommendation-service/scripts/seed_knowledge.js
mongosh pet_emarket < ai-recommendation-service/scripts/seed_knowledge_v2.js
```

---

## 4. Query Pattern (RAG Retrieval)

```javascript
// Semantic search: find top-5 relevant chunks for a user question
db.knowledge_chunks.aggregate([
  {
    "$vectorSearch": {
      "queryVector": <user_question_embedding>,
      "path": "embedding",
      "numCandidates": 50,
      "limit": 5,
      "index": "idx_knowledge_vector"
    }
  },
  {
    "$project": {
      "chunk_id": 1,
      "title": 1,
      "content": 1,
      "source": 1,
      "metadata": 1,
      "score": { "$meta": "vectorSearchScore" }
    }
  }
]);
```

### Fallback Strategy

1. **Primary**: Vector search with cosine similarity (threshold > 0.75)
2. **Fallback**: Full-text search on `content` and `title` fields using regex matching
3. **Last resort**: Return general greeting / FAQ default response

---

## 5. Maintenance

| Task | Frequency | Action |
|---|---|---|
| Re-embed updated chunks | On content change | `UPDATE` → recompute embedding with LLM API |
| Archive stale chunks | Monthly | Mark `metadata.stale: true` for chunks > 6 months without updates |
| Monitor cache hit rate | Dashboard | If < 60%, re-evaluate chunk size or embedding model |
