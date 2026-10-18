"""Shared URL sanitation for persisted discovery metadata."""
from urllib.parse import urlsplit, urlunsplit


def sanitize_url(value):
    try:
        parts = urlsplit(value)
        if parts.scheme.lower() not in {"http", "https", "file", "smb", "afp", "nfs"}:
            return ""
        hostname = parts.hostname or ""
        if ":" in hostname:
            hostname = "[" + hostname + "]"
        port = ":" + str(parts.port) if parts.port else ""
        return urlunsplit((parts.scheme, hostname + port, parts.path, "", ""))
    except ValueError:
        return ""
