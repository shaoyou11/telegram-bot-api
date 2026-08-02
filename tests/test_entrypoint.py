import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENTRYPOINT = ROOT / "docker-entrypoint.sh"


class EntryPointTests(unittest.TestCase):
    def run_entrypoint(self, **values):
        with tempfile.TemporaryDirectory() as directory:
            temp_root = Path(directory)
            capture = temp_root / "args.txt"
            fake_binary = temp_root / "telegram-bot-api"
            fake_binary.write_text(
                "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$CAPTURE_FILE\"\n",
                encoding="utf-8",
            )
            fake_binary.chmod(0o755)
            environment = os.environ.copy()
            environment.update(values)
            environment.update(
                PATH=f"{temp_root}{os.pathsep}{environment['PATH']}",
                CAPTURE_FILE=str(capture),
            )
            result = subprocess.run(
                ["sh", str(ENTRYPOINT)],
                env=environment,
                capture_output=True,
                text=True,
            )
            arguments = capture.read_text(encoding="utf-8").splitlines() if capture.exists() else []
            return result, arguments

    def test_passes_api_credentials_local_mode_and_http_port(self):
        result, arguments = self.run_entrypoint(
            TELEGRAM_API_ID="123456",
            TELEGRAM_API_HASH="hash-value",
            TELEGRAM_LOCAL="1",
            TELEGRAM_HTTP_PORT="8081",
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            arguments,
            ["--api-id", "123456", "--api-hash", "hash-value", "--local", "--http-port", "8081"],
        )

    def test_omits_local_mode_when_disabled(self):
        result, arguments = self.run_entrypoint(
            TELEGRAM_API_ID="123456",
            TELEGRAM_API_HASH="hash-value",
            TELEGRAM_LOCAL="0",
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(arguments, ["--api-id", "123456", "--api-hash", "hash-value"])

    def test_rejects_missing_api_credentials(self):
        result, arguments = self.run_entrypoint(TELEGRAM_LOCAL="1")

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(arguments, [])


if __name__ == "__main__":
    unittest.main()
