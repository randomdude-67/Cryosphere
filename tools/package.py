"""Package the HJSON mod using only Python's standard library."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parent.parent
ASSET_DIRECTORIES = (
    "bundles",
    "content",
    "maps",
    "music",
    "schematics",
    "sounds",
    "sprites",
)


def package() -> Path:
    files = [ROOT / "mod.hjson"]
    for optional in ("icon.png", "LICENSE", "README.md"):
        path = ROOT / optional
        if path.is_file():
            files.append(path)

    for directory in ASSET_DIRECTORIES:
        files.extend(
            path
            for path in (ROOT / directory).rglob("*")
            if path.is_file()
            and not any(part.startswith(".") for part in path.relative_to(ROOT).parts)
        )

    output = ROOT / "dist" / "cryosphere.zip"
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", compression=ZIP_DEFLATED) as archive:
        for path in sorted(files):
            archive.write(path, path.relative_to(ROOT).as_posix())
    return output


if __name__ == "__main__":
    print(package())
