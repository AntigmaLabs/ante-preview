import os
import shlex
from pathlib import Path

from harbor.agents.installed.base import BaseInstalledAgent, ExecInput
from harbor.models.agent.context import AgentContext
from harbor.models.agent.name import AgentName


class AnteAgent(BaseInstalledAgent):
    @staticmethod
    def name() -> str:
        return "ante"

    @property
    def _install_agent_template_path(self) -> Path:
        return Path(__file__).parent / "install-ante.sh.j2"

    @property
    def _template_variables(self) -> dict[str, str]:
        variables = {}

        # Priority: environment variable TAG > self.version() > None
        # TAG should be a GitHub release tag (e.g., v0.1.0, latest)
        tag = os.environ.get("TAG")
        if not tag:
            tag = self.version()
        if tag:
            variables["version"] = tag

        # Add GITHUB_TOKEN for accessing private repo releases
        github_token = os.environ.get("GITHUB_TOKEN")
        if github_token:
            variables["GITHUB_TOKEN"] = github_token

        return variables

    def populate_context_post_run(self, context: AgentContext) -> None:
        pass

    def create_run_agent_commands(self, instruction: str) -> list[ExecInput]:
        escaped_instruction = shlex.quote(instruction)

        if self.model_name:
            provider = os.environ.get("PROVIDER", "anthropic")
            model_name = self.model_name
        else:
            provider = os.environ.get("PROVIDER", "anthropic")
            model_name = os.environ.get("MODEL_NAME", "claude-sonnet-4-5")

        env = {
            "ANTHROPIC_API_KEY": os.environ.get("ANTHROPIC_API_KEY", ""),
            "OPENAI_API_KEY": os.environ.get("OPENAI_API_KEY", ""),
            "GEMINI_API_KEY": os.environ.get("GEMINI_API_KEY", ""),
            "MODEL_BASE_URL": os.environ.get("MODEL_BASE_URL", ""),
            "MODEL_NAME": model_name,
            "PROVIDER": provider,
            "MODEL_TEMPERATURE": os.environ.get("MODEL_TEMPERATURE", ""),
            "MODEL_TOP_P": os.environ.get("MODEL_TOP_P", ""),
            "MODEL_THINKING": os.environ.get("MODEL_THINKING", "enabled"),
            "MODEL_MAX_TOKENS": os.environ.get("MODEL_MAX_TOKENS", ""),
            "GRAFANA_CLOUD_AUTH": os.environ.get("GRAFANA_CLOUD_AUTH", ""),
            "GRAFANA_CLOUD_URL": os.environ.get("GRAFANA_CLOUD_URL", ""),
            "ANTE_ENV": os.environ.get("ANTE_ENV", ""),
            "ANTE_TAG": os.environ.get("ANTE_TAG", ""),
        }

        return [
            ExecInput(
                command=(
                    f"ante -p {escaped_instruction} --yolo "
                    f"--provider {provider} --model {model_name} "
                    f"2>&1 | tee /logs/agent/ante.txt"
                ),
                env=env,
            )
        ]
