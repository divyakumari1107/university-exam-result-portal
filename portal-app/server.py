#!/usr/bin/env python3
"""
Lightweight HTTP server for the University Exam & Result Portal.
Serves static files from portal-app/ and provides POST /api/email-result
using Python's built-in smtplib when SMTP environment variables are set.
"""

from email.message import EmailMessage
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import smtplib

APP_DIR = os.path.dirname(os.path.abspath(__file__))


def send_marksheet_smtp(to_email: str, result: dict) -> tuple[bool, str]:
    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER", "")
    smtp_pass = os.getenv("SMTP_PASS", "")
    from_addr = os.getenv("SMTP_FROM", smtp_user)

    if not smtp_user or not smtp_pass:
        return False, "SMTP_USER / SMTP_PASS not set; opening pre-filled email draft."

    subjects = result.get("subjects", [])
    lines = [
        "University Exam & Result Portal",
        f"Student : {result.get('name', '')}",
        f"Roll No : {result.get('roll', '')}",
        f"Branch  : {result.get('branch', '')}",
        f"Semester: {result.get('semester', '')}",
        "",
        "Marks Statement:",
    ]
    for s in subjects:
        lines.append(f"  - {s.get('name')}: {s.get('marks')} ({s.get('grade')} - {s.get('status')})")
    lines.extend(["", f"SGPA: {result.get('sgpa', '')}"])

    msg = EmailMessage()
    msg["Subject"] = f"University Result: {result.get('name', '')} ({result.get('roll', '')} - {result.get('semester', '')})"
    msg["From"] = from_addr
    msg["To"] = to_email
    msg.set_content("\n".join(lines))

    with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.send_message(msg)

    return True, f"Sent to {to_email}"


class PortalHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/api/email-result":
            self.send_error(404, "Endpoint not found")
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode("utf-8"))
            to_email = str(payload.get("to", "")).strip()
            result = payload.get("result") or {}
            if not to_email or "@" not in to_email:
                raise ValueError("Invalid email address")

            sent, message = send_marksheet_smtp(to_email, result)
            status_code = 200
            body = {"sent": sent, "message": message}
        except Exception as exc:
            status_code = 400
            body = {"sent": False, "message": str(exc)}

        encoded = json.dumps(body).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    handler = partial(PortalHandler, directory=APP_DIR)
    server = ThreadingHTTPServer(("0.0.0.0", port), handler)
    print(f"University Result Portal running at http://localhost:{port}")
    server.serve_forever()
