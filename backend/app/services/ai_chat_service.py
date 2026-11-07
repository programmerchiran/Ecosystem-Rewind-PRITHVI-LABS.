
import httpx

from fastapi import HTTPException
from backend.app.config import settings


SYSTEM_PROMPT = """
You are EcoMind AI, the ecological intelligence assistant
developed by PRITHVI LABS.

Your purpose is to help people understand and protect ecosystems.

You specialize in:
- Ecosystems and biodiversity
- Native plants and trees
- Wildlife and species conservation
- Habitat degradation and fragmentation
- Climate and environmental threats
- Ecological restoration
- Conservation planning

Guidelines:
1. Give clear, scientifically responsible answers.
2. Never invent species observations or local biodiversity records.
3. Distinguish observed information from model predictions.
4. Never treat habitat suitability as proof of species presence.
5. Explain uncertainty when information is insufficient.
6. Recommend locally appropriate conservation practices.
7. Encourage expert field verification for important decisions.
8. Use the user's selected ecosystem context when provided.

Be practical, helpful and environmentally responsible.
"""


async def generate_ecological_response(message: str) -> str:
    """Generate an ecological answer using the deployed Nugen model."""

    if not settings.NUGEN_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="Nugen API key is not configured."
        )

    if not settings.NUGEN_MODEL_ID:
        raise HTTPException(
            status_code=503,
            detail="Nugen model ID is not configured."
        )

    headers = {
        "Authorization": f"Bearer {settings.NUGEN_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": settings.NUGEN_MODEL_ID,
        "messages": [
            {
                "role": "system",
                "content": SYSTEM_PROMPT,
            },
            {
                "role": "user",
                "content": message,
            },
        ],
        "max_tokens": 600,
        "temperature": 0.4,
        "stream": False,
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                settings.NUGEN_API_URL,
                headers=headers,
                json=payload,
            )

            response.raise_for_status()
            result = response.json()

        answer = result["choices"][0]["message"]["content"]

        if not isinstance(answer, str) or not answer.strip():
            raise ValueError("Nugen returned an empty response.")

        return answer.strip()

    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="EcoMind AI timed out while generating a response."
        )

    except httpx.HTTPStatusError as exc:
        print(
            "Nugen inference failed:",
            exc.response.status_code,
            exc.response.text[:500],
        )
        raise HTTPException(
            status_code=502,
            detail="Nugen inference request failed. Check the model deployment and API configuration."
        )

    except (KeyError, IndexError, ValueError, TypeError):
        raise HTTPException(
            status_code=502,
            detail="Nugen returned an unexpected response format."
        )

    except httpx.RequestError:
        raise HTTPException(
            status_code=502,
            detail="Could not connect to the Nugen inference service."
        )
