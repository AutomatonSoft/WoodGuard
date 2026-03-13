from __future__ import annotations

import io
import mimetypes
import re
import shutil
from pathlib import Path, PurePosixPath
from uuid import uuid4

import boto3
from botocore.client import Config
from fastapi import HTTPException, UploadFile

from config.settings import get_settings
from models.invoice import UploadResponse


def _sanitize_filename(original_name: str) -> str:
    suffix = Path(original_name).suffix.lower()
    stem = Path(original_name).stem
    safe_stem = re.sub(r"[^a-zA-Z0-9_-]+", "-", stem).strip("-") or "file"
    return f"{safe_stem}-{uuid4().hex[:10]}{suffix}"


def _build_object_key(*parts: str | int | None) -> str:
    normalized = [str(part).strip("/").strip() for part in parts if part not in {None, ""}]
    prefix = get_settings().s3_key_prefix.strip("/")
    key = PurePosixPath(prefix, *normalized).as_posix() if prefix else PurePosixPath(*normalized).as_posix()
    return key


def _guess_content_type(filename: str, fallback: str | None) -> str:
    guessed, _ = mimetypes.guess_type(filename)
    return fallback or guessed or "application/octet-stream"


def _local_upload(file: UploadFile, object_key: str, filename: str) -> UploadResponse:
    settings = get_settings()
    upload_dir = Path(settings.upload_dir)
    destination = upload_dir / Path(object_key)
    destination.parent.mkdir(parents=True, exist_ok=True)

    with destination.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    url_path = PurePosixPath(settings.public_upload_prefix.strip("/"), *Path(object_key).parts).as_posix()
    return UploadResponse(
        filename=filename,
        url=f"/{url_path}",
        content_type=file.content_type,
        size_bytes=destination.stat().st_size,
        storage_backend="local",
        object_key=object_key,
    )


def _build_s3_client():
    settings = get_settings()
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint_url,
        region_name=settings.s3_region_name,
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_secret_access_key,
        config=Config(signature_version="s3v4"),
    )


def _s3_upload(file: UploadFile, object_key: str, filename: str) -> UploadResponse:
    settings = get_settings()
    if not settings.s3_bucket_name:
        raise HTTPException(status_code=500, detail="S3 bucket is not configured.")

    payload = file.file.read()
    size_bytes = len(payload)
    content_type = _guess_content_type(filename, file.content_type)
    client = _build_s3_client()
    client.upload_fileobj(
        io.BytesIO(payload),
        settings.s3_bucket_name,
        object_key,
        ExtraArgs={"ContentType": content_type},
    )

    if settings.s3_public_base_url:
        base_url = settings.s3_public_base_url.rstrip("/")
        url = f"{base_url}/{object_key}"
    else:
        url = client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket_name, "Key": object_key},
            ExpiresIn=settings.s3_presign_expire_seconds,
        )

    return UploadResponse(
        filename=filename,
        url=url,
        content_type=content_type,
        size_bytes=size_bytes,
        storage_backend="s3",
        object_key=object_key,
    )


def save_upload(
    file: UploadFile,
    *,
    folder: str | None = None,
    invoice_id: int | None = None,
    section: str | None = None,
) -> UploadResponse:
    settings = get_settings()
    original_name = file.filename or "upload.bin"
    filename = _sanitize_filename(original_name)
    object_key = _build_object_key(folder or "uploads", invoice_id, section, filename)

    if settings.storage_backend == "s3":
        return _s3_upload(file, object_key, filename)
    if settings.storage_backend == "local":
        return _local_upload(file, object_key, filename)

    raise HTTPException(status_code=500, detail=f"Unsupported storage backend: {settings.storage_backend}")
