from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


@dataclass
class StoryPackage:
    ambassador: str
    handle: str
    theme: str
    copy: str
    status: str = "planned"


class ZimzAuto:
    """Dry-run ambassador orchestrator.

    This prototype prepares daily Story packages and reward evidence.
    It does not connect to Instagram, publish content, or move GREEN AIPE.
    """

    def __init__(self, config_path: str | Path) -> None:
        self.config_path = Path(config_path)
        self.config: dict[str, Any] = json.loads(self.config_path.read_text())

    @property
    def active_profiles(self) -> list[dict[str, Any]]:
        return [p for p in self.config.get("profiles", []) if p.get("status") == "active"]

    def prepare_daily_packages(self) -> list[StoryPackage]:
        packages: list[StoryPackage] = []
        for profile in self.active_profiles:
            themes = profile.get("approved_topics") or ["SZIMZ ecosystem"]
            theme = themes[0]
            tone = ", ".join(profile.get("tone", [])) or "clear"
            copy = (
                f"{theme}: one short {tone} Story for {profile['name']}. "
                "Use only approved claims and approved campaign assets."
            )
            packages.append(
                StoryPackage(
                    ambassador=profile["name"],
                    handle=profile["handle"],
                    theme=theme,
                    copy=copy,
                )
            )
        return packages

    def reward_summary(self, qualifying_days: int) -> dict[str, int | bool]:
        programme = self.config["programme"]
        met = qualifying_days >= 7
        gross = programme["weekly_reward_green"] if met else 0
        fee = programme["weekly_service_fee_green"] if met else 0
        return {
            "qualifying_days": qualifying_days,
            "requirement_met": met,
            "gross_green": gross,
            "service_fee_green": fee,
            "net_green": max(gross - fee, 0),
        }

    def write_log(self, packages: list[StoryPackage], output_path: str | Path) -> None:
        now = datetime.now(timezone.utc).isoformat()
        rows = [
            {
                "timestamp": now,
                "ambassador": p.ambassador,
                "handle": p.handle,
                "theme": p.theme,
                "copy": p.copy,
                "status": p.status,
                "qualifying": False,
                "proof_ref": None,
            }
            for p in packages
        ]
        Path(output_path).write_text(json.dumps(rows, indent=2))


if __name__ == "__main__":
    agent = ZimzAuto(Path(__file__).with_name("config.example.json"))
    packages = agent.prepare_daily_packages()
    agent.write_log(packages, Path(__file__).with_name("daily_log.example.json"))
    for package in packages:
        print(f"{package.ambassador} ({package.handle}): {package.copy}")
