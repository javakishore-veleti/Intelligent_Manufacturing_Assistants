from __future__ import annotations

import os
from typing import List, Tuple

from langchain_classic.docstore.document import Document

from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_classic.chains.combine_documents import create_stuff_documents_chain
from langchain_classic.chains import create_retrieval_chain

from langchain_core.globals import set_llm_cache
from langchain_redis import RedisSemanticCache

from .utils import get_vector_store

from langchain_cohere import CohereRerank
from langchain_classic.retrievers import ContextualCompressionRetriever

SYSTEM = """You are a grouded and helpful Intelligent Manufacturing Assistant (IMA) for answering questions based on retrieved documents.
Always base answers strictly on the provided context. If the answer is not present, reply with "I don't know". Be concise and to the point and clearly.
"""

PROMPT = ChatPromptTemplate.from_messages([
    ("system", SYSTEM),
    ("user",
     "Question:\n{input}\n\n"
     "Context:\n{context}\n\n"
     "Rule: Prefer the most recent policy by effective date.")
])

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

set_llm_cache(RedisSemanticCache(redis_url=REDIS_URL, embeddings=embeddings, distance_threshold=0.98))


async def _build_chain(category:str = None):
    store = await get_vector_store()
    search_kwargs={"k": int(os.getenv("RETRIEVAL_K","5"))}

    if category:
        search_kwargs["filter"] = {"category": category}

    base_retriever = store.as_retriever(search_kwargs=search_kwargs)
    compressor = CohereRerank(model = "rerank-multilingual-v3.0", top_n=3)

    retriever = ContextualCompressionRetriever(
        base_retriever=base_retriever,
        base_compressor=compressor
    )
    llm = ChatOpenAI(model="gpt-4o-mini")
    doc_chain = create_stuff_documents_chain(llm, PROMPT)
    rag_chain = create_retrieval_chain(retriever, doc_chain)
    return rag_chain


async def answer_with_docs_async(question: str, category: str):
    chain = await _build_chain(category)
    result = await chain.ainvoke({"input": question})
    answer = result["answer"]

    docs = result["context"]

    unique_sources = {d.metadata.get("source") for d in docs if d.metadata.get("source")}
    sources = sorted(unique_sources)

    contexts = []
    for d in docs:
        contexts.append(d.page_content)

    return answer, sources, contexts