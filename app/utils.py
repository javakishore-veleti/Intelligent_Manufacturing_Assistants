import os
from langchain_openai import OpenAIEmbeddings
from langchain_postgres.v2.engine import PGEngine
from langchain_postgres.v2.async_vectorstore import AsyncPGVectorStore

PG_CONN_STR = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@localhost:5432/postgres")
PG_ENGINE = PGEngine.from_connection_string(PG_CONN_STR)

embeddings = OpenAIEmbeddings(model="text-embedding-3-small", dimensions=1024)


async def get_vector_store() -> AsyncPGVectorStore:
    return await AsyncPGVectorStore.create(
        engine=PG_ENGINE,
        embedding_service=embeddings,
        table_name="langchain_pg_embedding",
        metadata_json_column="langchain_metadata",
        metadata_columns=["category"]
    )
