from PIL import Image, ImageFilter
import os

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(SRC_DIR, "voile")
VOILE_PATH = os.path.expanduser(r"~\Downloads\voile.png")
OPACITY = 0.60  # 60%

os.makedirs(OUT_DIR, exist_ok=True)

voile = Image.open(VOILE_PATH).convert("RGBA")

for fname in sorted(os.listdir(SRC_DIR)):
    if not fname.startswith("pastel_") or not fname.endswith(".png"):
        continue

    src_path = os.path.join(SRC_DIR, fname)
    img = Image.open(src_path).convert("RGBA")

    # Resize voile if needed
    v = voile.resize(img.size, Image.LANCZOS) if voile.size != img.size else voile.copy()

    # Apply voile at 12% opacity: blend original with voile overlay
    blended = Image.blend(img, v, alpha=OPACITY)

    # Save
    out_path = os.path.join(OUT_DIR, fname)
    blended.convert("RGB").save(out_path, "PNG")
    print(f"OK: {fname}")

print(f"\nDone! {len(os.listdir(OUT_DIR))} files in {OUT_DIR}")
