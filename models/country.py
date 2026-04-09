from __future__ import annotations

from pydantic import BaseModel


class CountryProfile(BaseModel):
    code: str
    name: str
    is_eu: bool
    base_risk: int = 0


COUNTRY_DATA: dict[str, CountryProfile] = {
    "CN": CountryProfile(code="CN", name="China", is_eu=False, base_risk=12),
    "CZ": CountryProfile(code="CZ", name="Czech Republic", is_eu=True, base_risk=0),
    "DE": CountryProfile(code="DE", name="Germany", is_eu=True, base_risk=0),
    "EE": CountryProfile(code="EE", name="Estonia", is_eu=True, base_risk=0),
    "FI": CountryProfile(code="FI", name="Finland", is_eu=True, base_risk=0),
    "IT": CountryProfile(code="IT", name="Italy", is_eu=True, base_risk=0),
    "LT": CountryProfile(code="LT", name="Lithuania", is_eu=True, base_risk=0),
    "LV": CountryProfile(code="LV", name="Latvia", is_eu=True, base_risk=0),
    "NO": CountryProfile(code="NO", name="Norway", is_eu=False, base_risk=2),
    "PL": CountryProfile(code="PL", name="Poland", is_eu=True, base_risk=0),
    "SE": CountryProfile(code="SE", name="Sweden", is_eu=True, base_risk=0),
    "TR": CountryProfile(code="TR", name="Turkey", is_eu=False, base_risk=8),
    "UA": CountryProfile(code="UA", name="Ukraine", is_eu=False, base_risk=6),
    "US": CountryProfile(code="US", name="United States", is_eu=False, base_risk=3),
}


NAME_INDEX = {profile.name.lower(): profile for profile in COUNTRY_DATA.values()}


def resolve_country(value: str | None) -> CountryProfile | None:
    if not value:
        return None
    normalized = value.strip()
    if not normalized:
        return None

    code = normalized.upper()
    if code in COUNTRY_DATA:
        return COUNTRY_DATA[code]

    return NAME_INDEX.get(normalized.lower())


def normalize_country_code(value: str | None) -> str | None:
    profile = resolve_country(value)
    if profile:
        return profile.code

    if not value:
        return None

    normalized = value.strip().upper()
    return normalized or None


def list_countries() -> list[CountryProfile]:
    return sorted(COUNTRY_DATA.values(), key=lambda item: item.name)
