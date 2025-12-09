import json
import os
import openai

openai.api_key = os.environ["OPENAI_API_KEY"]

SYSTEM_PROMPT = """
You are a senior DevOps engineer.
Given CI/CD logs, you MUST respond with three sections:

[ROOT_CAUSE]
- Short explanation of why it failed.

[FIX]
- Step-by-step fix in plain language.

[YAML_PATCH]
- If relevant, a YAML snippet or code block to apply.
"""

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
        log_text = body.get("log", "")

        if not log_text:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing 'log' in body"})
            }

        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"Here are the logs:\n\n{log_text[:6000]}"}  # truncate for safety
        ]

        response = openai.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages
        )

        answer = response.choices[0].message.content

        return {
            "statusCode": 200,
            "body": json.dumps({"analysis": answer})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
