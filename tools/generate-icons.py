from pathlib import Path

from PIL import Image


ROOT = Path(__file__).parents[1]
SOURCE = ROOT / "src" / "xportstore" / "resources" / "icon.png"
SIZES = (20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 640, 1024, 1280, 1920)


def main():
    with Image.open(SOURCE) as source:
        icon = source.convert("RGB")
        if icon.width != icon.height:
            raise ValueError(f"App icon must be square, got {icon.size}")

        for size in SIZES:
            output = SOURCE.with_name(f"icon-{size}.png")
            resized = icon.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(output, format="PNG", optimize=True)
            print(output)


if __name__ == "__main__":
    main()
