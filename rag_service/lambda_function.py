import json
import os
import boto3
import openai
import base64
import math

openai.api_key = os.environ["OPENAI_API_KEY"]

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["RAG_TABLE"]
BUCKET_NAME = os.environ["RAG_BUCKET"]

table = dynamodb.Table(TABLE_NAME)

def get_embedding(text: str):
    resp = openai.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return resp.data[0].embedding

def cosine_similarity(a, b):
    dot = sum(x*y for x, y in zip(a, b))
    na = math.sqrt(sum(x*x for x in a))
    nb = math.sqrt(sum(y*y for y in b))
    return dot / (na * nb + 1e-9)

def chunk_text(text, max_len=500):
    words = text.split()
    chunks = []
    cur = []
    cur_len = 0
    for w in words:
        cur.append(w)
        cur_len += 1
        if cur_len >= max_len:
            chunks.append(" ".join(cur))
            cur = []
            cur_len = 0
    if cur:
        chunks.append(" ".join(cur))
    return chunks

def handle_upload(body):
    filename = body.get("filename", "doc.txt")
    content_b64 = body.get("content_base64")
    if not content_b64:
        return {"statusCode": 400, "body": json.dumps({"error": "content_base64 missing"})}

    data = base64.b64decode(content_b64).decode("utf-8")

    # store raw file in S3
    s3.put_object(Bucket=BUCKET_NAME, Key=filename, Body=data.encode("utf-8"))

    chunks = chunk_text(data)
    for idx, chunk in enumerate(chunks):
        emb = get_embedding(chunk)
        table.put_item(
            Item={
                "doc_id": filename,
                "chunk_id": str(idx),
                "chunk_text": chunk,
                "embedding": json.dumps(emb)
            }
        )

    return {"statusCode": 200, "body": json.dumps({"status": "indexed", "chunks": len(chunks)})}

def handle_query(body):
    question = body.get("question")
    if not question:
        return {"statusCode": 400, "body": json.dumps({"error": "question missing"})}

    q_emb = get_embedding(question)

    # naive: scan table (fine for demo / portfolio)
    resp = table.scan()
    items = resp["Items"]

    scored = []
    for item in items:
        emb = json.loads(item["embedding"])
        score = cosine_similarity(q_emb, emb)
        scored.append((score, item))

    scored.sort(key=lambda x: x[0], reverse=True)
    top_chunks = [s[1]["chunk_text"] for s in scored[:5]]

    context = "\n\n".join(top_chunks)

    messages = [
        {"role": "system", "content": "You answer questions based only on the context provided."},
        {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {question}"}
    ]

    answer = openai.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages
    ).choices[0].message.content

    return {
        "statusCode": 200,
        "body": json.dumps({"answer": answer})
    }

def lambda_handler(event, context):
    body = json.loads(event.get("body", "{}"))
    path = event.get("rawPath", "/")

    if path.endswith("/upload"):
        return handle_upload(body)
    elif path.endswith("/query"):
        return handle_query(body)
    else:
        return {"statusCode": 404, "body": json.dumps({"error": "Not found"})}
