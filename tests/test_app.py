import ast
from pathlib import Path
import tomllib


APP_SOURCE = Path(__file__).parents[1] / "src" / "xportstore" / "app.py"
ANDROID_OVERLAY = Path(__file__).parents[1] / "android-overlay" / "app" / "src" / "main"
PROJECT_CONFIG = Path(__file__).parents[1] / "pyproject.toml"


def _app_constants():
    tree = ast.parse(APP_SOURCE.read_text(encoding="utf-8"))
    return {
        node.targets[0].id: ast.literal_eval(node.value)
        for node in tree.body
        if isinstance(node, ast.Assign)
        and len(node.targets) == 1
        and isinstance(node.targets[0], ast.Name)
    }


def test_app_uses_secure_production_url():
    assert _app_constants()["APP_URL"] == "https://xportstore.ru/"


def test_app_does_not_inject_or_allow_insecure_site_content():
    source = APP_SOURCE.read_text(encoding="utf-8")
    assert "http://xportstore.ru" not in source
    assert "evaluateJavascript" not in source
    assert "setMixedContentMode" not in source


def test_android_wrapper_is_secure_and_does_not_modify_the_site_dom():
    manifest = (ANDROID_OVERLAY / "AndroidManifest.xml").read_text(encoding="utf-8")
    activity = (
        ANDROID_OVERLAY
        / "java"
        / "ru"
        / "xportstore"
        / "xportstore"
        / "XportMainActivity.java"
    ).read_text(encoding="utf-8")

    assert 'android:usesCleartextTraffic="false"' in manifest
    assert "MIXED_CONTENT_NEVER_ALLOW" in activity
    assert "MIXED_CONTENT_ALWAYS_ALLOW" not in activity
    assert "setUserAgentString" not in activity
    assert "evaluateJavascript" not in activity


def test_bundle_name_is_ascii_and_sideload_safe():
    config = tomllib.loads(PROJECT_CONFIG.read_text(encoding="utf-8"))
    assert config["tool"]["briefcase"]["project_name"] == "XPort Store"
    assert config["tool"]["briefcase"]["app"]["xportstore"]["formal_name"] == "XPort Store"
