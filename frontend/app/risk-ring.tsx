import { translateRiskLevel, type Locale } from "../lib/i18n";
import type { RiskSummary } from "../lib/types";


export function RiskRing({ risk, locale }: { risk: RiskSummary; locale: Locale }) {
  const color =
    risk.risk_level === "high"
      ? "var(--danger)"
      : risk.risk_level === "medium"
        ? "var(--warning)"
        : "var(--accent)";
  const background = `conic-gradient(${color} ${risk.risk_score}%, rgba(16, 38, 31, 0.08) 0)`;

  return (
    <div className="riskRing" style={{ background }}>
      <div className="riskRingContent">
        <strong>{Math.round(risk.risk_score)}</strong>
        <span>{translateRiskLevel(locale, risk.risk_level)}</span>
      </div>
    </div>
  );
}
