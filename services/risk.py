from __future__ import annotations

from collections.abc import Callable

from config.settings import get_settings
from models.country import resolve_country
from models.invoice import (
    AssessmentPayload,
    ComplianceChoice,
    DocumentStatus,
    RiskBreakdownItem,
    RiskLevel,
    RiskSummary,
)


settings = get_settings()


def _has_document(status: DocumentStatus, files: list[str]) -> bool:
    return status in {DocumentStatus.uploaded, DocumentStatus.verified} or bool(files)


def _has_memo(value: str | None) -> bool:
    return bool(value and value.strip())


def _answered(choice: ComplianceChoice) -> bool:
    return choice != ComplianceChoice.unknown


CheckFn = Callable[[AssessmentPayload], bool]


CHECKS: list[tuple[str, str, int, CheckFn]] = [
    ("certificate_document", "Certificate", 50, lambda a: _has_document(a.certificate.status, a.certificate.files)),
    ("certificate_memo", "Certificate memo", 2, lambda a: _has_memo(a.certificate.memo)),
    (
        "location_pictures_document",
        "Location pictures",
        10,
        lambda a: _has_document(a.location_pictures.status, a.location_pictures.files),
    ),
    ("location_pictures_memo", "Location memo", 2, lambda a: _has_memo(a.location_pictures.memo)),
    ("notice_document", "Notice", 10, lambda a: _has_document(a.notice.status, a.notice.files)),
    ("notice_memo", "Notice memo", 2, lambda a: _has_memo(a.notice.memo)),
    (
        "wood_specification",
        "Wood specification",
        10,
        lambda a: bool(a.wood_species or a.material_types or _has_memo(a.wood_specification_memo)),
    ),
    ("country_of_origin", "Country of origin", 5, lambda a: _has_memo(a.country_of_origin)),
    ("quantity", "Quantity", 10, lambda a: a.quantity is not None),
    ("delivery_date", "Delivery date", 2, lambda a: a.delivery_date is not None),
    ("child_labor", "Child labor response", 10, lambda a: _answered(a.child_labor_ok)),
    ("human_rights", "Human rights response", 10, lambda a: _answered(a.human_rights_ok)),
    (
        "geolocation_screenshot",
        "Geolocation screenshot",
        10,
        lambda a: _has_document(a.geolocation_screenshot.status, a.geolocation_screenshot.files),
    ),
    (
        "geolocation_data",
        "Geolocation data",
        7,
        lambda a: (a.geolocation_latitude is not None and a.geolocation_longitude is not None)
        or _has_memo(a.geolocation_source_text),
    ),
    ("personal_risk_level", "Personal risk assessment", 5, lambda a: a.personal_risk_level is not None),
    ("risk_reason", "Risk rationale", 10, lambda a: _has_memo(a.risk_reason)),
    ("others", "Other evidence", 2, lambda a: _has_document(a.others.status, a.others.files) or _has_memo(a.others.memo)),
    (
        "transport_papers_document",
        "Transport papers",
        13,
        lambda a: _has_document(a.transport_papers.status, a.transport_papers.files),
    ),
    ("transport_papers_memo", "Transport memo", 2, lambda a: _has_memo(a.transport_papers.memo)),
]


def calculate_risk(
    assessment: AssessmentPayload,
    company_country: str | None = None,
) -> RiskSummary:
    breakdown: list[RiskBreakdownItem] = []
    coverage_score = 0
    coverage_total = sum(weight for _, _, weight, _ in CHECKS)

    for key, label, weight, predicate in CHECKS:
        completed = predicate(assessment)
        awarded = weight if completed else 0
        coverage_score += awarded
        breakdown.append(
            RiskBreakdownItem(
                key=key,
                label=label,
                weight=weight,
                completed=completed,
                awarded_points=awarded,
            )
        )

    coverage_percent = round((coverage_score / coverage_total) * 100, 1) if coverage_total else 0.0
    penalty_points = 0
    blockers: list[str] = []

    if not _has_document(assessment.certificate.status, assessment.certificate.files):
        penalty_points += 25
        blockers.append("Certificate is missing.")

    if not _has_document(assessment.transport_papers.status, assessment.transport_papers.files):
        penalty_points += 10
        blockers.append("Transport papers are missing.")

    if (
        not _has_document(assessment.geolocation_screenshot.status, assessment.geolocation_screenshot.files)
        and not (
            assessment.geolocation_latitude is not None
            and assessment.geolocation_longitude is not None
        )
    ):
        penalty_points += 10
        blockers.append("No geolocation proof attached.")

    if assessment.child_labor_ok == ComplianceChoice.no:
        penalty_points += 20
        blockers.append("Child labor concern flagged.")

    if assessment.human_rights_ok == ComplianceChoice.no:
        penalty_points += 20
        blockers.append("Human rights concern flagged.")

    if assessment.personal_risk_level == RiskLevel.medium:
        penalty_points += 10
    elif assessment.personal_risk_level == RiskLevel.high:
        penalty_points += 20
        blockers.append("Reviewer marked this invoice as high risk.")

    country = resolve_country(company_country)
    if company_country and not country:
        penalty_points += 5
        blockers.append("Supplier country is unknown.")
    elif country and not country.is_eu:
        penalty_points += country.base_risk
        blockers.append(f"Supplier country {country.name} is outside the EU.")

    if not assessment.country_of_origin:
        penalty_points += 5
        blockers.append("Wood origin country is not filled.")

    risk_score = round(max(0.0, min(100.0, (100.0 - coverage_percent) + penalty_points)), 1)
    if risk_score >= settings.medium_risk_threshold:
        risk_level = RiskLevel.high
    elif risk_score >= settings.low_risk_threshold:
        risk_level = RiskLevel.medium
    else:
        risk_level = RiskLevel.low

    missing_sections = [item.label for item in breakdown if not item.completed][:6]
    return RiskSummary(
        coverage_score=coverage_score,
        coverage_total=coverage_total,
        coverage_percent=coverage_percent,
        penalty_points=penalty_points,
        risk_score=risk_score,
        risk_percent=risk_score,
        risk_level=risk_level,
        blockers=blockers,
        missing_sections=missing_sections,
        breakdown=breakdown,
    )
