from pathlib import Path
from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\2y0z0x4\AppData\Local\Temp\codex-clipboard-a7c774b6-d400-4d05-a1ed-626242a1d7c0.png")


def square_icon(size: int) -> Image.Image:
    src = Image.open(SOURCE).convert("RGBA")
    src.thumbnail((int(size * 0.86), int(size * 0.86)), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    out.alpha_composite(src, ((size - src.width) // 2, (size - src.height) // 2))
    return out


def write_png(path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    square_icon(size).save(path)


def write_ico(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    base = square_icon(256)
    sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    base.save(path, sizes=sizes)


def write_install_header(path: Path) -> None:
    old = Image.open(path)
    width, height = old.size
    src = Image.open(SOURCE).convert("RGBA")
    canvas = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    mark = src.copy()
    mark.thumbnail((int(width * 0.42), int(height * 0.78)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, (width - mark.width - 20, (height - mark.height) // 2))
    canvas.convert("RGB").save(path)


def main() -> None:
    android_sizes = {
        "drawable-ldpi": 36,
        "drawable-mdpi": 48,
        "drawable-hdpi": 72,
        "drawable-xhdpi": 96,
        "drawable-xxhdpi": 144,
        "drawable-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        write_png(ROOT / "android" / "res" / folder / "icon.png", size)

    write_png(ROOT / "resources" / "icons" / "qgroundcontrol.png", 512)
    write_png(ROOT / "resources" / "icons" / "android_512x512.png", 512)
    write_png(ROOT / "resources" / "icons" / "android_dev_512x512.png", 512)
    write_ico(ROOT / "resources" / "icons" / "qgroundcontrol.ico")
    write_ico(ROOT / "deploy" / "windows" / "WindowsQGC.ico")
    write_install_header(ROOT / "deploy" / "windows" / "installheader.bmp")


if __name__ == "__main__":
    main()
