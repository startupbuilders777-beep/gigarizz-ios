"""AI photo generation endpoints."""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.deps import get_generation_service, get_moderation_service, get_storage_service
from app.middleware.auth import verify_firebase_token
from app.models.database import GenerationJob, get_db
from app.models.schemas import GenerateRequest, GenerationJobResponse, JobStatus, ModelInfo
from app.services.generation_service import GenerationService, MODEL_CATALOG, OPENAI_MODELS
from app.services.moderation_service import ModerationService
from app.services.storage_service import StorageService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/generate", tags=["generation"])


@router.post("", response_model=GenerationJobResponse, status_code=status.HTTP_202_ACCEPTED)
async def create_generation(
    req: GenerateRequest,
    user: dict = Depends(verify_firebase_token),
    gen_svc: GenerationService = Depends(get_generation_service),
    mod_svc: ModerationService = Depends(get_moderation_service),
    db: AsyncSession = Depends(get_db),
):
    """Submit a new AI photo generation job.

    Returns a job ID that can be polled for status.
    """
    settings = get_settings()

    # Rate limit check (simple in-DB count, daily max = 50)
    now = datetime.now(timezone.utc)
    max_daily = 50
    result = await db.execute(
        select(GenerationJob).where(
            GenerationJob.user_id == user["uid"],
            GenerationJob.created_at >= now.replace(hour=0, minute=0, second=0),
        )
    )
    today_jobs = result.scalars().all()
    if len(today_jobs) >= max_daily:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Daily limit of {max_daily} generations reached",
        )

    # Moderate the prompt
    if req.prompt:
        mod_result = await mod_svc.check_text(req.prompt)
        if mod_result.get("flagged"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Content policy violation in prompt",
            )

    # Create job record
    job_id = gen_svc.generate_job_id()
    selected_model = req.model.value if req.model else "flux_schnell"
    job = GenerationJob(
        id=job_id,
        user_id=user["uid"],
        style=req.style.value,
        model=selected_model,
        custom_prompt=req.prompt,
        photo_count=req.photo_count,
        source_image_urls=[req.source_image_url] if req.source_image_url else [],
        status="processing",
        platform=req.platform,
    )
    db.add(job)
    await db.commit()

    # Submit to Replicate
    try:
        webhook_url = None
        if settings.webhook_base_url:
            webhook_url = f"{settings.webhook_base_url}/api/v1/generate/webhook"

        prediction_id = await gen_svc.create_prediction(
            job_id=job_id,
            style=req.style.value,
            source_image_urls=[req.source_image_url] if req.source_image_url else [],
            photo_count=req.photo_count,
            custom_prompt=req.prompt,
            webhook_url=webhook_url,
            model=selected_model,
        )

        job.replicate_prediction_id = prediction_id
        job.status = "processing"

        # OpenAI models return results synchronously
        openai_urls = gen_svc.pop_openai_results(prediction_id)
        if openai_urls:
            job.status = "completed"
            job.result_urls = openai_urls
            job.progress = 1.0
            job.completed_at = datetime.now(timezone.utc)

        await db.commit()

    except Exception as e:
        logger.error("Failed to submit generation: %s", e)
        job.status = "failed"
        job.error_message = str(e)
        await db.commit()
        raise HTTPException(status_code=500, detail="Failed to start generation")

    return GenerationJobResponse(
        job_id=job_id,
        status=JobStatus(job.status),
        style=req.style,
        model=selected_model,
        created_at=job.created_at,
        result_urls=job.result_urls or [],
    )


@router.get("/models", response_model=list[ModelInfo])
async def list_models():
    """List all available AI models for photo generation."""
    return [ModelInfo(**m) for m in MODEL_CATALOG]


@router.get("/{job_id}", response_model=GenerationJobResponse)
async def get_generation_status(
    job_id: str,
    user: dict = Depends(verify_firebase_token),
    gen_svc: GenerationService = Depends(get_generation_service),
    db: AsyncSession = Depends(get_db),
):
    """Check the status of a generation job. Polls Replicate if still processing."""
    result = await db.execute(
        select(GenerationJob).where(
            GenerationJob.id == job_id,
            GenerationJob.user_id == user["uid"],
        )
    )
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Poll Replicate / fal.ai if still processing
    if job.status == "processing" and job.replicate_prediction_id:
        try:
            pred = await gen_svc.check_prediction(job.replicate_prediction_id, model=job.model)
            replicate_status = pred.get("status", "")

            if replicate_status == "succeeded":
                output = pred.get("output")
                urls = output if isinstance(output, list) else [output] if output else []
                job.status = "completed"
                job.result_urls = urls
                job.progress = 1.0
                job.completed_at = datetime.now(timezone.utc)
                await db.commit()
            elif replicate_status == "failed":
                job.status = "failed"
                job.error_message = pred.get("error", "Generation failed")
                await db.commit()
            elif replicate_status == "processing":
                logs = pred.get("logs", "")
                if logs:
                    # Try to parse progress from logs
                    lines = logs.strip().split("\n")
                    if lines:
                        last = lines[-1]
                        if "%" in last:
                            try:
                                pct = float(last.split("%")[0].strip().split()[-1])
                                job.progress = pct / 100.0
                                await db.commit()
                            except (ValueError, IndexError):
                                pass
        except Exception as e:
            logger.warning("Failed to poll Replicate for job %s: %s", job_id, e)

    return GenerationJobResponse(
        job_id=job.id,
        status=JobStatus(job.status),
        style=job.style,
        model=job.model,
        progress=job.progress,
        result_urls=job.result_urls or [],
        error=job.error_message,
        created_at=job.created_at,
        completed_at=job.completed_at,
    )


@router.post("/webhook")
async def generation_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """Webhook callback from Replicate when generation completes."""
    settings = get_settings()

    # Verify webhook secret
    webhook_secret = request.headers.get("X-Webhook-Secret")
    if settings.webhook_secret and webhook_secret != settings.webhook_secret:
        raise HTTPException(status_code=403, detail="Invalid webhook secret")

    payload = await request.json()
    prediction_id = payload.get("id")
    prediction_status = payload.get("status")

    if not prediction_id:
        raise HTTPException(status_code=400, detail="Missing prediction ID")

    result = await db.execute(
        select(GenerationJob).where(
            GenerationJob.replicate_prediction_id == prediction_id
        )
    )
    job = result.scalar_one_or_none()
    if not job:
        logger.warning("Webhook received for unknown prediction: %s", prediction_id)
        return {"status": "ignored"}

    if prediction_status == "succeeded":
        output = payload.get("output")
        urls = output if isinstance(output, list) else [output] if output else []
        job.status = "completed"
        job.result_urls = urls
        job.progress = 1.0
        job.completed_at = datetime.now(timezone.utc)
    elif prediction_status == "failed":
        job.status = "failed"
        job.error_message = payload.get("error", "Generation failed")
    elif prediction_status == "canceled":
        job.status = "failed"
        job.error_message = "Generation was canceled"

    await db.commit()
    return {"status": "ok"}


@router.delete("/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_generation(
    job_id: str,
    user: dict = Depends(verify_firebase_token),
    gen_svc: GenerationService = Depends(get_generation_service),
    db: AsyncSession = Depends(get_db),
):
    """Cancel a running generation job."""
    result = await db.execute(
        select(GenerationJob).where(
            GenerationJob.id == job_id,
            GenerationJob.user_id == user["uid"],
        )
    )
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status != "processing":
        return  # Already done

    if job.replicate_prediction_id:
        try:
            await gen_svc.cancel_prediction(job.replicate_prediction_id, model=job.model)
        except Exception as e:
            logger.warning("Failed to cancel Replicate prediction: %s", e)

    job.status = "failed"
    job.error_message = "Canceled by user"
    await db.commit()
