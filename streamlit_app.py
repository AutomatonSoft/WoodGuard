from __future__ import annotations

import os
from typing import Any

import httpx
import streamlit as st


API_DEFAULT = os.getenv("WOODGUARD_API_URL", "http://127.0.0.1:8000/api/v1")
EVIDENCE_FIELDS = [
    ("certificate", "Certificate"),
    ("location_pictures", "Location Pictures"),
    ("notice", "Notice"),
    ("transport_papers", "Transport Papers"),
    ("geolocation_screenshot", "Geolocation Screenshot"),
    ("others", "Other Evidence"),
]


def api_request(method: str, api_base: str, path: str, token: str | None = None, **kwargs: Any) -> Any:
    headers = kwargs.pop("headers", {})
    if token:
        headers["Authorization"] = f"Bearer {token}"
    with httpx.Client(timeout=30.0) as client:
        response = client.request(method, f"{api_base}{path}", headers=headers, **kwargs)
        if response.status_code == 401 and not path.startswith("/auth/"):
            refreshed = refresh_session(api_base)
            if refreshed:
                headers["Authorization"] = f"Bearer {st.session_state['auth_token']}"
                response = client.request(method, f"{api_base}{path}", headers=headers, **kwargs)
        response.raise_for_status()
        if response.status_code == 204:
            return None
        return response.json()


def store_login_session(login_response: dict[str, Any]) -> None:
    st.session_state["auth_token"] = login_response["access_token"]
    st.session_state["refresh_token"] = login_response["refresh_token"]
    st.session_state["current_user"] = login_response["user"]


def clear_login_session() -> None:
    st.session_state["auth_token"] = None
    st.session_state["refresh_token"] = None
    st.session_state["current_user"] = None


def refresh_session(api_base: str) -> dict[str, Any] | None:
    refresh_token = st.session_state.get("refresh_token")
    if not refresh_token:
        clear_login_session()
        return None

    with httpx.Client(timeout=30.0) as client:
        response = client.post(
            f"{api_base}/auth/refresh",
            json={"refresh_token": refresh_token},
        )

    if response.status_code != 200:
        clear_login_session()
        return None

    payload = response.json()
    store_login_session(payload)
    return payload


def logout_session(api_base: str) -> None:
    refresh_token = st.session_state.get("refresh_token")
    if refresh_token:
        try:
            with httpx.Client(timeout=15.0) as client:
                client.post(f"{api_base}/auth/logout", json={"refresh_token": refresh_token})
        except httpx.HTTPError:
            pass
    clear_login_session()


def upload_files(api_base: str, token: str, invoice_id: int, section: str, files: list[Any]) -> list[str]:
    urls: list[str] = []
    for file in files:
        with httpx.Client(timeout=60.0) as client:
            response = client.post(
                f"{api_base}/uploads",
                headers={"Authorization": f"Bearer {token}"},
                data={"invoice_id": str(invoice_id), "section": section},
                files={"file": (file.name, file.getvalue(), file.type or "application/octet-stream")},
            )
            if response.status_code == 401:
                refreshed = refresh_session(api_base)
                if refreshed:
                    response = client.post(
                        f"{api_base}/uploads",
                        headers={"Authorization": f"Bearer {st.session_state['auth_token']}"},
                        data={"invoice_id": str(invoice_id), "section": section},
                        files={"file": (file.name, file.getvalue(), file.type or "application/octet-stream")},
                    )
            response.raise_for_status()
            urls.append(response.json()["url"])
    return urls


st.set_page_config(page_title="Woodguard Console", layout="wide")
st.title("Woodguard Test Console")

api_base = st.sidebar.text_input("API Base", value=API_DEFAULT)
st.session_state.setdefault("auth_token", None)
st.session_state.setdefault("refresh_token", None)
st.session_state.setdefault("current_user", None)

with st.sidebar.form("login_form"):
    st.subheader("Login")
    login_username = st.text_input("Username", value="admin")
    login_password = st.text_input("Password", value="woodguard123", type="password")
    login_submit = st.form_submit_button("Sign in")

if login_submit:
    try:
        login_response = api_request(
            "POST",
            api_base,
            "/auth/login",
            json={"username": login_username, "password": login_password},
        )
        store_login_session(login_response)
        st.sidebar.success(f"Signed in as {login_response['user']['username']}")
    except Exception as exc:  # noqa: BLE001
        st.sidebar.error(str(exc))

if st.session_state["auth_token"] and st.sidebar.button("Logout", use_container_width=True):
    logout_session(api_base)
    st.rerun()

if not st.session_state["auth_token"]:
    st.info("Sign in with the bootstrap admin or another user before using the console.")
    st.stop()

token = st.session_state["auth_token"]
current_user = st.session_state["current_user"]
st.sidebar.caption(f"{current_user['username']} | {current_user['role']}")

if st.sidebar.button("Sync Warehub", use_container_width=True):
    try:
        api_request("POST", api_base, "/invoices/sync/warehub", token=token, json={})
        st.sidebar.success("Warehub sync completed.")
        st.rerun()
    except Exception as exc:  # noqa: BLE001
        st.sidebar.error(str(exc))

with st.sidebar.form("manual_invoice"):
    st.subheader("Create Manual Invoice")
    manual_number = st.text_input("Invoice number")
    manual_company = st.text_input("Company name")
    manual_country = st.text_input("Country code", value="TR")
    manual_amount = st.number_input("Amount", min_value=0.0, step=100.0)
    manual_submit = st.form_submit_button("Create")

if manual_submit:
    try:
        api_request(
            "POST",
            api_base,
            "/invoices",
            token=token,
            json={
                "invoice_number": manual_number,
                "company_name": manual_company or None,
                "company_country": manual_country or None,
                "amount": manual_amount,
                "status": "pending",
            },
        )
        st.sidebar.success("Manual invoice created.")
        st.rerun()
    except Exception as exc:  # noqa: BLE001
        st.sidebar.error(str(exc))

try:
    metrics = api_request("GET", api_base, "/dashboard/metrics", token=token)
    invoices = api_request("GET", api_base, "/invoices", token=token)["items"]
    reference = api_request("GET", api_base, "/reference/options", token=token)
except Exception as exc:  # noqa: BLE001
    st.error(str(exc))
    st.stop()

metric_columns = st.columns(5)
metric_columns[0].metric("Invoices", metrics["total_invoices"])
metric_columns[1].metric("Open Exposure", f"EUR {round(metrics['open_exposure'])}")
metric_columns[2].metric("Coverage Avg", f"{round(metrics['average_coverage'])}%")
metric_columns[3].metric("High Risk", metrics["high_risk_count"])
metric_columns[4].metric("Non-EU Suppliers", metrics["non_eu_suppliers"])

if not invoices:
    st.info("No invoices available yet. Sync Warehub or create one manually.")
    st.stop()

label_map = {
    f"{invoice['invoice_number']} | {invoice.get('company_name') or 'Unassigned'} | {invoice['status']}": invoice["id"]
    for invoice in invoices
}
selected_label = st.selectbox("Invoice dossier", options=list(label_map))
selected_invoice_id = label_map[selected_label]
detail = api_request("GET", api_base, f"/invoices/{selected_invoice_id}", token=token)
audit_logs = api_request("GET", api_base, f"/invoices/{selected_invoice_id}/audit-logs", token=token)["items"]

overview_tab, assessment_tab, risk_tab, audit_tab = st.tabs(["Overview", "Assessment", "Risk", "Audit"])

with overview_tab:
    with st.form("overview_form"):
        left, right = st.columns(2)
        country_options = [""] + [country["code"] for country in reference["countries"]]
        current_country = detail.get("company_country") or ""
        company_name = left.text_input("Company name", value=detail.get("company_name") or "")
        company_country = left.selectbox(
            "Country",
            options=country_options,
            index=country_options.index(current_country) if current_country in country_options else 0,
        )
        status = left.selectbox("Status", options=["pending", "partial", "paid", "cancelled", "draft", "unknown"], index=["pending", "partial", "paid", "cancelled", "draft", "unknown"].index(detail["status"]))
        amount = left.number_input("Amount", min_value=0.0, value=float(detail["amount"]), step=100.0)
        remaining_amount = left.number_input("Remaining amount", min_value=0.0, value=float(detail["remaining_amount"]), step=100.0)
        invoice_date = right.text_input("Invoice date", value=detail.get("invoice_date") or "")
        due_date = right.text_input("Due date", value=detail.get("due_date") or "")
        seller_name = right.text_input("Seller name", value=detail.get("seller_name") or "")
        seller_email = right.text_input("Seller email", value=detail.get("seller_email") or "")
        seller_phone = right.text_input("Seller phone", value=detail.get("seller_phone") or "")
        seller_address = st.text_area("Seller address", value=detail.get("seller_address") or "")
        notes = st.text_area("Internal notes", value=detail.get("notes") or "")
        overview_submit = st.form_submit_button("Save metadata")

    if overview_submit:
        payload = {
            "company_name": company_name or None,
            "company_country": company_country or None,
            "status": status,
            "amount": amount,
            "remaining_amount": remaining_amount,
            "invoice_date": invoice_date or None,
            "due_date": due_date or None,
            "seller_name": seller_name or None,
            "seller_email": seller_email or None,
            "seller_phone": seller_phone or None,
            "seller_address": seller_address or None,
            "notes": notes or None,
        }
        api_request("PUT", api_base, f"/invoices/{detail['id']}", token=token, json=payload)
        st.success("Metadata saved. Refresh the page to see updated metrics.")
        st.rerun()

with assessment_tab:
    assessment = detail["assessment"]
    with st.form("assessment_form"):
        upload_buffers: dict[str, list[Any]] = {}
        for field, label in EVIDENCE_FIELDS:
            current = assessment[field]
            st.markdown(f"### {label}")
            cols = st.columns([1, 1])
            assessment[field]["status"] = cols[0].selectbox(
                f"{label} status",
                options=["missing", "uploaded", "verified"],
                index=["missing", "uploaded", "verified"].index(current["status"]),
                key=f"{field}_status",
            )
            assessment[field]["memo"] = cols[1].text_input(
                f"{label} memo",
                value=current.get("memo") or "",
                key=f"{field}_memo",
            )
            upload_buffers[field] = st.file_uploader(
                f"{label} files",
                accept_multiple_files=True,
                key=f"{field}_files",
            )
            existing = current.get("files") or []
            if existing:
                st.caption("Current files: " + ", ".join(path.split("/")[-1] for path in existing))

        assessment["wood_species"] = st.multiselect("Wood species", options=reference["wood_species"], default=assessment.get("wood_species") or [])
        assessment["material_types"] = st.multiselect("Material types", options=reference["material_types"], default=assessment.get("material_types") or [])
        assessment["wood_specification_memo"] = st.text_area("Wood specification memo", value=assessment.get("wood_specification_memo") or "")
        cols = st.columns(3)
        assessment["country_of_origin"] = cols[0].text_input("Country of origin", value=assessment.get("country_of_origin") or "")
        assessment["quantity"] = cols[1].number_input("Quantity", min_value=0.0, value=float(assessment.get("quantity") or 0.0))
        assessment["quantity_unit"] = cols[2].text_input("Unit", value=assessment.get("quantity_unit") or "")
        cols = st.columns(3)
        assessment["child_labor_ok"] = cols[0].selectbox("Child labor", options=["unknown", "yes", "no"], index=["unknown", "yes", "no"].index(assessment.get("child_labor_ok") or "unknown"))
        assessment["human_rights_ok"] = cols[1].selectbox("Human rights", options=["unknown", "yes", "no"], index=["unknown", "yes", "no"].index(assessment.get("human_rights_ok") or "unknown"))
        assessment["personal_risk_level"] = cols[2].selectbox("Personal risk", options=["", "low", "medium", "high"], index=["", "low", "medium", "high"].index(assessment.get("personal_risk_level") or ""))
        cols = st.columns(3)
        assessment["geolocation_latitude"] = cols[0].number_input("Geo latitude", value=float(assessment.get("geolocation_latitude") or 0.0))
        assessment["geolocation_longitude"] = cols[1].number_input("Geo longitude", value=float(assessment.get("geolocation_longitude") or 0.0))
        assessment["delivery_date"] = cols[2].text_input("Delivery date", value=assessment.get("delivery_date") or "")
        assessment["geolocation_source_text"] = st.text_input("Geo source", value=assessment.get("geolocation_source_text") or "")
        assessment["risk_reason"] = st.text_area("Risk reason", value=assessment.get("risk_reason") or "")
        assessment_submit = st.form_submit_button("Save assessment")

    if assessment_submit:
        for field, files in upload_buffers.items():
            if files:
                new_urls = upload_files(api_base, token, detail["id"], field, files)
                assessment[field]["files"] = [*(assessment[field].get("files") or []), *new_urls]
                if new_urls:
                    assessment[field]["status"] = "uploaded"

        assessment["country_of_origin"] = assessment["country_of_origin"] or None
        assessment["quantity_unit"] = assessment["quantity_unit"] or None
        assessment["delivery_date"] = assessment["delivery_date"] or None
        assessment["geolocation_source_text"] = assessment["geolocation_source_text"] or None
        assessment["risk_reason"] = assessment["risk_reason"] or None
        assessment["wood_specification_memo"] = assessment["wood_specification_memo"] or None
        assessment["personal_risk_level"] = assessment["personal_risk_level"] or None
        api_request("PUT", api_base, f"/invoices/{detail['id']}/assessment", token=token, json=assessment)
        st.success("Assessment saved. Refresh the page to see recalculated risk.")
        st.rerun()

with risk_tab:
    risk = detail["risk"]
    st.metric("Risk score", round(risk["risk_score"]))
    st.progress(min(max(risk["risk_score"] / 100, 0.0), 1.0))
    st.write(f"Risk level: **{risk['risk_level']}**")
    st.write(f"Coverage: **{round(risk['coverage_percent'])}%**")
    if risk["blockers"]:
        st.subheader("Blockers")
        for blocker in risk["blockers"]:
            st.write(f"- {blocker}")
    st.subheader("Breakdown")
    st.dataframe(risk["breakdown"], use_container_width=True)

with audit_tab:
    if not audit_logs:
        st.info("No audit events recorded for this invoice yet.")
    for entry in audit_logs:
        actor = entry["actor_username"] or "system"
        summary = entry["summary"] or "No summary provided."
        st.markdown(f"**{entry['action']}**")
        st.caption(f"{entry['created_at']} | {actor} | {entry.get('actor_role') or '-'}")
        st.write(summary)
        if entry.get("payload"):
            st.json(entry["payload"], expanded=False)
