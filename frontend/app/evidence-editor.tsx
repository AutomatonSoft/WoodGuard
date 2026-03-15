import { useId } from "react";

import { absoluteFileUrl } from "../lib/api";
import { getMessages, translateDocumentStatus, type Locale } from "../lib/i18n";
import type { Evidence } from "../lib/types";


export function EvidenceEditor({
  title,
  evidence,
  locale,
  onStatusChange,
  onMemoChange,
  onUpload,
}: {
  title: string;
  evidence: Evidence;
  locale: Locale;
  onStatusChange: (value: Evidence["status"]) => void;
  onMemoChange: (value: string) => void;
  onUpload: (files: FileList | null) => void;
}) {
  const t = getMessages(locale);
  const inputId = useId();
  const uploadedSummary = `${t.currentFiles}: ${evidence.files.length}`;

  return (
    <article className="evidenceCard">
      <h3>{title}</h3>
      <div className="formRow">
        <label>{t.status}</label>
        <select
          className="selectInput"
          value={evidence.status}
          onChange={(event) => onStatusChange(event.target.value as Evidence["status"])}
        >
          <option value="missing">{translateDocumentStatus(locale, "missing")}</option>
          <option value="uploaded">{translateDocumentStatus(locale, "uploaded")}</option>
          <option value="verified">{translateDocumentStatus(locale, "verified")}</option>
        </select>
      </div>
      <div className="formRow">
        <label>{t.memo}</label>
        <textarea
          className="textArea"
          value={evidence.memo ?? ""}
          onChange={(event) => onMemoChange(event.target.value)}
        />
      </div>
      <div className="formRow">
        <label>{t.upload}</label>
        <label className="uploadControl" htmlFor={inputId}>
          <span className="uploadTrigger">{t.upload}</span>
          <span className="uploadMeta">{uploadedSummary}</span>
        </label>
        <input
          id={inputId}
          className="fileInput"
          type="file"
          multiple
          onChange={(event) => onUpload(event.target.files)}
        />
      </div>
      <div className="fileList">
        {evidence.files.map((file) => (
          <a className="fileLink" key={file} href={absoluteFileUrl(file)} target="_blank" rel="noreferrer">
            {file.split("/").pop()}
          </a>
        ))}
      </div>
    </article>
  );
}
