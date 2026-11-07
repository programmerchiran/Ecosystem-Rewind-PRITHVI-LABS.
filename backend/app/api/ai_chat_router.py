
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from backend.app.services.ai_chat_service import (
    generate_ecological_response,
)

router = APIRouter(
    prefix="/ai",
    tags=["EcoMind AI"],
)


class ChatRequest(BaseModel):
    message: str = Field(
        min_length=1,
        max_length=4000,
    )


class ChatResponse(BaseModel):
    answer: str
    model: str


@router.post("/chat", response_model=ChatResponse)
async def chat_with_ecomind(request: ChatRequest):
    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=422,
            detail="Message cannot be empty.",
        )

    answer = await generate_ecological_response(message)

    return ChatResponse(
        answer=answer,
        model="EcoMind AI",
    )
